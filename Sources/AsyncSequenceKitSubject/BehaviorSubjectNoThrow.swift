//
//  BehaviorSubjectNoThrow.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import class AsyncSequenceKitPlatform.AllocatedLock
import class AsyncSequenceKitPlatform.Boxed

public struct NoThrowBehaviorSubject<Element> {
    public typealias Failure = Never

    fileprivate typealias Pipe = _Concurrency.AsyncStream<Element>
    private typealias SubscriptionManager = PipeSubscriptionManager<Element, Failure>

    private let lock: AllocatedLock = .new()
    private let subscriptionManager: SubscriptionManager = .init()
    @Boxed private var currentValue: Element

    public init(_ value: Element) {
        self.currentValue = value
    }

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol {
        fileprivate let pipe: Pipe
        fileprivate var iterator: Pipe.AsyncIterator
        fileprivate var initialValue: Optional<() -> Element?>

        public mutating func next() async -> Element? {
            if let initialValue {
                self.initialValue = nil
                return initialValue()
            }
            return await self.iterator.next()
        }
    }
}

extension NoThrowBehaviorSubject: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        self.lock.lock()
        defer { self.lock.unlock() }

        let (pipe, continuation) = Pipe.makeStream(bufferingPolicy: .unbounded)
        let downstreamID = self.subscriptionManager.add(downstream: .init(continuation))

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

        let iterator = pipe.makeAsyncIterator()
        return AsyncIterator(pipe: pipe, iterator: iterator) { [weak $currentValue] in
            $currentValue?.wrappedValue
        }
    }
}

extension NoThrowBehaviorSubject: BehaviorSubject {
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
    }

    public func complete() {
        self.lock.withLock {
            self.subscriptionManager.complete()
        }
    }
}
