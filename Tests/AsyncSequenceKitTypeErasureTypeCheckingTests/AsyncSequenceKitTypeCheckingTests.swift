//
//  AsyncSequenceKitTypeCheckingTests.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import XCTest
@testable import AsyncSequenceKitTypeErasure

// Commented out code contains expected error
final class AsyncSequenceKitTypeCheckingTests: XCTestCase {
    func testTypeInference() async throws {
        let noThrowStream = AsyncStream(Int.self, { continuation in continuation.finish() })

        let noThrowTypeErased = noThrowStream.erase({ await $0() })
        XCTAssertEqual(String(describing: type(of: noThrowTypeErased)), "NoThrowAsyncSeq<Int>")

        let doThrowStream = AsyncThrowingStream(Int.self, { continuation in continuation.finish() })
        let doThrowTypeErased = doThrowStream.erase({ try await $0() })
        XCTAssertEqual(String(describing: type(of: doThrowTypeErased)), "DoThrowAsyncSeq<Int>")
    }

    func testTypeCheckForNoThrow() async throws {
        try XCTSkipIf(true, "Type check for NoThrow")

        let noThrowStream = AsyncStream(Int.self, { continuation in continuation.finish() })
        let noThrowTypeErased = noThrowStream.erase({ await $0() })
        for await element in noThrowTypeErased {
            __("The for await syntax should compile fine without the try keyword", element)
        }
        for try await element in noThrowTypeErased {
            __("The for await syntax should compile fine with the try keyword", element)
        }
    }

    func testTypeCheckForDoThrow() async throws {
        try XCTSkipIf(true, "Type check for DoThrow")

        let doThrowStream = AsyncThrowingStream(Int.self, { continuation in continuation.finish() })
        let doThrowTypeErased = doThrowStream.erase({ try await $0() })
        //for await element in doThrowTypeErased {
        //    __("Call can throw, but is not marked with 'try' and the error is not handled", element)
        //}
        for try await element in doThrowTypeErased {
            __("The for await syntax should compile fine with the try keyword", element)
        }
    }

    func testTypeAnnotation() async throws {
        try XCTSkipIf(true, "Type annotation")
        let noThrowStream = AsyncStream(Int.self, { continuation in continuation.finish() })

        let typeAnnotatedNoThrowTypeErased: NoThrowAsyncSeq<Int> = noThrowStream.erase({ await $0() })
        let typeCastingNoThrowTypeErased = noThrowStream.erase({ await $0() }) as DoThrowAsyncSeq<Int>
        __("Works!", typeAnnotatedNoThrowTypeErased, typeCastingNoThrowTypeErased)

        let typeAnnotatedDoThrowTypeErased: DoThrowAsyncSeq<Int> = noThrowStream.erase({ await $0() })
        let typeCastingDoThrowTypeErased = noThrowStream.erase({ await $0() }) as DoThrowAsyncSeq<Int>
        __("Works!", typeAnnotatedDoThrowTypeErased, typeCastingDoThrowTypeErased)

        //let doThrowTypeErased = noThrowStream.erase({ try await $0() })
        //__("No calls to throwing functions occur within 'try' expression")
    }

    private func __(_ a: Any, _ b: Any? = nil, _ c: Any? = nil) {}
}
