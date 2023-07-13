//
//  Connectable.swift
//
//
//  Created by LS Hung on 12/07/2023.
//

import protocol AsyncSequenceKitSubject.TerminationSideEffectAssignable

@rethrows
public protocol Connectable<Element>: _Concurrency.AsyncSequence
    where AsyncIterator: TerminationSideEffectAssignable
{
    associatedtype Element

    func connect() -> _Concurrency.Task<Void, Never>
}
