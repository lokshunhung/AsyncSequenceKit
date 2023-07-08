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

// MARK: - LockPrimitive

#if canImport(Darwin)
typealias LockPrimitive = os_unfair_lock
#elseif canImport(Glibc)
typealias LockPrimitive = pthread_mutex_t
#elseif canImport(WinSDK)
typealias LockPrimitive = SRWLOCK
#endif

internal typealias LockPtr = UnsafeMutablePointer<LockPrimitive>

// MARK: - AllocatedLock

internal final class AllocatedLock {
    private let ptr: LockPtr

    private init(ptr: LockPtr) {
        self.ptr = ptr
    }

    static func new() -> Self {
        let ptr = LockPtr.allocate(capacity: 1)
        _initialize(lock: ptr)
        return self.init(ptr: ptr)
    }

    deinit {
        _deinitialize(lock: self.ptr)
        self.ptr.deinitialize(count: 1)
    }

    func lock() {
        _lock(lock: self.ptr)
    }

    func unlock() {
        _unlock(lock: self.ptr)
    }

    @inline(__always) @usableFromInline
    func withLock<R>(_ body: () throws -> R) rethrows -> R {
        self.lock()
        defer { self.unlock() }
        return try body()
    }
}

// MARK: - Lockable<State>

internal struct Lockable<State> {
    private typealias StatePtr = UnsafeMutablePointer<State>
    private typealias Buffer = ManagedBuffer<State, LockPrimitive>

    private let buffer: Buffer

    init(_ state: State) {
        self.buffer = RefCountBuffer.create(minimumCapacity: 1, makingHeaderWith: { (buffer: Buffer) in
            buffer.withUnsafeMutablePointerToElements { (lock: LockPtr) in
                _initialize(lock: lock)
            }
            return state
        })
    }

    func withLock<R>(_ body: (inout State) throws -> R) rethrows -> R {
        return try self.buffer.withUnsafeMutablePointers { (state: StatePtr, lock: LockPtr) in
            _lock(lock: lock)
            defer { _unlock(lock: lock) }
            return try body(&state.pointee)
        }
    }

    private final class RefCountBuffer: ManagedBuffer<State, LockPrimitive> {
        deinit { // lifecycle managed with reference counting
            self.withUnsafeMutablePointerToElements { (lock: LockPtr) in
                _deinitialize(lock: lock)
            }
        }
    }
}

// MARK: - lock pointer implementation from apple/swift-async-algorithm

@inline(__always)
private func _initialize(lock ptr: LockPtr) {
    #if canImport(Darwin)
    ptr.initialize(to: os_unfair_lock())
    #elseif canImport(Glibc)
    pthread_mutex_init(ptr, nil)
    #elseif canImport(WinSDK)
    InitializeSRWLock(ptr)
    #endif
}

@inline(__always)
private func _deinitialize(lock ptr: LockPtr) {
    #if canImport(Glibc)
    pthread_mutex_destroy(ptr)
    #endif
}

@inline(__always)
private func _lock(lock ptr: LockPtr) {
    #if canImport(Darwin)
    os_unfair_lock_lock(ptr)
    #elseif canImport(Glibc)
    pthread_mutex_lock(ptr)
    #elseif canImport(WinSDK)
    AcquireSRWLockExclusive(ptr)
    #endif
}

@inline(__always)
private func _unlock(lock ptr: LockPtr) {
    #if canImport(Darwin)
    os_unfair_lock_unlock(ptr)
    #elseif canImport(Glibc)
    pthread_mutex_unlock(ptr)
    #elseif canImport(WinSDK)
    ReleaseSRWLockExclusive(ptr)
    #endif
}
