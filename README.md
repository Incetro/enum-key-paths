![](enum-key-paths.png)

# 🔌 Enum key paths

With the package you can use [key paths](https://developer.apple.com/documentation/swift/swift_standard_library/key-path_expressions) with enums

``` swift
import EnumKeyPaths

// MARK: - Authentication

enum Authentication {
    case authenticated(accessToken: String)
    case unauthenticated
}

/Authentication.authenticated // EnumKeyPath<Authentication, String>

user[keyPath: \User.id] = 113
user[keyPath: \User.id] // 113

let authentication = (/Authentication.authenticated).embed("access")
(/Authentication.authenticated).extract(from: authentication) // Optional("access")
```

Extraction can fail and return `nil` because the cases may not match up.

``` swift
(/Authentication.authenticated).extract(from: .unauthenticated) // nil
```

Swift key paths use dot-syntax to dive deeper into a structure, enum key paths use a double-dot syntax:

``` swift
\Table.user.name
// WritableKeyPath<Table, String>

/Result<Authentication, Error>..Authentication.authenticated
// EnumKeyPath<Result<Authentication, Error>, String>
```

Enum key paths provide an "[identity](https://github.com/apple/swift-evolution/blob/master/proposals/0227-identity-keypath.md)" path, which is useful for interacting with APIs that use key paths but you want to work with entire structure.

``` swift
\User.self           // WritableKeyPath<User, User>
/Authentication.self // EnumKeyPath<Authentication, Authentication>
```

Key paths are created for every property, even computed ones, so what is the equivalent for enum key paths? "computed" enum key paths can be created by providing custom `embed` and `extract` functions:

``` swift
EnumKeyPath<Authentication, String>(
    embed: { token in
        Authentication.authenticated(token: encrypt(token))
    },
    extract: { authentication in
        guard
            case let .authenticated(encryptedToken) = authentication,
            let decryptedToken = decrypt(token)
            else { return nil }
        return decryptedToken
    }
)
```

Since Swift 5.2, key path expressions can be passed directly to methods like `map`. The same is true of enum key path expressions, which can be passed to methods like `compactMap`:

``` swift
users.map(\User.name)
authentications.compactMap(/Authentication.authenticated)
```

## Ergonomic associated value access

EnumKeyPaths uses Swift reflection to automatically and extract associated values from _any_ enum in a single, short expression. This helpful utility is made available as a public module function that can be used in your own libraries and apps:

``` swift
extract(case: Authentication.authenticated, from: .authenticated("token"))
// Optional("token")
```

## Enum key paths operators

``` swift
// With operators:
/Authentication.authenticated
// Without:
EnumKeyPath.case(Authentication.authenticated)

// With operators:
authentications.compactMap(/Authentication.authenticated)
// Without:
authentications.compactMap(extract(Authentication.authenticated))

// With operators:
/Result<Authentication, Error>.success..Authentication.authenticated
// Without:
EnumKeyPath.case(Result<Authentication, Error>.success)
  .appending(path: .case(Authentication.authenticated))

// With operators:
/Authentication.self
// Without operators:
EnumKeyPath<Authentication, Authentication>.self
```

## Installation

You can add EnumKeyPaths to an Xcode project by adding it as a package dependency:
`https://github.com/Incetro/enum-key-paths`

If you want to use EnumKeyPaths in a [SwiftPM](https://swift.org/package-manager/) project, it's as simple as adding a `dependencies` clause to your `Package.swift`:

``` swift
dependencies: [
    .package(url: "https://github.com/Incetro/enum-key-paths.git", from: "0.0.1")
]
```

## License

All modules are released under the MIT license. See [LICENSE](LICENSE) for details.
