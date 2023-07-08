//
//  _Concurrency+Erasure.swift
//
//  Inspired by https://github.com/pointfreeco/swift-dependencies/blob/856df92f856e66a0c57b2d51dff62bcc24d48923/Sources/Dependencies/ConcurrencySupport/AsyncStream.swift#L137
//  to use `AsyncStream` and `AsyncThrowingStream` as type erasure wrappers
//
//  Created by LS Hung on 08/07/2023.
//

extension _Concurrency.AsyncIteratorProtocol {
    /// Equivalent to `AsyncIteratorProtocol.next()`.
    /// Added to make type erasing calls less noisy.
    /// See [`_Concurrency.AsyncSequence.erase(_:)`](x-source-tag://_Concurrency_AsyncSequence_erase) for source.
    /// - Returns: The next element, if it exists, or `nil` to signal the end of the sequence.
    ///
    /// - SeeAlso: [AsyncSequence.erase(_:)](x-source-tag://_Concurrency_AsyncSequence_erase_AsyncStream)
    /// - SeeAlso: [AsyncSequence.erase(_:)](x-source-tag://_Concurrency_AsyncSequence_erase_AsyncThrowingStream)
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
    /// - Tag: _Concurrency_AsyncSequence_erase_AsyncStream
    public func erase(_ next: @escaping (inout Self.AsyncIterator) async -> Element?) -> AsyncStream<Element> {
        var iterator = self.makeAsyncIterator()
        return AsyncStream(unfolding: { await next(&iterator) })
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
    /// - Tag: _Concurrency_AsyncSequence_erase_AsyncThrowingStream
    public func erase(_ produce: @escaping (inout Self.AsyncIterator) async throws -> Element?) -> AsyncThrowingStream<Element, any Swift.Error> {
        var iterator = self.makeAsyncIterator()
        return AsyncThrowingStream(unfolding: { try await produce(&iterator) })
    }
}
