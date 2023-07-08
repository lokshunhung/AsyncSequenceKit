//
//  AsyncPublished.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

@propertyWrapper
public struct AsyncPublished<Value> {
    public init(wrappedValue: Value) {}

    @available(*, unavailable, message: "@AsyncPublished can only be applied to class properties")
    public var wrappedValue: Value {
        get { fatalError() } set { fatalError() }
    }
}
