import XCTest
@testable import Quark

class JSONTests : XCTestCase {
    func testJSON() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer(ordering: true)

        let data: C7.Data = "{\"array\":[true,-4.2,-1969,null,\"hey! 😊\"],\"boolean\":false,\"dictionaryOfEmptyStuff\":{\"emptyArray\":[],\"emptyDictionary\":{},\"emptyString\":\"\"},\"double\":4.2,\"integer\":1969,\"null\":null,\"string\":\"yoo! 😎\"}"

        let map: Map = [
            "array": [
                true,
                -4.2,
                -1969,
                nil,
                "hey! 😊",
            ],
            "boolean": false,
            "dictionaryOfEmptyStuff": [
                "emptyArray": [],
                "emptyDictionary": [:],
                "emptyString": ""
            ],
            "double": 4.2,
            "integer": 1969,
            "null": nil,
            "string": "yoo! 😎",
        ]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssertEqual(serialized, data)
    }

    func testNumberWithExponent() throws {
        let parser = JSONMapParser()
        let data: C7.Data = "[1E3]"
        let map: Map = [1_000]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)
    }

    func testNumberWithNegativeExponent() throws {
        let parser = JSONMapParser()
        let data: C7.Data = "[1E-3]"
        let map: Map = [1E-3]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)
    }

    func testWhitespaces() throws {
        let parser = JSONMapParser()
        let data: C7.Data = "[ \n\t\r1 \n\t\r]"
        let map: Map = [1]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)
    }

    func testNumberStartingWithZero() throws {
        let parser = JSONMapParser()
        let data: C7.Data = "[0001000]"
        let map: Map = [1000]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)
    }

    func testEscapedSlash() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer()

        let data: C7.Data = "{\"foo\":\"\\\"\"}"

        let map: Map = [
            "foo": "\""
        ]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssertEqual(serialized, data)
    }

    func testSmallDictionary() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer()

        let data: C7.Data = "{\"foo\":\"bar\",\"fuu\":\"baz\"}"

        let map: Map = [
            "foo": "bar",
            "fuu": "baz",
        ]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssert(serialized == data || serialized == "{\"fuu\":\"baz\",\"foo\":\"bar\"}")
    }

    func testInvalidMap() throws {
        let serializer = JSONMapSerializer()

        let map: Map = [
            "foo": .data("yo!")
        ]

        var called = false

        do {
            _ = try serializer.serialize(map)
            XCTFail("Should've throwed error")
        } catch {
            called = true
        }
        
        XCTAssert(called)
    }

    func testEscapedEmoji() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer()

        let data: C7.Data = "[\"\\ud83d\\ude0e\"]"
        let map: Map = ["😎"]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssertEqual(serialized, "[\"😎\"]")
    }

    func testEscapedSymbol() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer()

        let data: C7.Data = "[\"\\u221e\"]"
        let map: Map = ["∞"]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssertEqual(serialized, "[\"∞\"]")
    }

    func testFailures() throws {
        let parser = JSONMapParser()
        var data: C7.Data

        data = ""
        XCTAssertThrowsError(try parser.parse(data))
        data = "nudes"
        XCTAssertThrowsError(try parser.parse(data))
        data = "bar"
        XCTAssertThrowsError(try parser.parse(data))
        data = "{}foo"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\""
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\u"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud8"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83d"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83d\\"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83d\\u"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83d\\ud"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83d\\ude"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83d\\ude0"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83d\\ude0e"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\ud83d\\u0000"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\u0000\\u0000"
        XCTAssertThrowsError(try parser.parse(data))
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\u0000\\ude0e"
        XCTAssertThrowsError(try parser.parse(data))
        data = "\"\\uGGGG\\uGGGG"
        XCTAssertThrowsError(try parser.parse(data))
        data = "0F"
        XCTAssertThrowsError(try parser.parse(data))
        data = "-0F"
        XCTAssertThrowsError(try parser.parse(data))
        data = "-09F"
        XCTAssertThrowsError(try parser.parse(data))
        data = "999999999999999998"
        XCTAssertThrowsError(try parser.parse(data))
        data = "999999999999999999"
        XCTAssertThrowsError(try parser.parse(data))
        data = "9999999999999999990"
        XCTAssertThrowsError(try parser.parse(data))
        data = "9999999999999999999"
        XCTAssertThrowsError(try parser.parse(data))
        data = "9."
        XCTAssertThrowsError(try parser.parse(data))
        data = "0E"
        XCTAssertThrowsError(try parser.parse(data))
        data = "{\"foo\"}"
        XCTAssertThrowsError(try parser.parse(data))
        data = "{\"foo\":\"bar\"\"fuu\"}"
        XCTAssertThrowsError(try parser.parse(data))
        data = "{1969}"
        XCTAssertThrowsError(try parser.parse(data))
        data = "[\"foo\"\"bar\"]"
        XCTAssertThrowsError(try parser.parse(data))
    }

    func testDescription() throws {
        XCTAssertEqual(String(describing: JSONMapParseError.unexpectedTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "UnexpectedTokenError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.insufficientTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InsufficientTokenError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.extraTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "ExtraTokenError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.nonStringKeyError(reason: "foo", lineNumber: 0, columnNumber: 0)), "NonStringKeyError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.invalidStringError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InvalidStringError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.invalidNumberError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InvalidNumberError[Line: 0, Column: 0]: foo")
    }
}

extension JSONTests {
    static var allTests: [(String, (JSONTests) -> () throws -> Void)] {
        return [
            ("testJSON", testJSON),
            ("testJSON", testNumberWithExponent),
            ("testJSON", testNumberWithNegativeExponent),
            ("testJSON", testWhitespaces),
            ("testJSON", testNumberStartingWithZero),
            ("testJSON", testEscapedSlash),
            ("testJSON", testSmallDictionary),
            ("testJSON", testInvalidMap),
            ("testJSON", testEscapedEmoji),
            ("testEscapedSymbol", testEscapedSymbol),
            ("testJSON", testFailures),
            ("testJSON", testDescription),
        ]
    }
}
