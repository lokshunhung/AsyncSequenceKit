//
//  Subject.swift
//
//
//  Created by LS Hung on 02/07/2023.
//

@rethrows
public protocol Subject<Element, Failure>: _Concurrency.AsyncSequence
    where Failure: Swift.Error
{
    associatedtype Element
    associatedtype Failure

    func next(_ value: Element)

    func error(_ error: Failure)

    func complete()

    /// `AsyncSequence.makeAsyncIterator()` is where an async iteration is requested.
    /// This is analogous to `RxSwift.Observable.subscribe()` or `Combine.Publisher.sink()`.
    ///
    /// Like `RxSwift.Disposable` or `Combine.Cancellable` to hold/trigger cleanup logic,
    /// `Async[Throwing]Stream.Continuation.onTermination` stores the cleanup logic
    /// when the async iteration is terminated (e.g. enclosing `Task` is cancelled).
    ///
    /// However, since the `onTermination` handler is held by the `continuation` which is the underlying
    /// implementation that enables the multicast (i.e. multiple subscribers / iteration requests) behavior,
    /// and not the `Task` when the actual subscription/iteration is performed, a peer overload of `makeAsyncIterator`
    /// is added.
    ///
    /// Exposing the `onTermination` handler allows adding side effects to be executed when an `Async[Throwing]Stream` is terminated.
    /// This is needed to implement the `refCount` operator to keep track of the total number of active subscribers, and terminate the upstream
    /// when the number of subscribers drops to zero.
    /// - Tag: Subject_makeAsyncIterator_withTerminationHandler
    func makeAsyncIterator(withTerminationHandler onTermination: Optional<() -> Void>) -> Self.AsyncIterator
}
