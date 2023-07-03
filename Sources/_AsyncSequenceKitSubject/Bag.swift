//
//  Bag.swift
//
//  Adapted from RxSwift/Platform/DataStructures/Bag.swift
//  Adapted from OpenCombine/Sources/OpenCombine/Helprs/ConduitList.swift
//
//  Created by LS Hung on 03/07/2023.
//

import Foundation

@usableFromInline
internal struct BagKey: RawRepresentable, Equatable, Hashable {
    @usableFromInline
    let rawValue: UInt

    @usableFromInline
    init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    @usableFromInline
    func next() -> Self {
        return .init(rawValue: self.rawValue &+ 1)
    }

    @usableFromInline
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    @usableFromInline
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue)
    }
}


@usableFromInline
internal enum Bag<Element> {
    @usableFromInline
    typealias Key = BagKey

    case empty
    case single(Key, Element)
    case many([Key: Element], nextKey: Key)

    @usableFromInline
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

    @usableFromInline
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

    @usableFromInline
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

    @usableFromInline
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
