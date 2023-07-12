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
}
