//
//  PublishSubject.swift
//
//
//  Created by LS Hung on 02/07/2023.
//

import Foundation

public protocol PublishSubject<Element, Failure>: Subject
    where Failure: Swift.Error
{
    associatedtype Element
    associatedtype Failure
}

public struct NoThrowPublishSubject<Element>: PublishSubject {
    public typealias Failure = Never

    fileprivate typealias Buffer = _Concurrency.AsyncStream<Element>
    fileprivate typealias Continuation = _Concurrency.AsyncStream<Element>.Continuation

    private let lock: AllocatedLock = .new()
    private let subscriptionManager: SubscriptionManager = .init()

    public init() {}

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol {
        fileprivate let buffer: Buffer
        fileprivate var iterator: Buffer.AsyncIterator

        public mutating func next() async -> Element? {
            return await self.iterator.next()
        }
    }
}

extension NoThrowPublishSubject: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        self.lock.lock()
        defer { self.lock.unlock() }

        let (buffer, continuation) = Buffer.makeStream(of: Element.self, bufferingPolicy: .unbounded)
        let downstreamID = subscriptionManager.add(downstream: continuation)

        // AsyncSequence.makeAsyncIterator() is where an async iteration is requested.
        // This is analogous to RxSwift.Observable.subscribe() or Combine.Publisher.sink()
        //
        // Like RxSwift.Disposable or Combine.Cancellable to hold/trigger cleanup logic,
        // continuation.onTermination stores the cleanup logic
        // when the async iteration is terminated (e.g. enclosing Task is cancelled).
        continuation.onTermination = { [weak subscriptionManager] reason in
            // Termination reason == .finished if continuation.finished() is being called
            // in the locked region of subscriptionManager.complete().
            // Calling subscriptionManager.remove(downstream:) here would try to acquire
            // subscriptionManager.lock again, causing a runtime error.
            // So instead, the removal of this downstream is handled in subscriptionManager.complete().
            if case .finished = reason { return }
            subscriptionManager?.remove(downstream: downstreamID)
        }

        let iterator = buffer.makeAsyncIterator()
        return AsyncIterator(buffer: buffer, iterator: iterator)
    }
}

extension NoThrowPublishSubject: Subject {
    public func next(_ value: Element) {
        self.lock.withLock {
            self.subscriptionManager.next(value)
        }
    }

    public func error(_ error: Failure) {
    }

    public func complete() {
        self.lock.withLock {
            self.subscriptionManager.complete()
        }
    }
}

extension NoThrowPublishSubject {
    // TODO: refactor to generic using a conduit, instead of relying on concrete Buffer.Continuation
    fileprivate final class SubscriptionManager {
        typealias Downstream = Buffer.Continuation
        typealias DownstreamStorage = Bag<Downstream>
        typealias DownstreamID = DownstreamStorage.Key

        private let lock: AllocatedLock = .new()
        private var state: SubjectActiveState = .active
        private var downstreams: DownstreamStorage = .empty

        func add(downstream: Downstream) -> DownstreamID {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.downstreams.add(downstream)
        }

        func remove(downstream id: DownstreamID) {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.downstreams.remove(id)
        }

        func next(_ value: Element) {
            self.lock.lock()
            defer { self.lock.unlock() }
            guard self.state.isActive else { return }
            self.downstreams.forEach { continuation in
                continuation.yield(value)
            }
        }

        func error(_ error: Failure) {}

        func complete() {
            self.lock.lock()
            defer { self.lock.unlock() }
            guard self.state.isActive else { return }
            self.downstreams.forEach { continuation in
                continuation.finish()
            }

            self.state.deactivate()
            self.downstreams.removeAll()
        }
    }
}
