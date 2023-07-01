//
//  AnyProducer.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

public struct AnyProducer<Element, Completion: ProducerCompletion>: Producer {
    private let receiveConsumer: (Consumer<Element, Completion>) -> Consumption

    public func receive(consumer: Consumer<Element, Completion>) -> Consumption {
        return self.receiveConsumer(consumer)
    }
}

extension AnyProducer {
    init<T>(producer: T) where T: Producer, T.Element == Element, T.Completion == Completion {
        self.init(receiveConsumer: { consumer in
            producer.receive(consumer: consumer)
        })
    }
}

extension Producer {
    public func eraseToProducer() -> AnyProducer<Element, Completion> {
        return AnyProducer(producer: self)
    }
}
