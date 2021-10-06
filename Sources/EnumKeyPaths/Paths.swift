//
//  Paths.swift
//  enum-key-paths
//
//  Created by incetro on 01/01/2021.
//  Copyright © 2021 Incetro Inc. All rights reserved.
//

// MARK: - Basic

extension EnumKeyPath where Root == Value {

    /// The identity case path for `Root`: a case path
    /// that always successfully extracts a root value
    public static var `self`: EnumKeyPath {
        .init(
            embed: { $0 },
            extract: Optional.some
        )
    }
}

// MARK: - Void

extension EnumKeyPath where Root == Void {

    /// Returns a case path that always successfully extracts the given constant value
    ///
    /// - Parameter value: a constant value
    /// - Returns: a case path from `()` to `value`
    public static func constant(_ value: Value) -> EnumKeyPath {
        .init(
            embed: { _ in },
            extract: { .some(value) }
        )
    }
}

// MARK: - Never

extension EnumKeyPath where Value == Never {

    /// The never case path for `Root`: a case path that always
    /// fails to extract the a value of the uninhabited `Never` type
    public static var never: EnumKeyPath {
        func never<A>(_ never: Never) -> A {}
        return .init(
            embed: never,
            extract: { _ in nil }
        )
    }
}

// MARK: - RawRepresentable

extension EnumKeyPath where Value: RawRepresentable, Root == Value.RawValue {

    /// Returns a case path for `RawRepresentable` types: a case path
    /// that attempts to extract a value that can be represented by a raw value
    /// from a raw value
    public static var rawValue: EnumKeyPath {
        .init(
            embed: \.rawValue,
            extract: Value.init
        )
    }
}

// MARK: - LosslessStringConvertible

extension EnumKeyPath where Value: LosslessStringConvertible, Root == String {

    /// Returns a case path for `LosslessStringConvertible` types: a case path that attempts to
    /// extract a value that can be represented by a lossless string from a string
    public static var description: EnumKeyPath {
        .init(
            embed: \.description,
            extract: Value.init
        )
    }
}
