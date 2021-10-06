//
//  Operators.swift
//  enum-key-paths
//
//  Created by incetro on 01/01/2021.
//  Copyright © 2021 Incetro Inc. All rights reserved.
//

prefix operator /

/// Returns whether or not a root value matches a particular case path
///
///     let array = [Result<Int, Error>.success(1), .success(2), .failure(NSError()), .success(4)]
///     let prefixed = array.prefix(while: { /Result.success ~= $0 })
///     // [.success(1), .success(2)]
///
/// - Parameters:
///   - pattern: a case path
///   - value: a root value
/// - Returns: Whether or not a root value matches a particular case path
public func ~= <Root, Value>(keyPath: EnumKeyPath<Root, Value>, value: Root) -> Bool {
    keyPath.extract(from: value) != nil
}

/// Returns a case path for the given embed function
///
/// - Note: This operator is only intended to be used with enum cases that have no associated
///   values. Its behavior is otherwise undefined.
/// - Parameter embed: an embed function
/// - Returns: a case path
public prefix func / <Root, Value>(embed: @escaping (Value) -> Root) -> EnumKeyPath<Root, Value> {
    .case(embed)
}

/// Returns a void case path for a case with no associated value
///
/// - Note: This operator is only intended to be used with enum cases that have no associated
///   values. Its behavior is otherwise undefined.
/// - Parameter root: A case with no an associated value.
/// - Returns: A void case path.
public prefix func / <Root>(root: Root) -> EnumKeyPath<Root, Void> {
    .case(root)
}

/// Returns the identity case path for the given type. Enables `/MyType.self` syntax
///
/// - Parameter type: A type for which to return the identity case path.
/// - Returns: An identity case path.
public prefix func / <Root>(type: Root.Type) -> EnumKeyPath<Root, Root> {
    .self
}

/// Identifies and returns a given case path. Enables shorthand syntax on static case paths, _e.g._
/// `/.self`  instead of `.self`
///
/// - Parameter type: A type for which to return the identity case path.
/// - Returns: An identity case path.
public prefix func / <Root>(keyPath: EnumKeyPath<Root, Root>) -> EnumKeyPath<Root, Root> {
    .self
}

/// Returns a function that can attempt to extract associated values from the given enum case
/// initializer
///
/// Use this operator to create new transform functions to pass to higher-order methods like
/// `compactMap`:
///
///     [Result<Int, Error>.success(113), .failure(MyError()]
///       .compactMap(/Result.success)
///     // [113]
///
/// - Note: This operator is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
/// - Parameter case: An enum case initializer.
/// - Returns: A function that can attempt to extract associated values from an enum.
public prefix func / <Root, Value>(case: @escaping (Value) -> Root) -> (Root) -> Value? {
    extract(`case`)
}

/// Returns a void case path for a case with no associated value
///
/// - Note: This operator is only intended to be used with enum cases that have no associated
///   values. Its behavior is otherwise undefined.
/// - Parameter root: A case with no an associated value.
/// - Returns: A void case path.
public prefix func / <Root>(root: Root) -> (Root) -> Void? {
    (/root).extract
}

// MARK: - Appending

precedencegroup EnumKeyPathCompositionPrecedence {
    associativity: right
}

infix operator ..: EnumKeyPathCompositionPrecedence

extension EnumKeyPath {

    /// Returns a new case path created by appending the given case path to this one
    ///
    /// The operator version of `EnumKeyPath.appending(path:)`. Use this method to extend this case path
    /// to the value type of another case path.
    ///
    /// - Parameters:
    ///   - lhs: A case path from a root to a value.
    ///   - rhs: A case path from the first case path's value to some other appended value.
    /// - Returns: A new case path from the first case path's root to the second case path's value.
    public static func .. <AppendedValue>(
        lhs: EnumKeyPath,
        rhs: EnumKeyPath<Value, AppendedValue>
    ) -> EnumKeyPath<Root, AppendedValue> {
        lhs.appending(path: rhs)
    }

    /// Returns a new case path created by appending the given embed function
    ///
    /// - Parameters:
    ///   - lhs: A case path from a root to a value.
    ///   - rhs: An embed function from an appended value.
    /// - Returns: A new case path from the first case path's root to the second embed function's value.
    public static func .. <AppendedValue>(
        lhs: EnumKeyPath,
        rhs: @escaping (AppendedValue) -> Value
    ) -> EnumKeyPath<Root, AppendedValue> {
        lhs.appending(path: .case(rhs))
    }
}

/// Returns a new extract function by appending the given extract function with an embed function
///
/// Useful when composing extract functions together.
///
///     let array = [Result<Int?, Error>.success(.some(113)), .success(nil), .failure(MyError())]
///     let mapped = .compactMap(/Result.success..Optional.some)
///     // [113]
///
/// - Parameters:
///   - lhs: An extract function from a root to a value.
///   - rhs: An embed function from some other appended value to the extract function's value.
/// - Returns: A new extract function from the first extract function's root to the second embed
///   function's appended value.
public func .. <Root, Value, AppendedValue>(
    lhs: @escaping (Root) -> Value?,
    rhs: @escaping (AppendedValue) -> Value
) -> (Root) -> AppendedValue? {
    { lhs($0).flatMap(extract(rhs)) }
}
