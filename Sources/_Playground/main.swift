//
//  main.swift
//
//
//  Created by LS Hung on 01/07/2023.
//

import Foundation
import AsyncSequenceKit

let s: AsyncStream<Int> = .init { continuation in
    Task {
        for i in 0...10 {
            continuation.yield(i)
            try await Task.sleep(milliseconds: UInt64(i * 100))
        }
        continuation.finish()
    }
}

let t: AsyncThrowingStream<Int, Swift.Error> = .init { continuation in
    Task {
        for i in 0...10 {
            continuation.yield(i)
            try await Task.sleep(milliseconds: UInt64(i * 100))
        }
        continuation.finish()
    }
}

for await e in s { print(e) }
for try await e in s { print(e) }

//for await e in t { print(e) } // ok
for try await e in t { print(e) } // ok


//for await e in s.eraseToAny() { print(e) }
//for try await e in s.eraseToAny() { print(e) }

//for await e in t.eraseToAny() { print(e) }
//for try await e in t.eraseToAny() { print(e) }

for await e in s.eraseToAny({ await $0.next() }) { print(e) } // ok

//for try await e in t.eraseToAny({ try await $0.next() }) { print(e) } // bad
