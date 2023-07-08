//
//  PublishSubjectTests.swift
//
//
//  Created by LS Hung on 08/07/2023.
//

import XCTest
@testable import _AsyncSequenceKitSubject

final class PublishSubjectTests: XCTestCase {
    func testSimplePublish() async throws {
        let subject = NoThrowPublishSubject<Int>()

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

        subject.next(1)
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
        let subject = NoThrowPublishSubject<Int>()

        subject.next(1) // should not be received
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

        subject.next(2)
        subject.next(3)
        subject.complete()
        await Task.megaYield(count: 20)

        let received = await (a: a.value, b: b.value)
        XCTAssertEqual(received.a, [2, 3])
        XCTAssertEqual(received.b, [2, 3])
    }
}
