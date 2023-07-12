//
//  PipeSubscriptionManager.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import class AsyncSequenceKitPlatform.AllocatedLock

internal final class PipeSubscriptionManager<Element, Failure>
    where Failure: Swift.Error
{
    typealias Downstream = PipeContinuation<Element, Failure>
    typealias DownstreamStorage = Bag<Downstream>
    typealias DownstreamID = DownstreamStorage.Key

    private let lock: AllocatedLock = .new()
    private var state: SubjectActiveState = .active
    private var downstreams: DownstreamStorage = .empty

    func add(downstream: Downstream) -> DownstreamID {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.downstreams.add(downstream)
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
            continuation.next(value)
        }
    }

    func error(_ error: Failure) {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard self.state.isActive else { return }
        self.downstreams.forEach { continuation in
            continuation.error(error)
        }
    }

    func complete() {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard self.state.isActive else { return }
        self.downstreams.forEach { continuation in
            continuation.complete()
        }

        self.state.deactivate()
        self.downstreams.removeAll()
    }
}
