//
//  Bag.swift
//
//  Adapted from RxSwift/Platform/DataStructures/Bag.swift
//  Adapted from OpenCombine/Sources/OpenCombine/Helprs/ConduitList.swift
//
//  Created by LS Hung on 03/07/2023.
//

import Foundation

internal struct BagKey: RawRepresentable, Equatable, Hashable {
    let rawValue: UInt

    init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    func next() -> Self {
        return .init(rawValue: self.rawValue &+ 1)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}


internal enum Bag<Element> {
    typealias Key = BagKey

    case empty
    case single(Key, Element)
    case many([Key: Element], nextKey: Key)

    var count: Int {
        switch self {
        case .empty:
            return 0
        case .single:
            return 1
        case .many(let storage, _):
            return storage.count
        }
    }

    mutating func add(_ element: Element) -> Key {
        switch self {
        case .empty:
            let key = BagKey(rawValue: 0)
            self = .single(key, element)
            return key
        case .single(let existingKey, let existingElement):
            let key = existingKey.next()
            let storage = [existingKey: existingElement, key: element]
            let nextKey = key.next()
            self = .many(storage, nextKey: nextKey)
            return key
        case .many(var storage, let key):
            storage[key] = element
            let nextKey = key.next()
            self = .many(storage, nextKey: nextKey)
            return key
        }
    }

    mutating func remove(_ key: Key) {
        switch self {
        case .empty:
            return
        case .single(let existingKey, _):
            guard key == existingKey else { return }
            self = .empty
        case .many(var storage, let nextKey):
            guard storage.removeValue(forKey: key) != nil else { return }
            if storage.isEmpty {
                self = .empty
            } else {
                self = .many(storage, nextKey: nextKey)
            }
        }
    }

    mutating func removeAll() {
        self = .empty
    }

    @inline(__always) @usableFromInline
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
