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

public struct NoThrowPublishSubject<Element>: PublishSubject {
    public typealias Failure = Never

    fileprivate typealias Buffer = _Concurrency.AsyncStream<Element>
    fileprivate typealias Continuation = _Concurrency.AsyncStream<Element>.Continuation

    private let lock: NSLock = NSLock()
    private let subscriptionManager: SubscriptionManager

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol {
        fileprivate let buffer: Buffer
        fileprivate var iterator: Buffer.AsyncIterator

        public mutating func next() async -> Element? {
            return await self.iterator.next()
        }
    }
}

extension NoThrowPublishSubject.AsyncIterator {
    fileprivate init(subscriptionManager: NoThrowPublishSubject.SubscriptionManager) {
        let (buffer, continuation) = NoThrowPublishSubject.Buffer.makeStream(of: Element.self, bufferingPolicy: .unbounded)
        let downstreamID = subscriptionManager.add(downstream: continuation)
        continuation.onTermination = { [weak subscriptionManager] reason in
            subscriptionManager?.remove(downstream: downstreamID)
        }
        let iterator = buffer.makeAsyncIterator()
        self.init(buffer: buffer, iterator: iterator)
    }
}

extension NoThrowPublishSubject: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        self.lock.lock()
        defer { self.lock.unlock() }
        return AsyncIterator(subscriptionManager: self.subscriptionManager)
    }
}

extension NoThrowPublishSubject: Subject {
    public func next(_ value: Element) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.subscriptionManager.next(value)
    }

    public func error(_ error: Failure) {
    }

    public func complete() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.subscriptionManager.complete()
    }
}

extension NoThrowPublishSubject {
    fileprivate final class SubscriptionManager {
        typealias DownstreamID = UInt

        private let lock: NSLock = NSLock()
        private var state: SubjectActiveState = .active
        private var downstreams: DownstreamStorage = .empty

        func add(downstream: Buffer.Continuation) -> DownstreamID {
            self.lock.lock()
            defer { self.lock.unlock() }
            let id = self.downstreams.add(downstream)
            return id
        }

        func remove(downstream id: DownstreamID) {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.downstreams.remove(id)
        }

        func next(_ value: Element) {
            self.lock.lock()
            defer { self.lock.unlock() }

            guard self.state.isActive else { return }
            self.downstreams.forEach { continuation in
                continuation.yield(value)
            }
        }

        func error(_ error: Failure) {}

        func complete() {
            self.lock.lock()
            defer { self.lock.unlock() }

            guard self.state.isActive else { return }
            self.downstreams.forEach { continuation in
                continuation.finish()
            }

            self.state.deactivate()
        }
    }

    fileprivate enum DownstreamStorage {
        typealias ID = UInt
        typealias Element = Buffer.Continuation

        case empty
        case single(ID, Element)
        case many([ID: Element], nextID: ID)

        mutating func add(_ element: Element) -> ID {
            switch self {
            case .empty:
                let id: ID = 0
                self = .single(id, element)
                return id
            case .single(let existingID, let existingElement):
                let id = existingID &+ 1
                let storage = [existingID: existingElement, id: element]
                let nextID = id &+ 1
                self = .many(storage, nextID: nextID)
                return id
            case .many(var storage, let id):
                storage[id] = element
                let nextID = id &+ 1
                self = .many(storage, nextID: nextID)
                return id
            }
        }

        mutating func remove(_ id: ID) {
            switch self {
            case .empty:
                return
            case .single(let existingID, _):
                guard id == existingID else { return }
                self = .empty
            case .many(var storage, let nextID):
                guard storage.removeValue(forKey: id) != nil else { return }
                if storage.isEmpty {
                    self = .empty
                } else {
                    self = .many(storage, nextID: nextID)
                }
            }
        }

        func forEach(_ body: (Element) throws -> Void) rethrows {
            switch self {
            case .empty:
                break
            case .single(_, let element):
                try body(element)
            case .many(let storage, _):
                try storage.values.forEach(body)
            }
        }
    }
}

extension NoThrowPublishSubject {
    public init() {
        self.init(subscriptionManager: SubscriptionManager())
    }
}
