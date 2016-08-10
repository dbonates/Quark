import XCTest
@testable import Quark

enum TestRouterError : Error {
    case error
}

struct EmptyRouter : CustomRouter {}

struct TestRouter : CustomRouter {
    func custom(routes: Routes) {
        routes.get("/") { _ in
            return Response()
        }
    }
}

struct CustomRecoverRouter : CustomRouter {
    func custom(routes: Routes) {
        routes.get("/") { _ in
            throw TestRouterError.error
        }
    }

    func recover(error: Error) throws -> Response {
        return Response()
    }
}

class RouterTests : XCTestCase {
    func testEmptyRouter() throws {
        let router = EmptyRouter()
        let request = Request()
        let response = try router.router.respond(to: request)
        XCTAssertEqual(response.status, .notFound)
    }

    func testCustomRouter() throws {
        let router = TestRouter()
        let request = Request()
        let response = try router.router.respond(to: request)
        XCTAssertEqual(response.status, .ok)
    }

    func testCustomRecoverRouter() throws {
        let router = CustomRecoverRouter()
        let request = Request()
        let response = try router.router.respond(to: request)
        XCTAssertEqual(response.status, .ok)
    }
}

extension RouterTests {
    static var allTests: [(String, (RouterTests) -> () throws -> Void)] {
        return [
            ("testEmptyRouter", testEmptyRouter),
            ("testCustomRouter", testCustomRouter),
            ("testCustomRecoverRouter", testCustomRecoverRouter),
        ]
    }
}
