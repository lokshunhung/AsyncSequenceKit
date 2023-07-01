//
//  PublishSubject.swift
//
//
//  Created by LS Hung on 02/07/2023.
//

import Foundation

public protocol PublishSubject<Element, Failure>: Subject
    where Failure: Swift.Error
{
    associatedtype Element
    associatedtype Failure
}

public final class NoThrowPublishSubject<Element>: PublishSubject {
    public typealias Failure = Never

    fileprivate typealias Buffer = _Concurrency.AsyncStream<Element>
    fileprivate typealias Continuation = _Concurrency.AsyncStream<Element>.Continuation
    fileprivate typealias FinalSelf = NoThrowPublishSubject<Element>

    private let buffer: Buffer
    private let continuation: Continuation
    private let asyncIterator: () -> AsyncIterator

    private init(buffer: Buffer,
                 continuation: Continuation,
                 asyncIterator: @escaping () -> AsyncIterator) {
        self.buffer = buffer
        self.continuation = continuation
        self.asyncIterator = asyncIterator
    }

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol {
        fileprivate var iterator: Buffer.AsyncIterator

        public mutating func next() async -> Element? {
            return await self.iterator.next()
        }
    }
}

extension NoThrowPublishSubject: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        return self.asyncIterator()
    }
}

extension NoThrowPublishSubject: Subject {
    public func next(_ value: Element) {
        self.continuation.yield(value)
    }

    public func error(_ error: Failure) {
    }

    public func complete() {
        self.continuation.finish()
    }
}

extension NoThrowPublishSubject {
    public convenience init() {
        var continuation: Continuation!
        let buffer = Buffer(Element.self, bufferingPolicy: .bufferingNewest(0), { continuation = $0 })
        self.init(
            buffer: buffer,
            continuation: continuation,
            asyncIterator: {
                let iterator = buffer.makeAsyncIterator()
                return .init(iterator: iterator)
            }
        )
    }
}
