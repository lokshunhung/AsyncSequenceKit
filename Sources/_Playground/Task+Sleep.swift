//
//  Task+Sleep.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation

extension _Concurrency.Task where Success == Never, Failure == Never {
    internal static func sleep(milliseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }
}
