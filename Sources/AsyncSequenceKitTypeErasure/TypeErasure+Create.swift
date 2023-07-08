//
//  TypeErasureFactory.swift
//
//
//  Created by LS Hung on 09/07/2023.
//

public enum AsyncSeq {
    public static func create<Element>(
        unfolding factory: @escaping () -> () async -> Element?
    ) -> NoThrowAsyncSeq<Element> {
        return .init(unfolding: factory)
    }

    public static func create<Element>(
        unfolding factory: @escaping () -> () async throws -> Element?
    ) -> DoThrowAsyncSeq<Element> {
        return .init(unfolding: factory)
    }
}
