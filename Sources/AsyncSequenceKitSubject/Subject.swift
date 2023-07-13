//
//  Subject.swift
//
//
//  Created by LS Hung on 02/07/2023.
//

@rethrows
public protocol Subject<Element, Failure>: _Concurrency.AsyncSequence
    where Failure: Swift.Error,
          AsyncIterator: TerminationSideEffectAssignable
{
    associatedtype Element
    associatedtype Failure

    func next(_ value: Element)

    func error(_ error: Failure)

    func complete()
}

public protocol TerminationSideEffectAssignable {
    /// Like `RxSwift.Disposable` or `Combine.Cancellable` to hold/trigger cleanup logic,
    /// `Async[Throwing]Stream.Continuation.onTermination` stores the cleanup logic
    /// when the async iteration is terminated (e.g. enclosing `Task` is cancelled).
    ///
    /// Exposing the `onTermination` handler allows adding side effects to be executed when an `Async[Throwing]Stream` is terminated.
    /// This is needed to implement the `refCount` operator to keep track of the total number of active subscribers, and terminate the upstream
    /// when the number of subscribers drops to zero.
    var onTermination: Optional<() -> Void> { get set }
}
