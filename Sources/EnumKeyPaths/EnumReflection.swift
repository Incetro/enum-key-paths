//
//  EnumReflection.swift
//  enum-key-paths
//
//  Created by incetro on 01/01/2021.
//  Copyright © 2021 Incetro Inc. All rights reserved.
//

import func Foundation.memcmp

// MARK: - Case

extension EnumKeyPath {

    /// Returns a case path that extracts values associated with a given enum case initializer
    ///
    /// - Note: This function is only intended to be used with enum case initializers. Its behavior is
    ///   otherwise undefined.
    ///
    /// - Parameter embed: an enum case initializer
    /// - Returns: a case path that extracts associated values from enum cases
    public static func `case`(_ embed: @escaping (Value) -> Root) -> EnumKeyPath {
        .init(
            embed: embed,
            extract: { EnumKeyPaths.extract(case: embed, from: $0) }
        )
    }
}

extension EnumKeyPath where Value == Void {

    /// Returns a case path that successfully extracts `()` from a given enum case with no associated
    /// values
    ///
    /// - Note: This function is only intended to be used with enum cases that have no associated
    ///   values. Its behavior is otherwise undefined.
    ///
    /// - Parameter value: an enum case with no associated values
    /// - Returns: a case path that extracts `()` if the case matches, otherwise `nil`
    public static func `case`(_ value: Root) -> EnumKeyPath {
        EnumKeyPath(
            embed: { value },
            extract: { "\($0)" == "\(value)" ? () : nil }
        )
    }
}

// MARK: - Extract

/// Attempts to extract values associated with a given enum case initializer from a given root enum
///
///     extract(case: Result<Int, Error>.success, from: .success(113))
///     // 113
///     extract(case: Result<Int, Error>.success, from: .failure(MyError())
///     // nil
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
///
/// - Parameters:
///   - embed: an enum case initializer
///   - root: a root enum value
/// - Returns: values iff they can be extracted from the given enum case initializer and root enum,
///   otherwise `nil`
public func extract<Root, Value>(case embed: (Value) -> Root, from root: Root) -> Value? {

    func extractHelp(from root: Root) -> ([String?], Value)? {

        if let value = root as? Value {
            var otherRoot = embed(value)
            var root = root
            if memcmp(&root, &otherRoot, MemoryLayout<Root>.size) == 0 {
                return ([], value)
            }
        }

        var path: [String?] = []
        var any: Any = root

        while let child = Mirror(reflecting: any).children.first, let label = child.label {
            path.append(label)
            path.append(String(describing: type(of: child.value)))
            if let child = child.value as? Value {
                return (path, child)
            }
            any = child.value
        }

        if MemoryLayout<Value>.size == 0, !isUninhabitedEnum(Value.self) {
            return (["\(root)"], unsafeBitCast((), to: Value.self))
        }

        return nil
    }

    if let (rootPath, child) = extractHelp(from: root), let (otherPath, _) = extractHelp(from: embed(child)), rootPath == otherPath {
        return child
    }

    return nil
}

/// Returns a function that can attempt to extract associated values from the given enum case
/// initializer
///
/// Use this function to create new transform functions to pass to higher-order methods like
/// `compactMap`:
///
///     [Result<Int, Error>.success(113), .failure(MyError()]
///       .compactMap(extract(Result.success))
///     // [113]
///
/// - Note: This function is only intended to be used with enum case initializers. Its behavior is
///   otherwise undefined.
///
/// - Parameter case: an enum case initializer
/// - Returns: a function that can attempt to extract associated values from an enum
public func extract<Root, Value>(_ case: @escaping (Value) -> Root) -> (Root) -> (Value?) {
    { root in extract(case: `case`, from: root) }
}

// MARK: - EnumMetadata

private struct EnumMetadata {

    // MARK: - Properties

    /// Enum kind value
    let kind: Int

    /// Enum type descriptor
    let typeDescriptor: UnsafePointer<EnumTypeDescriptor>
}

// MARK: - EnumTypeDescriptor

private struct EnumTypeDescriptor {

    // MARK: - Properties

    /// These fields are not modeled because we don't need them.
    /// They are the type descriptor flags and various pointer offsets
    let flags, p1, p2, p3, p4: Int32

    let numPayloadCasesAndPayloadSizeOffset: Int32
    let numEmptyCases: Int32

    var numPayloadCases: Int32 {
        numPayloadCasesAndPayloadSizeOffset & 0xFFFFFF
    }
}

// MARK: - Other

private func isUninhabitedEnum(_ type: Any.Type) -> Bool {
    let metadataPtr = unsafeBitCast(type, to: UnsafeRawPointer.self)
    let metadataKind = metadataPtr.load(as: Int.self)
    let isEnum = metadataKind == 0x201
    guard isEnum else { return false }
    let enumMetadata = metadataPtr.load(as: EnumMetadata.self)
    let enumTypeDescriptor = enumMetadata.typeDescriptor.pointee
    let numCases = enumTypeDescriptor.numPayloadCases + enumTypeDescriptor.numEmptyCases
    return numCases == 0
}
