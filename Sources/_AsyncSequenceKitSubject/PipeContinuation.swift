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
    let next: (Element) -> Void
    let error: (Failure) -> Void
    let complete: () -> Void
}

internal extension PipeContinuation where Failure == Never {
    @inline(__always) @usableFromInline
    init(_ continuation: _Concurrency.AsyncStream<Element>.Continuation) {
        self.init(next: { continuation.yield($0) },
                  error: { _ in },
                  complete: { continuation.finish() })
    }
}

internal extension PipeContinuation {
    @inline(__always) @usableFromInline
    init(_ continuation: _Concurrency.AsyncThrowingStream<Element, Failure>.Continuation) {
        self.init(next: { continuation.yield($0) },
                  error: { continuation.finish(throwing: $0) },
                  complete: { continuation.finish() })
    }
}
