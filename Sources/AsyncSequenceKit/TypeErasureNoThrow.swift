//
//  TypeErasureNoThrow.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

public struct NoThrowAsyncItr<Element>: _Concurrency.AsyncIteratorProtocol {
    let nextElement: () async -> Element?

    public func next() async -> Element? {
        return await self.nextElement()
    }
}

public struct NoThrowAsyncSeq<Element>: _Concurrency.AsyncSequence {
    public typealias AsyncIterator = NoThrowAsyncItr<Element>

    let asyncIterator: () -> AsyncIterator

    public func makeAsyncIterator() -> AsyncIterator {
        return self.asyncIterator()
    }
}
