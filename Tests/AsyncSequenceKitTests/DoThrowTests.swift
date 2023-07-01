//
//  DoThrowTests.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import XCTest
@testable import AsyncSequenceKit

// Sanity checks
final class DoThrowTests: XCTestSuite {
    func testEraseToDoThrowAsyncSeq() async throws {
        let expected: [Int] = [1, 2, 3]

        let stream = AsyncStream(Int.self, { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        })
        let erased = stream.erase({ await $0() }) as DoThrowAsyncSeq<Int>

        var result: [Int] = []
        for try await element in erased {
            result.append(element)
        }
        XCTAssertEqual(result, expected)
    }

    func testEraseToDoThrowAsyncSeq_ThrowingError() async throws {
        let expected: [Int] = [1, 2, 3]

        let stream = AsyncThrowingStream(Int.self, { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish(throwing: ThrowingErrorTest_Error())
        })
        let erased = stream.erase({ try await $0() }) as DoThrowAsyncSeq<Int>

        var result: [Int] = []
        var caughtError: Optional<any Error> = nil
        do {
            for try await element in erased {
                result.append(element)
            }
        } catch {
            caughtError = error
        }
        XCTAssertEqual(result, expected)
        XCTAssertNotNil(caughtError)
        XCTAssertEqual(String(describing: type(of: caughtError)), "Optional<ThrowingErrorTest_Error>")
    }

    private struct ThrowingErrorTest_Error: Error {}
}
