//
//  Subject.swift
//
//
//  Created by LS Hung on 02/07/2023.
//

public protocol Subject<Element, Failure>
    where Failure: Swift.Error
{
    associatedtype Element
    associatedtype Failure

    func next(_ value: Element)

    func error(_ error: Failure)

    func complete()
}
