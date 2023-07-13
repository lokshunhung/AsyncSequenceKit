//
//  BehaviorSubjectDoThrow.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import class AsyncSequenceKitPlatform.AllocatedLock
import class AsyncSequenceKitPlatform.Boxed

public struct DoThrowBehaviorSubject<Element, Failure>
    where Failure: Swift.Error
{   // TODO: AsyncThrowingStream.makeStream requires Failure to be Swift.Error
    fileprivate typealias Pipe = _Concurrency.AsyncThrowingStream<Element, any Swift.Error>
    fileprivate typealias SubscriptionManager = PipeSubscriptionManager<Element, any Swift.Error>

    private let lock: AllocatedLock = .new()
    private let subscriptionManager: SubscriptionManager = .init()
    @Boxed private var currentValue: Element

    public init(_ value: Element) {
        self.currentValue = value
    }
}

extension DoThrowBehaviorSubject: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        return self.lock.withLock {
            AsyncIterator.new(self.subscriptionManager) { [weak $currentValue] in
                $currentValue?.wrappedValue
            }
        }
    }

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol, TerminationSideEffectAssignable {
        private weak var subscriptionManager: SubscriptionManager?
        private let pipe: Pipe
        private let continuation: Pipe.Continuation
        private let downstreamID: SubscriptionManager.DownstreamID
        private var iterator: Pipe.AsyncIterator
        private var initialValue: Optional<() -> Element?>

        public var onTermination: Optional<() -> Void> = nil {
            didSet { self.bindOnTermination() }
        }

        fileprivate static func new(_ subscriptionManager: SubscriptionManager,
                                    initialValue: @escaping () -> Element?) -> Self {
            let (pipe, continuation) = Pipe.makeStream(bufferingPolicy: .unbounded)
            let downstreamID = subscriptionManager.add(downstream: .init(continuation))
            let iterator = pipe.makeAsyncIterator()
            let `self` = Self(subscriptionManager: subscriptionManager,
                              pipe: pipe, continuation: continuation,
                              downstreamID: downstreamID,
                              iterator: iterator,
                              initialValue: initialValue)
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

        public mutating func next() async throws -> Element? {
            if let initialValue {
                self.initialValue = nil
                return initialValue()
            }
            return try await self.iterator.next()
        }
    }
}

extension DoThrowBehaviorSubject: BehaviorSubject {
    public var value: Element {
        self.lock.withLock {
            self.currentValue
        }
    }

    public func next(_ value: Element) {
        self.lock.withLock {
            self.currentValue = value
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
