//
//  PublishSubject.swift
//
//
//  Created by LS Hung on 02/07/2023.
//

public protocol PublishSubject<Element, Failure>: Subject
    where Failure: Swift.Error
{
    associatedtype Element
    associatedtype Failure
}
