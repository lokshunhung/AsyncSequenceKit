//
//  Producer.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

@rethrows
public protocol ProducerCompletion {
    func completion() async throws
}

@rethrows
public protocol Producer<Element, Completion> {
    associatedtype Element
    associatedtype Completion: ProducerCompletion
    typealias Consumption = _Concurrency.Task<Void, Swift.Error>

    func receive(consumer: Consumer<Element, Completion>) -> Consumption
}
