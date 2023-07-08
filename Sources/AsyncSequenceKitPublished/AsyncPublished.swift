//
//  AsyncPublished.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import AsyncSequenceKitSubject

@propertyWrapper
public struct AsyncPublished<Value> {
    private let box: BoxedSubject

    public init(wrappedValue: Value) {
        self.box = BoxedSubject(subject: .init(wrappedValue))
    }

    // TODO: hook into ObservableObject's objectWillChange
    public static subscript<T>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            let `self` = instance
            return self[keyPath: storageKeyPath].box.subject.value
        }
        set {
            let `self` = instance
            self[keyPath: storageKeyPath].box.subject.next(newValue)
        }
    }

    @available(*, unavailable, message: "@AsyncPublished can only be applied to class properties")
    public var wrappedValue: Value {
        get { fatalError() } set { fatalError() }
    }

    public var projectedValue: AsyncStream<Value> {
        // TODO: eager creation of the iterator isn't good, bring back NoThrowAsyncSeq
        var iterator = self.box.subject.makeAsyncIterator()
        return AsyncStream(unfolding: { await iterator.next() })
    }
}

private extension AsyncPublished {
    // TODO: use reference type for Subject
    final class BoxedSubject {
        let subject: NoThrowBehaviorSubject<Value>
        init(subject: NoThrowBehaviorSubject<Value>) {
            self.subject = subject
        }
    }
}
