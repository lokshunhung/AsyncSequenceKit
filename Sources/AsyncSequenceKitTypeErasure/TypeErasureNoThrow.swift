//
//  TypeErasureNoThrow.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

public struct NoThrowAsyncSeq<Element>: _Concurrency.AsyncSequence {
    public typealias AsyncIterator = NoThrowAsyncItr<Element>

    let asyncIterator: () -> AsyncIterator

    public func makeAsyncIterator() -> AsyncIterator {
        return self.asyncIterator()
    }
}

public struct NoThrowAsyncItr<Element>: _Concurrency.AsyncIteratorProtocol {
    let nextElement: () async -> Element?

    public func next() async -> Element? {
        return await self.nextElement()
    }
}

extension NoThrowAsyncSeq {
    public init(unfolding factory: @escaping () -> () async -> Element?) {
        self.init(asyncIterator: {
            .init(nextElement: factory())
        })
    }
}

extension _Concurrency.AsyncSequence {
    /// Wraps the async sequence inside a type-erased wrapper that **does not throw**.
    /// 
    /// Must be called using:
    ///
    ///     asyncSequence.erase({ await $0() })
    ///
    /// - Parameters:
    ///   - next: A closure that takes a mutable reference to its iterator, which calls its `next` method
    ///           In other words, `{ await $0() }`
    /// - Returns: A type-erased `AsyncSequence` wrapper that **does not throw**
    ///
    /// - SeeAlso: ``NoThrowAsyncSeq``
    /// - SeeAlso: ``NoThrowAsyncItr``
    /// - Tag: _Concurrency_AsyncSequence_erase_NoThrowAsyncSeq
    public func erase(_ next: @escaping (inout Self.AsyncIterator) async -> Element?) -> NoThrowAsyncSeq<Element> {
        return NoThrowAsyncSeq(unfolding: {
            var itr = self.makeAsyncIterator()
            return { await next(&itr) }
        })
    }
}
