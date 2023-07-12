//
//  RefCount.swift
//
//
//  Created by LS Hung on 12/07/2023.
//

import class AsyncSequenceKitPlatform.AllocatedLock
import class AsyncSequenceKitPlatform.Boxed

public struct RefCount<Upstream>
    where Upstream: Connectable<Upstream.Element>
{
    public typealias Element = Upstream.Element

    private let lock: AllocatedLock = .new()
    @Boxed private var state: RefCountState = .disconnected
    private let upstream: Upstream

    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol {
        fileprivate var iterator: Upstream.AsyncIterator

        public mutating func next() async rethrows -> Element? {
            return try await self.iterator.next()
        }
    }
}

extension RefCount: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        self.lock.lock()
        defer { self.lock.unlock() }

        self.state.increment(connecting: self.upstream)
        let iterator = self.upstream.makeAsyncIterator() // TODO: where to call self.state.decrement()?
        return AsyncIterator(iterator: iterator)
    }
}

private enum RefCountState {
    case disconnected
    case connected(subscriptionCount: Int, task: Task<Void, Never>)

    mutating func increment(connecting connectable: some Connectable) {
        switch self {
        case .connected(let subscriptionCount, let task):
            self = .connected(subscriptionCount: subscriptionCount + 1, task: task)
        case .disconnected:
            let subscriptionTask = connectable.connect()
            self = .connected(subscriptionCount: 1, task: subscriptionTask)
        }
    }

    mutating func decrement() {
        switch self {
        case .connected(let subscriptionCount, let task) where subscriptionCount > 1:
            self = .connected(subscriptionCount: subscriptionCount - 1, task: task)
        case .connected(_, let task):
            task.cancel()
            self = .disconnected
        case .disconnected:
            break
        }
    }
}
