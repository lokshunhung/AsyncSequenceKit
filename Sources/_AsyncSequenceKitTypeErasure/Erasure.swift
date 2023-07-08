//
//  Erasure.swift
//
//  Inspired from https://github.com/pointfreeco/swift-dependencies/blob/856df92f856e66a0c57b2d51dff62bcc24d48923/Sources/Dependencies/ConcurrencySupport/AsyncStream.swift#L137
//
//  Created by LS Hung on 08/07/2023.
//

import Foundation

extension _Concurrency.AsyncSequence {
    public func erase(_ produce: @escaping (inout Self.AsyncIterator) async -> Element?) -> AsyncStream<Element> {
        var iterator = self.makeAsyncIterator()
        return AsyncStream(unfolding: { await produce(&iterator) })
    }

    public func erase(_ produce: @escaping (inout Self.AsyncIterator) async throws -> Element?) -> AsyncThrowingStream<Element, any Swift.Error> {
        var iterator = self.makeAsyncIterator()
        return AsyncThrowingStream(unfolding: { try await produce(&iterator) })
    }
}
