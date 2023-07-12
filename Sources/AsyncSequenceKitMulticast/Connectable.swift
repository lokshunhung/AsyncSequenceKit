//
//  Connectable.swift
//
//
//  Created by LS Hung on 12/07/2023.
//

@rethrows
public protocol Connectable<Element>: _Concurrency.AsyncSequence {
    associatedtype Element

    func connect() -> _Concurrency.Task<Void, Never>
}
