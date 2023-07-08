//
//  _Concurrency+Callable.swift
//  
//
//  Created by LS Hung on 09/07/2023.
//

extension _Concurrency.AsyncIteratorProtocol {
    /// Equivalent to `AsyncIteratorProtocol.next()`.
    /// Added to make type erasing calls less noisy.
    ///
    /// - Returns: The next element, if it exists, or `nil` to signal the end of the sequence.
    ///
    /// - SeeAlso: [AsyncSequence.erase(_:)](x-source-tag://_Concurrency_AsyncSequence_erase_NoThrowAsyncSeq)
    /// - SeeAlso: [AsyncSequence.erase(_:)](x-source-tag://_Concurrency_AsyncSequence_erase_DoThrowAsyncSeq)
    @inline(__always) @inlinable
    public mutating func callAsFunction() async rethrows -> Element? {
        return try await self.next()
    }
}

// xcode documentation tags: https://stackoverflow.com/a/54564301
