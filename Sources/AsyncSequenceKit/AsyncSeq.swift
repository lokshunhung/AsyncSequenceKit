//
//  AsyncSeq.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

public struct Consumer<Element, Failure: Swift.Error> {
    let value: Optional<(Element) -> Void>
    let error: Optional<(Failure) -> Void>
    let complete: Optional<() -> Void>
}

public protocol Producer<Element, Failure> {
    associatedtype Element
    associatedtype Failure: Swift.Error

    typealias Subscriber = Consumer<Element, Failure>
    typealias Subscription = _Concurrency.Task<Void, any Swift.Error>

    func receive(subscriber: Subscriber) -> Subscription
}

extension Producer {
    public func eraseToProducer() -> AnyProducer<Element, Failure> {
        return AnyProducer(producer: self)
    }

    public func subscribe(_ subscriber: Subscriber) -> Subscription {
        return self.receive(subscriber: subscriber)
    }

    public func subscribe(value: Optional<(Element) -> Void> = nil,
                          error: Optional<(Failure) -> Void> = nil,
                          complete: Optional<() -> Void> = nil) -> Subscription {
        return self.subscribe(Subscriber(value: value, error: error, complete: complete))
    }
}

// MARK: - AnyProducer

public struct AnyProducer<Element, Failure: Swift.Error>: Producer {
    private let box: AnyProducerBox<Element, Failure>

    init(producer: some Producer<Element, Failure>) {
        if let erased = producer as? AnyProducer<Element, Failure> {
            self.box = erased.box
        } else {
            self.box = AnyProducerBoxImpl(erasure: producer)
        }
    }

    public func receive(subscriber: Subscriber) -> Subscription {
        return box.receive(subscriber: subscriber)
    }
}

private class AnyProducerBox<Element, Failure: Swift.Error>: Producer {
    func receive(subscriber: Subscriber) -> Subscription { fatalError() }
}

private final class AnyProducerBoxImpl<T: Producer>: AnyProducerBox<T.Element, T.Failure> {
    private let erasure: T
    init(erasure: T) { self.erasure = erasure }

    override func receive(subscriber: Subscriber) -> Subscription {
        return erasure.receive(subscriber: subscriber)
    }
}

// MARK: - AsyncSequence

public struct AsyncSequenceProducer<Element, Failure: Swift.Error>: Producer {
    private let receiveSubscriber: (Subscriber) -> Subscription

    init<T: AsyncSequence>(_ asyncSequence: T) where T.Element == Element {
        self.receiveSubscriber = { subscriber in
            Task(priority: nil, operation: {
                do {
                    for try await element in asyncSequence {
                        subscriber.value?(element)
                    }
                    subscriber.complete?()
                } catch let error as Failure {
                    subscriber.error?(error)
                }
            })
        }
    }

    public func receive(subscriber: Consumer<Element, Failure>) -> Subscription {
        self.receiveSubscriber(subscriber)
    }
}

extension AsyncSequence {
    public func eraseToProducer() -> AnyProducer<Element, Swift.Error> {
        return AsyncSequenceProducer(self).eraseToProducer()
    }

    public func eraseToProducer<Failure: Swift.Error>() -> AnyProducer<Element, Failure> {
        return AsyncSequenceProducer(self).eraseToProducer()
    }
}


//public protocol AsyncSeq<Element, Failure> {
//    associatedtype Element
//    associatedtype Failure: Swift.Error
//    associatedtype AsyncSeqItr: AsyncItr<Element, Failure>
//}
//public protocol AsyncItr<Element, Failure> {
//    associatedtype Element
//    associatedtype Failure: Swift.Error
//    mutating func next() async -> Result<Element, Failure>?
//}
//
//
//extension _Concurrency.AsyncStream: AsyncSeq {
//    public typealias Failure = Never
//    public func makeItr() -> AsyncSeqItr {
//        var itr = self.makeAsyncIterator()
//        return AsyncSeqItr(nextElement: { await itr.next() })
//    }
//    public struct AsyncSeqItr: AsyncItr {
//        let nextElement: () async -> Element?
//        public mutating func next() async -> Result<Element, Failure>? {
//            return await self.nextElement().map(Result.success)
//        }
//    }
//}
