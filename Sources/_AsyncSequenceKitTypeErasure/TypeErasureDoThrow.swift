//
//  TypeErasureDoThrow.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

public struct DoThrowAsyncItr<Element>: _Concurrency.AsyncIteratorProtocol {
    let nextElement: () async throws -> Element?

    public func next() async throws -> Element? {
        return try await self.nextElement()
    }
}

public struct DoThrowAsyncSeq<Element>: _Concurrency.AsyncSequence {
    public typealias AsyncIterator = DoThrowAsyncItr<Element>

    let asyncIterator: () -> AsyncIterator

    public func makeAsyncIterator() -> AsyncIterator {
        return self.asyncIterator()
    }
}
