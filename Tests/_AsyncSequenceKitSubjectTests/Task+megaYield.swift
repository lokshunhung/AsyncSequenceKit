//
//  Task+megaYield.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import Foundation

extension _Concurrency.Task where Success == Failure, Failure == Never {
    // https://github.com/pointfreeco/swift-clocks/blob/2320fda8d053860b2ae75e470099d4c294af81f0/Sources/Clocks/Internal/Yield.swift
    static func megaYield(count: Int = 10) async {
        for _ in 1...count {
            await Task<Void, Never>.detached(priority: .background, operation: { await Task.yield() }).value
        }
    }
}
