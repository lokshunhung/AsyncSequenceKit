//
//  SubjectActiveState.swift
//
//
//  Created by LS Hung on 02/07/2023.
//

import Foundation

@usableFromInline
internal enum SubjectActiveState {
    case active
    case inactive

    @usableFromInline
    var isActive: Bool {
        switch self {
        case .active:
            return true
        case .inactive:
            return false
        }
    }

    @usableFromInline
    mutating func deactivate() {
        guard case .active = self else {
            fatalError("SubjectActiveState already transitioned to .inactive, but deactivate() is called again")
        }
        self = .inactive
    }
}
