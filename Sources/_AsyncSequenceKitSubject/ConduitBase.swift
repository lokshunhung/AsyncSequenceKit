//
//  ConduitBase.swift
//
//  Adapted from OpenCombine/Sources/OpenCombine/Helprs/ConduitBase.swift
//
//  Created by Sergej Jaskiewicz on 25.06.2020.
//

internal class ConduitBase<Output, Failure: Error> {
    internal init() {}

    internal func value(_ value: Output) {
        fatalError()
    }

    internal func error(_ error: Failure) {
        fatalError()
    }

    internal func complete() {
        fatalError()
    }

    internal func cancel() {
        fatalError()
    }
}

extension ConduitBase: Equatable {
    internal static func == (lhs: ConduitBase<Output, Failure>,
                             rhs: ConduitBase<Output, Failure>) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension ConduitBase: Hashable {
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
