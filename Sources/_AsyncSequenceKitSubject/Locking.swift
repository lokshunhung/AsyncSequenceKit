//
//  Lock.swift
//
//  Adapted from swift-async-algorithms/Sources/AsyncAlgorithms/Locking.swift
//
//  Created by LS Hung on 03/07/2023.
//

#if canImport(Darwin)
@_implementationOnly import Darwin
#elseif canImport(Glibc)
@_implementationOnly import Glibc
#elseif canImport(WinSDK)
@_implementationOnly import WinSDK
#endif

internal struct Lock {
    #if canImport(Darwin)
    typealias Primitive = os_unfair_lock
    #elseif canImport(Glibc)
    typealias Primitive = pthread_mutex_t
    #elseif canImport(WinSDK)
    typealias Primitive = SRWLOCK
    #endif

    typealias PlatformLock = UnsafeMutablePointer<Primitive>
    let platformLock: PlatformLock

    private init(_ platformLock: PlatformLock) {
        self.platformLock = platformLock
    }

    fileprivate static func initialize(_ platformLock: PlatformLock) {
        #if canImport(Darwin)
        platformLock.initialize(to: os_unfair_lock())
        #elseif canImport(Glibc)
        pthread_mutex_init(platformLock, nil)
        #elseif canImport(WinSDK)
        InitializeSRWLock(platformLock)
        #endif
    }

    fileprivate static func deinitialize(_ platformLock: PlatformLock) {
        #if canImport(Glibc)
        pthread_mutex_destroy(platformLock)
        #endif
        platformLock.deinitialize(count: 1)
    }

    fileprivate static func lock(_ platformLock: PlatformLock) {
        #if canImport(Darwin)
        os_unfair_lock_lock(platformLock)
        #elseif canImport(Glibc)
        pthread_mutex_lock(platformLock)
        #elseif canImport(WinSDK)
        AcquireSRWLockExclusive(platformLock)
        #endif
    }

    fileprivate static func unlock(_ platformLock: PlatformLock) {
        #if canImport(Darwin)
        os_unfair_lock_unlock(platformLock)
        #elseif canImport(Glibc)
        pthread_mutex_unlock(platformLock)
        #elseif canImport(WinSDK)
        ReleaseSRWLockExclusive(platformLock)
        #endif
    }

    static func allocate() -> Lock {
        let platformLock = PlatformLock.allocate(capacity: 1)
        initialize(platformLock)
        return Lock(platformLock)
    }

    func deinitialize() {
        Lock.deinitialize(platformLock)
    }

    func lock() {
        Lock.lock(platformLock)
    }

    func unlock() {
        Lock.unlock(platformLock)
    }

    /// Acquire the lock for the duration of the given block.
    ///
    /// This convenience method should be preferred to `lock` and `unlock` in
    /// most situations, as it ensures that the lock will be released regardless
    /// of how `body` exits.
    ///
    /// - Parameter body: The block to execute while holding the lock.
    /// - Returns: The value returned by the block.
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try body()
    }
}

//struct Synchronized<T> {
//    private final class LockBuffer: ManagedBuffer<T, Lock.Primitive> {
//        @inline(__always) @usableFromInline
//        static func create(initialValue: T) -> ManagedBuffer<T, Lock.Primitive> {
//            return Self.create(minimumCapacity: 1, makingHeaderWith: { buffer in
//                buffer.withUnsafeMutablePointerToElements { platformLock in
//                    Lock.initialize(platformLock)
//                }
//                return initialValue
//            })
//        }
//
//        deinit {
//            withUnsafeMutablePointerToElements { platformLock in
//                Lock.deinitialize(platformLock)
//            }
//        }
//    }
//
//    private let buffer: ManagedBuffer<T, Lock.Primitive>
//
//    init(_ initialValue: T) {
//        self.buffer = LockBuffer.create(initialValue: initialValue)
//    }
//
//    func synchronized<R>(_ body: (inout T) throws -> R) rethrows -> R {
//        try self.buffer.withUnsafeMutablePointers { (header: UnsafeMutablePointer<T>, platformLock: UnsafeMutablePointer<Lock.Primitive>) in
//            Lock.lock(platformLock)
//            defer { Lock.unlock(platformLock) }
//            return try body(&header.pointee)
//        }
//    }
//}
