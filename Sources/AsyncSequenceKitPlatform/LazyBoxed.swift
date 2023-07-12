//
//  LazyBoxed.swift
//
//
//  Created by LS Hung on 12/07/2023.
//

@propertyWrapper
public final class LazyBoxed<Value> {
    private var value: Value?
    private let factory: () -> Value
    private let lock: RawLock = .allocate()

    public init(factory: @escaping () -> Value) {
        self.factory = factory
    }

    deinit {
        self.lock.deallocate()
    }

    public var wrappedValue: Value {
        self.lock.lock()
        defer { self.lock.unlock() }

        if let value { return value }

        let value = self.factory()
        self.value = value
        return value
    }

    public var projectedValue: LazyBoxed<Value> { self }
}
