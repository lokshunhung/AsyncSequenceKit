//
//  NoThrowTests.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import XCTest
@testable import AsyncSequenceKit

// Sanity checks
final class NoThrowTests: XCTestSuite {
    func testEraseToNoThrowAsyncSeq() async throws {
        let expected: [Int] = [1, 2, 3]

        let stream = AsyncStream(Int.self, { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        })
        let erased = stream.erase({ await $0() }) as NoThrowAsyncSeq<Int>

        var result: [Int] = []
        for await element in erased {
            result.append(element)
        }
        XCTAssertEqual(result, expected)
    }
}
