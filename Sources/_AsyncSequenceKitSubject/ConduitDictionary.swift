//
//  ConduitDictionary.swift
//
//
//  Created by LS Hung on 02/07/2023.
//

import Foundation

// A simplified implementation of Bidirectional-Dictionary
// ref: OpenCombine/Sources/OpenCombine/Helprs/ConduitList.swift
internal enum ConduitDictionary<T>
    where T: Equatable, T: Hashable
{
    typealias ID = UInt
    case empty
    case single(ID, T)
    case many(storage: Dictionary<ID, T>, ids: Dictionary<T, ID>, nextID: ID)

    internal mutating func add(_ element: T) -> ID {
        switch self {
        case .empty:
            let id: ID = 0
            self = .single(id, element)
            return id
        case .single(let existingID, let existingElement):
            guard element == existingElement else {
                return existingID
            }
            let id: ID = existingID &+ 1
            let storage: Dictionary<ID, T> = [
                existingID: existingElement,
                id: element,
            ]
            let ids: Dictionary<T, ID> = [
                existingElement: existingID,
                element: id,
            ]
            let nextID: ID = id &+ 1
            self = .many(storage: storage, ids: ids, nextID: nextID)
            return id
        case .many(var storage, var ids, let id):
            if let existingID = ids[element] {
                return existingID
            }
            storage[id] = element
            ids[element] = id
            let nextID: ID = id &+ 1
            self = .many(storage: storage, ids: ids, nextID: nextID)
            return id
        }
    }

    @discardableResult
    internal mutating func remove(_ id: ID) -> T? {
        switch self {
        case .empty:
            return nil
        case .single(let existingID, let existingElement):
            guard id == existingID else {
                return nil
            }
            return existingElement
        case .many(var storage, var ids, let nextID):
            guard let element = storage[id] else {
                return nil
            }
            storage[id] = nil
            ids[element] = nil
            self = .many(storage: storage, ids: ids, nextID: nextID)
            return element
        }
    }

    internal func forEach(_ body: (T) throws -> Void) rethrows {
        switch self {
        case .empty:
            return
        case .single(_, let element):
            try body(element)
        case .many(let storage, _, _):
            try storage.values.forEach(body) // order not guaranteed
        }
    }
}
