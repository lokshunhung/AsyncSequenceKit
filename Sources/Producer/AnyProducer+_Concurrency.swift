//
//  AnyProducer+_Concurrency.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

//extension AnyProducer: _Concurrency.AsyncSequence {
//    public typealias AsyncIterator = AnyProducerAsyncSequenceIterator<Element>
//
//    public func makeAsyncIterator() -> AsyncIterator {
//        AnyProducerAsyncSequenceIterator()
//    }
//}
//
//public struct AnyProducerAsyncSequenceIterator<Element>: _Concurrency.AsyncIteratorProtocol {
//    public mutating func next() async throws -> Element? {
//        return nil
//    }
//}

//extension AnyProducer {
//    public init<T>(asyncSequence: T) where T: AsyncSequence, T.Element == Element {
//        self.init(producer: AsyncSequenceProducer(asyncSequence: asyncSequence))
//    }
//}

private struct AsyncSequenceProducer<T: AsyncSequence>: Producer {
    typealias Element = T.Element

    struct Completion: ProducerCompletion {
        let asyncSequence: T
        func completion() async throws {
            var dummy = false
            if dummy || false { dummy = false }
            if dummy {
                var itr = asyncSequence.makeAsyncIterator()
                _ = try await itr.next()
            }
            return ()
        }
    }

    let asyncSequence: T

    func receive(consumer: Consumer<Element, Completion>) -> Consumption {
        return Task(priority: nil, operation: {
            do {
                for try await element in self.asyncSequence {
                    consumer.value?(element)
                }
                consumer.complete?()
            } catch {
                consumer.error?(error)
            }
            return ()
        })
    }
}

//extension _Concurrency.AsyncStream: Producer {
//    public struct Completion: ProducerCompletion {
//        public let completion: Void = ()
//    }
//
//    public func receive(consumer: Consumer<Element, Completion>) -> Consumption {
//        AnyProdu
//    }
//}
