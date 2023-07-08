//
//  BehaviorSubject.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

public protocol BehaviorSubject<Element, Failure>: Subject
    where Failure: Swift.Error
{
    associatedtype Element
    associatedtype Failure

    var value: Element { get }
}
