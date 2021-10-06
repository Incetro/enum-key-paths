//
//  EnumKeyPath.swift
//  enum-key-paths
//
//  Created by incetro on 01/01/2021.
//  Copyright © 2021 Incetro Inc. All rights reserved.
//

// MARK: - EnumKeyPath

/// A path that supports embedding a value in a root
/// and attempting to extract a root's embedded value
///
/// This type defines key path-like semantics for enum cases
public struct EnumKeyPath<Root, Value> {

    // MARK: - Properties

    /// A closure that embeds a value in a root
    private let _embed: (Value) -> Root

    /// A closure that can extract a value from a root
    private let _extract: (Root) -> Value?

    // MARK: - Initializers

    /// Default initializer.
    /// Creates a case path with a pair of closures.
    ///
    /// - Parameters:
    ///   - embed: a closure that embeds a value in a root
    ///   - extract: a closure that can extract a value from a root
    public init(
        embed: @escaping (Value) -> Root,
        extract: @escaping (Root) -> Value?
    ) {
        self._embed = embed
        self._extract = extract
    }

    // MARK: - Public

    /// Returns a root by embedding a value
    ///
    /// - Parameter value: a value to embed
    /// - Returns: a root that embeds `value`
    public func embed(_ value: Value) -> Root {
        _embed(value)
    }

    /// Extracts a value from a root
    ///
    /// - Parameter root: a root to extract from
    /// - Returns: a value that extracted from the given root (`nil` if it can't be extracted)
    public func extract(from root: Root) -> Value? {
        _extract(root)
    }

    /// Append the given case path to current
    /// You should use this method to extend current case path to the value type of another case path
    ///
    /// - Parameter path: the case path to append
    /// - Returns: a case path from the current root to the value type of `path`
    public func appending<AppendedValue>(path: EnumKeyPath<Value, AppendedValue>) -> EnumKeyPath<Root, AppendedValue> {
        EnumKeyPath<Root, AppendedValue>(
            embed: { embed(path.embed($0)) },
            extract: { extract(from: $0).flatMap(path.extract) }
        )
    }
}
