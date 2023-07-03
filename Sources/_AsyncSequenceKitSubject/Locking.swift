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

#if canImport(Darwin)
typealias LockPrimitive = os_unfair_lock
#elseif canImport(Glibc)
typealias LockPrimitive = pthread_mutex_t
#elseif canImport(WinSDK)
typealias LockPrimitive = SRWLOCK
#endif

internal final class AllocatedLock {
    typealias Ptr = UnsafeMutablePointer<LockPrimitive>

    private let ptr: Ptr

    init(ptr: Ptr) {
        self.ptr = ptr
    }

    static func new() -> Self {
        let ptr = Ptr.allocate(capacity: 1)
        _initialize(lock: ptr)
        return self.init(ptr: ptr)
    }

    deinit {
        _deinitialize(lock: self.ptr)
    }

    func lock() {
        _lock(lock: self.ptr)
    }

    func unlock() {
        _unlock(lock: self.ptr)
    }

    func withLock<R>(_ body: () throws -> R) rethrows -> R {
        self.lock()
        defer { self.unlock() }
        return try body()
    }
}

@inline(__always)
private func _initialize(lock ptr: AllocatedLock.Ptr) {
    #if canImport(Darwin)
    ptr.initialize(to: os_unfair_lock())
    #elseif canImport(Glibc)
    pthread_mutex_init(ptr, nil)
    #elseif canImport(WinSDK)
    InitializeSRWLock(ptr)
    #endif
}

@inline(__always)
private func _deinitialize(lock ptr: AllocatedLock.Ptr) {
    #if canImport(Glibc)
    pthread_mutex_destroy(ptr)
    #endif
    ptr.deinitialize(count: 1)
}

@inline(__always)
private func _lock(lock ptr: AllocatedLock.Ptr) {
    #if canImport(Darwin)
    os_unfair_lock_lock(ptr)
    #elseif canImport(Glibc)
    pthread_mutex_lock(ptr)
    #elseif canImport(WinSDK)
    AcquireSRWLockExclusive(ptr)
    #endif
}

@inline(__always)
private func _unlock(lock ptr: AllocatedLock.Ptr) {
    #if canImport(Darwin)
    os_unfair_lock_unlock(ptr)
    #elseif canImport(Glibc)
    pthread_mutex_unlock(ptr)
    #elseif canImport(WinSDK)
    ReleaseSRWLockExclusive(ptr)
    #endif
}
