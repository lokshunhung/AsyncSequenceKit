//
//  Boxed.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

@propertyWrapper
public final class Boxed<Value> {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public var projectedValue: Boxed<Value> { self }
}
