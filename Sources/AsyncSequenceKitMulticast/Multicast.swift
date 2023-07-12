//
//  Multicast.swift
//
//
//  Created by LS Hung on 12/07/2023.
//

import AsyncSequenceKitSubject
import class AsyncSequenceKitPlatform.LazyBoxed

public struct Multicast<Upstream, Subject>
    where Upstream: _Concurrency.AsyncSequence,
          Subject: AsyncSequenceKitSubject.Subject<Upstream.Element, any Swift.Error>
{
    public typealias Element = Upstream.Element

    private let upstream: Upstream
    @LazyBoxed private var subject: Subject

    init(upstream: Upstream, subjectFactory: @escaping () -> Subject) {
        self.upstream = upstream
        self._subject = LazyBoxed(factory: subjectFactory)
    }

    public struct AsyncIterator: _Concurrency.AsyncIteratorProtocol {
        fileprivate var iterator: Subject.AsyncIterator

        public mutating func next() async rethrows -> Element? {
            return try await self.iterator.next()
        }
    }
}

extension Multicast: _Concurrency.AsyncSequence {
    public func makeAsyncIterator() -> AsyncIterator {
        let subject = self.subject
        let iterator = subject.makeAsyncIterator()
        return AsyncIterator(iterator: iterator)
    }
}

extension Multicast: Connectable {
    public typealias Failure = Swift.Error

    public func connect() -> _Concurrency.Task<Void, Never> {
        let subject = self.subject
        return Task {
            do {
                for try await value in self.upstream {
                    subject.next(value)
                }
                subject.complete()
            } catch is _Concurrency.CancellationError {
                // is subject already cleaned up here?
            } catch let error {
                subject.error(error)
            }
        }
    }
}
