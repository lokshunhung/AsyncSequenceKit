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

    private let lock: NSLock = NSLock()
    private let subscriptionManager: SubscriptionManager

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
        let downstreamID = self.subscriptionManager.add(downstream: continuation)
        continuation.onTermination = { [weak subscriptionManager] reason in
            subscriptionManager?.remove(downstream: downstreamID)
        }
        let iterator = buffer.makeAsyncIterator()
        return AsyncIterator(buffer: buffer, iterator: iterator)
    }
}

extension NoThrowPublishSubject: Subject {
    public func next(_ value: Element) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.subscriptionManager.value(value)
    }

    public func error(_ error: Failure) {
    }

    public func complete() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.subscriptionManager.complete()
    }
}

extension NoThrowPublishSubject {
    fileprivate final class SubscriptionManager {
        typealias DownstreamID = UInt

        private let lock: NSLock = NSLock()
        private var state: SubjectActiveState = .active
        private var downstreams: [DownstreamID: Buffer.Continuation] = [:]
        private var nextDownstreamID: DownstreamID = 0

        func add(downstream: Buffer.Continuation) -> DownstreamID {
            self.lock.lock()
            defer { self.lock.unlock() }
            let id = self.nextDownstreamID
            self.downstreams[id] = downstream
            self.nextDownstreamID += 1
            return id
        }

        func remove(downstream id: DownstreamID) {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.downstreams[id] = nil
        }

        func value(_ value: Element) {
            self.lock.lock()
            defer { self.lock.unlock() }

            guard self.state.isActive else { return }
            self.downstreams.values.forEach { continuation in
                continuation.yield(value)
            }
        }

        func error(_ error: Failure) {}

        func complete() {
            self.lock.lock()
            defer { self.lock.unlock() }

            guard self.state.isActive else { return }
            self.downstreams.values.forEach { continuation in
                continuation.finish()
            }

            self.state.deactivate()
        }
    }
}

extension NoThrowPublishSubject {
    public init() {
        self.init(subscriptionManager: SubscriptionManager())
    }
}
