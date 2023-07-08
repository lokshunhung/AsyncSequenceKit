//
//  Boxed.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import Foundation

@propertyWrapper
internal final class Boxed<Value> {
    var wrappedValue: Value

    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    var projectedValue: Boxed<Value> {
        return self
    }
}
