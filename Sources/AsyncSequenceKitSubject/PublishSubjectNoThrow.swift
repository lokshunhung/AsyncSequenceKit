//
//  PublishSubjectNoThrow.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import class AsyncSequenceKitPlatform.AllocatedLock

public struct NoThrowPublishSubject<Element>: PublishSubject {
    public typealias Failure = Never

    fileprivate typealias Pipe = _Concurrency.AsyncStream<Element>
    fileprivate typealias SubscriptionManager = PipeSubscriptionManager<Element, Failure>

    private let lock: AllocatedLock = .new()
    private let subscriptionManager: SubscriptionManager = .init()

    public init() {}
}

extension NoThrowPublishSubject: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        return self.lock.withLock {
            AsyncIterator.new(self.subscriptionManager)
        }
    }

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol, TerminationSideEffectAssignable {
        private weak var subscriptionManager: SubscriptionManager?
        private let pipe: Pipe
        private let continuation: Pipe.Continuation
        private let downstreamID: SubscriptionManager.DownstreamID
        private var iterator: Pipe.AsyncIterator

        public var onTermination: Optional<() -> Void> = nil {
            didSet { self.bindOnTermination() }
        }

        fileprivate static func new(_ subscriptionManager: SubscriptionManager) -> Self {
            let (pipe, continuation) = Pipe.makeStream(bufferingPolicy: .unbounded)
            let downstreamID = subscriptionManager.add(downstream: .init(continuation))
            let iterator = pipe.makeAsyncIterator()
            let `self` = Self(subscriptionManager: subscriptionManager,
                              pipe: pipe, continuation: continuation,
                              downstreamID: downstreamID,
                              iterator: iterator)
            self.bindOnTermination()
            return self
        }

        private func bindOnTermination() {
            self.continuation.onTermination = { [self] reason in
                self.onTermination?()
                if case .finished = reason { return }
                self.subscriptionManager?.remove(downstream: self.downstreamID)
            }
        }

        public mutating func next() async -> Element? {
            return await self.iterator.next()
        }
    }
}

extension NoThrowPublishSubject: Subject {
    public func next(_ value: Element) {
        self.lock.withLock {
            self.subscriptionManager.next(value)
        }
    }

    public func error(_ error: Failure) {}

    public func complete() {
        self.lock.withLock {
            self.subscriptionManager.complete()
        }
    }
}
