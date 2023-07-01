//
//  Consumer.swift
//  
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

public struct Consumer<Element, Completion: ProducerCompletion> {
    internal let value: Optional<(Element) -> Void>
    internal let error: Optional<(Swift.Error) -> Void>
    internal let complete: Optional<() -> Void>

//    private let receiveValue: (Element) -> Void
//    private let receiveCompletion: (Completion) -> Void
//
//    init(receiveValue: @escaping (Element) -> Void,
//         receiveCompletion: @escaping (ProducerCompletion) -> Void) {
//        self.receiveValue = receiveValue
//        self.receiveCompletion = receiveCompletion
//    }
//
//    func value(_ value: Element) {}
//
//    func completion(_ error: Swift.Error? = nil) rethrows {
//    }
}
