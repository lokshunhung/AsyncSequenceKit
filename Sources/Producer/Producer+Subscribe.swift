//
//  Producer+Subscribe.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

extension Producer {
    public func subscribe(receiveEvent: Event<Element, Completion>) rethrows {
    }
}

public enum Event<Element, Completion: ProducerCompletion> {
    case value(Element)
    case completion(Completion)
}
