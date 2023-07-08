//
//  PipeContinuation.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import Foundation

@usableFromInline
internal struct PipeContinuation<Element, Failure>
    where Failure: Swift.Error
{
    @usableFromInline let next: (Element) -> Void
    @usableFromInline let error: (Failure) -> Void
    @usableFromInline let complete: () -> Void
}

internal extension PipeContinuation where Failure == Never {
    @usableFromInline
    init(_ continuation: _Concurrency.AsyncStream<Element>.Continuation) {
        self.init(next: { continuation.yield($0) },
                  error: { _ in },
                  complete: { continuation.finish() })
    }
}

internal extension PipeContinuation {
    @usableFromInline
    init(_ continuation: _Concurrency.AsyncThrowingStream<Element, Failure>.Continuation) {
        self.init(next: { continuation.yield($0) },
                  error: { continuation.finish(throwing: $0) },
                  complete: { continuation.finish() })
    }
}
