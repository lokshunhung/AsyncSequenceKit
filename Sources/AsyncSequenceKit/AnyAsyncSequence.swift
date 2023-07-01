//
//  AnyAsyncSequence.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

public struct AnyAsyncSequence<Element>: _Concurrency.AsyncSequence {
    public typealias AsyncIterator = AnyAsyncIterator<Element>

    private let makeIterator: () -> AsyncIterator

    public init(makeIterator: @escaping () -> AsyncIterator) {
        self.makeIterator = makeIterator
    }

    public func makeAsyncIterator() -> AsyncIterator {
        return self.makeIterator()
    }
}

public struct AnyAsyncIterator<Element>: _Concurrency.AsyncIteratorProtocol {
    private let nextElement: () async -> Element?

    init(nextElement: @escaping () async -> Element?) {
        self.nextElement = nextElement
    }

    public mutating func next() async -> Element? {
        return await self.nextElement()
    }
}

extension _Concurrency.AsyncSequence {
//    public func eraseToAny() -> AnyAsyncSequence<Element> {
//        return .init(makeIterator: {
//            var iterator = self.makeAsyncIterator()
//            return .init(nextElement: {
//                await iterator.next()
//            })
//        })
//    }

//    public func eraseToAny() -> AnyAsyncSequence<Element> {
//        return self.eraseToAny({ await $0.next() })
//    }

    public func eraseToAny(
        _ nextElement: @escaping (inout AsyncIterator) async -> Element?
    )
    -> AnyAsyncSequence<Element> {
        return .init(makeIterator: {
            var iterator = self.makeAsyncIterator()
            return .init(nextElement: {
                await nextElement(&iterator)
            })
        })
    }
}

