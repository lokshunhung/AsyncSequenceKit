//
//  BehaviorSubjectTests.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import XCTest
@testable import AsyncSequenceKitSubject

final class BehaviorSubjectTests: XCTestCase {
    func testSimplePublish() async throws {
        let subject = NoThrowBehaviorSubject<Int>(1)

        let a = Task {
            var a: [Int] = []
            for await element in subject {
                a.append(element)
            }
            return a
        }
        let b = Task {
            var b: [Int] = []
            for await element in subject {
                b.append(element)
            }
            return b
        }
        await Task.megaYield(count: 20)

        subject.next(2)
        subject.next(3)
        await Task.megaYield(count: 20)

        subject.complete()
        await Task.megaYield(count: 20)

        let received = await (a: a.value, b: b.value)
        XCTAssertEqual(received.a, [1, 2, 3])
        XCTAssertEqual(received.b, [1, 2, 3])
    }

    func testSubscribingAfterPublishing() async throws {
        let subject = NoThrowBehaviorSubject<Int>(1) // 1 should not be received, but

        subject.next(2) // 2 should be received
        await Task.megaYield(count: 20)

        let a = Task {
            var a: [Int] = []
            for await element in subject {
                a.append(element)
            }
            return a
        }
        let b = Task {
            var b: [Int] = []
            for await element in subject {
                b.append(element)
            }
            return b
        }
        await Task.megaYield(count: 20)

        subject.next(3)
        subject.next(4)
        subject.complete()
        await Task.megaYield(count: 20)

        let received = await (a: a.value, b: b.value)
        XCTAssertEqual(received.a, [2, 3, 4])
        XCTAssertEqual(received.b, [2, 3, 4])
    }

    func testGetCurrent() async throws {
        let subject = NoThrowBehaviorSubject<Int>(1)

        await Task.megaYield(count: 20)
        XCTAssertEqual(subject.value, 1)

        subject.next(2)
        await Task.megaYield(count: 20)
        XCTAssertEqual(subject.value, 2)

        subject.complete()
        await Task.megaYield(count: 20)
        XCTAssertEqual(subject.value, 2) // TODO: should we keep this?
    }
}
