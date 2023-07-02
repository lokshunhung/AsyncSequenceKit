//
//  BehaviorSubject.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

public protocol BehaviorSubject<Element, Failure>: Subject
    where Failure: Swift.Error
{
    associatedtype Element
    associatedtype Failure

    var current: Element { get }
}

public final class NoThrowBehaviorSubject<Element> {
    public typealias Failure = Never

    fileprivate typealias Buffer = _Concurrency.AsyncStream<Element>
    fileprivate typealias Continuation = _Concurrency.AsyncStream<Element>.Continuation
    fileprivate typealias FinalSelf = NoThrowBehaviorSubject<Element>

    private let lock: NSLock = NSLock()
    private var currentValue: Element
    private let buffer: Buffer
    private let continuation: Continuation
    private let asyncIterator: (FinalSelf) -> AsyncIterator

    private init(currentValue: Element,
                 buffer: Buffer,
                 continuation: Continuation,
                 asyncIterator: @escaping (FinalSelf) -> AsyncIterator) {
        self.currentValue = currentValue
        self.buffer = buffer
        self.continuation = continuation
        self.asyncIterator = asyncIterator
    }

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol {
        fileprivate var initialValue: Element?
        fileprivate var iterator: Buffer.AsyncIterator
        fileprivate let parentSequence: NoThrowBehaviorSubject

        public mutating func next() async -> Element? {
            if let value = self.initialValue {
                self.initialValue = nil
                self.parentSequence.current = value
                return initialValue
            }

            let value = await self.iterator.next()
            if let value {
                self.parentSequence.current = value
            }
            return value
        }
    }
}

extension NoThrowBehaviorSubject: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        return self.asyncIterator(self)
    }
}

extension NoThrowBehaviorSubject: BehaviorSubject {
    public fileprivate(set) var current: Element {
        get {
            lock.lock()
            defer { lock.unlock() }
            return self.currentValue
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            self.currentValue = newValue
        }
    }

    public func next(_ value: Element) {
        self.continuation.yield(value)
    }

    public func error(_ error: Failure) {
    }

    public func complete() {
        self.continuation.finish()
    }
}

extension NoThrowBehaviorSubject {
    public convenience init(_ value: Element) {
        let (buffer, continuation) = Buffer.makeStream(of: Element.self, bufferingPolicy: .bufferingNewest(1))
        self.init(
            currentValue: value,
            buffer: buffer, // TODO: Important: shared buffer?
            continuation: continuation,
            asyncIterator: {
                let iterator = buffer.makeAsyncIterator()
                return .init(initialValue: value, iterator: iterator, parentSequence: $0)
            }
        )
    }
}
