import XCTest
@testable import Quark

class Base64Tests : XCTestCase {
    func testBase64() throws {
        let string = "foo bar"
        XCTAssertEqual(Base64.encode(""), "")
        XCTAssertEqual(Base64.encode("f"), "Zg==")
        XCTAssertEqual(Base64.encode("fo"), "Zm8=")
        XCTAssertEqual(Base64.encode("foo"), "Zm9v")
        XCTAssertEqual(Base64.encode(string), "Zm9vIGJhcg==")
        XCTAssertEqual(Base64.urlSafeEncode(string), "Zm9vIGJhcg")
        XCTAssertEqual(Base64.decode(""), Data(""))
        XCTAssertEqual(Base64.decode("Zg=="), Data("f"))
        XCTAssertEqual(Base64.decode("Zm8="), Data("fo"))
        XCTAssertEqual(Base64.decode("Zm9v"), Data("foo"))
        XCTAssertEqual(Base64.decode("Zm9vIGJhcg=="), Data("foo bar"))
    }
}

extension Base64Tests {
    static var allTests : [(String, (Base64Tests) -> () throws -> Void)] {
        return [
            ("testBase64", testBase64),
        ]
    }
}
