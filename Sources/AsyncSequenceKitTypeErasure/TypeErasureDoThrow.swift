//
//  TypeErasureDoThrow.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

public struct DoThrowAsyncSeq<Element>: _Concurrency.AsyncSequence {
    public typealias AsyncIterator = DoThrowAsyncItr<Element>

    let asyncIterator: () -> AsyncIterator

    public func makeAsyncIterator() -> AsyncIterator {
        return self.asyncIterator()
    }
}

public struct DoThrowAsyncItr<Element>: _Concurrency.AsyncIteratorProtocol {
    let nextElement: () async throws -> Element?

    public func next() async throws -> Element? {
        return try await self.nextElement()
    }
}

extension _Concurrency.AsyncSequence {
    /// Wraps the async sequence inside a type-erased wrapper that **might throw**.
    ///
    /// Must be called using:
    ///
    ///     asyncSequence.erase({ try await $0() })
    ///
    /// - Parameters:
    ///   - next: A closure that takes a mutable reference to its iterator, which calls its `next` method
    ///           In other words, `{ try await $0() }`
    /// - Returns: A type-erased `AsyncSequence` wrapper that **might throw**
    ///
    /// - SeeAlso: ``DoThrowAsyncSeq``
    /// - SeeAlso: ``DoThrowAsyncItr``
    /// - Tag: _Concurrency_AsyncSequence_erase_DoThrowAsyncSeq
    public func erase(_ next: @escaping (inout Self.AsyncIterator) async throws -> Element?) -> DoThrowAsyncSeq<Element> {
        return DoThrowAsyncSeq(asyncIterator: {
            var itr = self.makeAsyncIterator()
            return DoThrowAsyncItr(nextElement: { try await next(&itr) })
        })
    }
}
