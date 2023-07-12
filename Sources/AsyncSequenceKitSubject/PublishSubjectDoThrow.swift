//
//  PublishSubjectDoThrow.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import class AsyncSequenceKitPlatform.AllocatedLock

public struct DoThrowPublishSubject<Element, Failure>: PublishSubject
    where Failure: Swift.Error
{   // TODO: AsyncThrowingStream.makeStream requires Failure to be Swift.Error
    fileprivate typealias Pipe = _Concurrency.AsyncThrowingStream<Element, any Swift.Error>
    private typealias SubscriptionManager = PipeSubscriptionManager<Element, any Swift.Error>

    private let lock: AllocatedLock = .new()
    private let subscriptionManager: SubscriptionManager = .init()

    public init() {}

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol {
        fileprivate let pipe: Pipe
        fileprivate var iterator: Pipe.AsyncIterator

        public mutating func next() async throws -> Element? {
            return try await self.iterator.next()
        }
    }
}

extension DoThrowPublishSubject: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        return self.makeAsyncIterator(withTerminationHandler: nil)
    }

    public func makeAsyncIterator(withTerminationHandler onTermination: Optional<() -> Void>) -> AsyncIterator {
        self.lock.lock()
        defer { self.lock.unlock() }

        let (pipe, continuation) = Pipe.makeStream(bufferingPolicy: .unbounded)
        let downstreamID = self.subscriptionManager.add(downstream: .init(continuation))

        // See: [Subject.makeAsyncIterator(withTerminationHandler:)](x-source-tag://Subject_makeAsyncIterator_withTerminationHandler)
        continuation.onTermination = { [weak subscriptionManager] reason in
            onTermination?()
            // Termination reason == .finished if continuation.finished() is being called
            // in the locked region of subscriptionManager.complete().
            // Calling subscriptionManager.remove(downstream:) here would try to acquire
            // subscriptionManager.lock again, causing a runtime error.
            // So instead, the removal of this downstream is handled in subscriptionManager.complete().
            if case .finished = reason { return }
            subscriptionManager?.remove(downstream: downstreamID)
        }

        let iterator = pipe.makeAsyncIterator()
        return AsyncIterator(pipe: pipe, iterator: iterator)
    }
}

extension DoThrowPublishSubject: Subject {
    public func next(_ value: Element) {
        self.lock.withLock {
            self.subscriptionManager.next(value)
        }
    }

    public func error(_ error: Failure) {
        self.lock.withLock {
            self.subscriptionManager.error(error)
        }
    }

    public func complete() {
        self.lock.withLock {
            self.subscriptionManager.complete()
        }
    }
}
