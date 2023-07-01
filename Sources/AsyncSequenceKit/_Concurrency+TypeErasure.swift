//
//  AsyncSequence+TypeErasure.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

extension _Concurrency.AsyncIteratorProtocol {
    /// Equivalent to `AsyncIteratorProtocol.next()`.
    /// Added to make type erasing calls less noisy.
    /// See [`_Concurrency.AsyncSequence.erase(_:)`](x-source-tag://_Concurrency_AsyncSequence_erase) for source.
    /// - Returns: The next element, if it exists, or `nil` to signal the end of the sequence.
    ///
    /// - SeeAlso: [AsyncSequence.erase(_:)](x-source-tag://_Concurrency_AsyncSequence_erase_NoThrowAsyncSeq)
    /// - SeeAlso: [AsyncSequence.erase(_:)](x-source-tag://_Concurrency_AsyncSequence_erase_DoThrowAsyncSeq)
    @inline(__always) @inlinable
    public mutating func callAsFunction() async rethrows -> Element? {
        // documentation link: https://stackoverflow.com/a/54564301
        return try await self.next()
    }
}

/// - Tag: _Concurrency_AsyncSequence_erase
extension _Concurrency.AsyncSequence {
    /// Wraps the async sequence inside a type-erased wrapper that **does not throw**.
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
        return NoThrowAsyncSeq(asyncIterator: {
            var itr = self.makeAsyncIterator()
            return NoThrowAsyncItr(nextElement: { await next(&itr) })
        })
    }

    /// Wraps the async sequence inside a type-erased wrapper that **might throw**.
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
