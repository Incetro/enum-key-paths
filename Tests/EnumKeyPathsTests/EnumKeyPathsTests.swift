import EnumKeyPaths
import XCTest

// MARK: - EnumKeyPathsTests

final class EnumKeyPathsTests: XCTestCase {

    func testEmbed() {

        /// given

        enum Enumeration: Equatable {
            case verse(Int)
        }

        /// when & then

        XCTAssertEqual(.verse(113), (/Enumeration.verse).embed(113))
        XCTAssertEqual(.verse(113), (/Enumeration.self).embed(Enumeration.verse(113)))
    }

    func testNestedEmbed() {

        /// given

        enum Enumeration: Equatable {
            case verse(Axiom)
        }

        enum Axiom: Equatable {
            case verse(Int)
        }

        /// when & then

        XCTAssertEqual(.verse(.verse(113)), (/Enumeration.verse..Axiom.verse).embed(113))
    }

    func testVoidEnumKeyPath() {

        /// given

        enum Enumeration: Equatable {
            case mua
        }

        /// when & then

        XCTAssertEqual(.mua, (/Enumeration.mua).embed(()))
    }

    func testEnumKeyPaths() {

        XCTAssertEqual(
            .some("Hello"),
            (/String?.some)
                .extract(from: "Hello")
        )

        XCTAssertNil(
            (/String?.some)
                .extract(from: .none)
        )

        XCTAssertEqual(
            .some("Hello"),
            (/Result<String, Error>.success)
                .extract(from: .success("Hello"))
        )

        XCTAssertNil(
            (/Result<String, Error>.failure)
                .extract(from: .success("Hello"))
        )

        struct MyError: Equatable, Error {
        }

        XCTAssertEqual(
            .some(MyError()),
            (/Result<String, Error>.failure)
                .extract(from: .failure(MyError()))
        )

        XCTAssertNil(
            (/Result<String, Error>.success)
                .extract(from: .failure(MyError()))
        )
    }

    func testIdentity() {

        XCTAssertEqual(
            .some(113),
            (/Int.self)
                .extract(from: 113)
        )

        XCTAssertEqual(
            .some(113),
            (/.self)
                .extract(from: 113)
        )

        XCTAssertEqual(
            .some(113),
            (/{ $0 })
                .extract(from: 113)
        )
    }

    func testLabeledCases() {

        /// given

        enum Enumeration: Equatable {
            case verse(some: Int)
            case verse(none: Int)
        }

        XCTAssertEqual(
            .some(113),
            (/Enumeration.verse(some:))
                .extract(from: .verse(some: 113))
        )
        XCTAssertNil(
            (/Enumeration.verse(some:))
                .extract(from: .verse(none: 113))
        )

        XCTAssertEqual(
            .some(113),
            EnumKeyPath
                .case { Enumeration.verse(none: $0) }
                .extract(from: .verse(none: 113))
        )
        XCTAssertNil(
            EnumKeyPath
                .case { Enumeration.verse(none: $0) }
                .extract(from: .verse(some: 113))
        )
    }

    func testMultiCases() {

        /// given

        enum Enumeration {
            case verse(Int, String)
        }

        guard let boom = (/Enumeration.verse).extract(from: .verse(113, "INCETRO")) else {
            XCTFail()
            return
        }

        /// when & then

        XCTAssertEqual(113, boom.0)
        XCTAssertEqual("INCETRO", boom.1)
    }

    func testMultiLabeledCases() {

        /// given

        enum Enumeration {
            case verse(demure: Int, eternity: String)
        }

        guard let demureEternity = EnumKeyPath<Enumeration, (demure: Int, eternity: String)>
                .case(Enumeration.verse)
                .extract(
                    from: .verse(demure: 113, eternity: "INCETRO")
                )
        else {
            XCTFail()
            return
        }

        /// when & then

        XCTAssertEqual(113, demureEternity.demure)
        XCTAssertEqual("INCETRO", demureEternity.eternity)
    }

    func testSingleValueExtractionFromMultiple() {

        /// given

        enum Enumeration {
            case verse(demure: Int, eternity: String)
        }

        /// when & then

        XCTAssertEqual(
            .some(113),
            extract(
                case: { Enumeration.verse(demure: $0, eternity: "INCETRO") },
                from: .verse(demure: 113, eternity: "INCETRO")
            )
        )
    }

    func testMultiMixedCases() {

        /// given

        enum Enumeration {
            case verse(Int, eternity: String)
        }

        guard
            let demureEternity = (/Enumeration.verse)
                .extract(from: .verse(113, eternity: "INCETRO"))
        else {
            XCTFail()
            return
        }

        /// when & then

        XCTAssertEqual(113, demureEternity.0)
        XCTAssertEqual("INCETRO", demureEternity.1)
    }

    func testNestedReflection() {

        /// given

        enum Enumeration {
            case verse(Axiom)
        }

        enum Axiom {
            case sea(Int)
        }

        /// when & then

        XCTAssertEqual(
            113,
            extract(
                case: { Enumeration.verse(.sea($0)) },
                from: .verse(.sea(113))
            )
        )
    }

    func testNestedZeroMemoryLayout() {

        /// given

        enum Enumeration {
            case verse(Axiom)
        }

        enum Axiom: Equatable {
            case sea
        }

        /// when & then

        XCTAssertEqual(
            .sea,
            (/Enumeration.verse)
                .extract(from: .verse(.sea))
        )
    }

    func testNestedUninhabitedTypes() {

        /// given

        enum Uninhabited {}

        enum Enumeration {
            case mua
            case verse(Uninhabited)
            case sea(Never)
        }

        /// when & then

        XCTAssertNil(
            (/Enumeration.verse)
                .extract(from: Enumeration.mua)
        )

        XCTAssertNil(
            (/Enumeration.sea)
                .extract(from: Enumeration.mua)
        )
    }

    func testEnumsWithoutAssociatedValues() {

        /// given

        enum Enumeration: Equatable {
            case verse
            case sea
        }

        /// when & then

        XCTAssertNotNil(
            (/Enumeration.verse)
                .extract(from: .verse)
        )

        XCTAssertNil(
            (/Enumeration.verse)
                .extract(from: .sea)
        )

        XCTAssertNotNil(
            (/Enumeration.sea)
                .extract(from: .sea)
        )

        XCTAssertNil(
            (/Enumeration.sea)
                .extract(from: .verse)
        )

        XCTAssertNotNil(
            extract(
                case: { Enumeration.verse },
                from: .verse
            )
        )

        XCTAssertNil(
            extract(
                case: { Enumeration.verse },
                from: .sea
            )
        )

        XCTAssertNotNil(
            extract(
                case: { Enumeration.sea },
                from: .sea
            )
        )

        XCTAssertNil(
            extract(
                case: { Enumeration.sea },
                from: .verse
            )
        )
    }

    func testEnumsWithClosures() {

        /// given

        enum Enumeration {
            case verse(() -> Void)
        }

        /// when

        var didRun = false
        guard let verse = (/Enumeration.verse).extract(from: .verse { didRun = true }) else {
            XCTFail()
            return
        }
        verse()

        /// then

        XCTAssertTrue(didRun)
    }

    func testRecursive() {

        /// given

        indirect enum Enumeration {
            case mua(Enumeration)
            case verse(Int)
        }

        /// when & then

        XCTAssertEqual(
            .some(113),
            extract(
                case: { Enumeration.mua(.mua(.mua(.verse($0)))) },
                from: .mua(.mua(.mua(.verse(113))))
            )
        )
        XCTAssertNil(
            extract(
                case: { Enumeration.mua(.mua(.mua(.verse($0)))) },
                from: .mua(.mua(.verse(113)))
            )
        )
    }

    func testExtract() {

        /// given & when & then

        struct MyError: Error {}

        XCTAssertEqual(
            [1],
            [
                Result.success(1),
                .success(nil),
                .failure(MyError())
            ].compactMap(/Result.success..Optional.some)
        )

        XCTAssertEqual(
            [1],
            [
                Result.success(1),
                .success(nil),
                .failure(MyError())
            ].compactMap(/{ .success(.some($0)) })
        )

        enum Authentication {
            case authenticated(token: String)
            case unauthenticated
        }

        XCTAssertEqual(
            ["deadbeef"],
            [
                Authentication.authenticated(token: "deadbeef"),
                .unauthenticated
            ].compactMap(/Authentication.authenticated)
        )

        XCTAssertEqual(
            1,
            [
                Authentication.authenticated(token: "deadbeef"),
                .unauthenticated
            ].compactMap(/Authentication.unauthenticated).count
        )
    }

    func testAppending() {
        XCTAssertEqual(
            .some(113),
            (/Result<Int?, Error>.success .. /Int?.some)
                .extract(from: .success(.some(113)))
        )
    }

    func testExample() {
        XCTAssertEqual("INCETRO", extract(case: Result<String, Error>.success, from: .success("INCETRO")))
        XCTAssertNil(extract(case: Result<String, Error>.failure, from: .success("INCETRO")))
        XCTAssertEqual(113, (/Int??.some .. Int?.some).extract(from: Optional(Optional(113))))
    }

    func testConstantEnumKeyPath() {
        XCTAssertEqual(.some(113), EnumKeyPath.constant(113).extract(from: ()))
        XCTAssertNotNil(EnumKeyPath.constant(113).embed(113))
    }

    func testNeverEnumKeyPath() {
        XCTAssertNil(EnumKeyPath.never.extract(from: 113))
    }

    func testRawValuePath() {

        /// given

        enum Enumeration: String { case verse, sea }

        /// when & then

        XCTAssertEqual(.some(.verse), EnumKeyPath<String, Enumeration>.rawValue.extract(from: "verse"))
        XCTAssertEqual("sea", EnumKeyPath.rawValue.embed(Enumeration.sea))
    }

    func testDescriptionPath() {
        XCTAssertEqual(.some(113), EnumKeyPath.description.extract(from: "113"))
        XCTAssertEqual("113", EnumKeyPath.description.embed(113))
    }

    func testA() {

        /// given

        enum EnumWithLabeledCase {
            case labeled(label: Int, otherLabel: Int)
            case labeled(Int, Int)
        }

        /// when & then

        XCTAssertNil((/EnumWithLabeledCase.labeled(label:otherLabel:)).extract(from: .labeled(2, 2)))
        XCTAssertNotNil(
            (/EnumWithLabeledCase.labeled(label:otherLabel:)).extract(
                from: .labeled(label: 2, otherLabel: 2)))
    }

    func testPatternMatching() {

        /// given

        let results = [
            Result<Int, NSError>.success(1),
            .success(2),
            .failure(NSError(domain: "co.incetro", code: -1)),
            .success(3),
        ]

        /// when & then

        XCTAssertEqual(
            Array(results.lazy.prefix(while: { /Result.success ~= $0 }).compactMap(/Result.success)),
            [1, 2]
        )

        switch results[0] {
        case /Result.success:
            break
        default:
            XCTFail()
        }
    }
}
