import XCTest
@testable import Quark

extension Server {
    init(host: Quark.Host, responder: Responder) throws {
        self.tcpHost = host
        self.host = "127.0.0.1"
        self.port = 8080
        self.bufferSize = 2048
        self.middleware = []
        self.responder = responder
        self.failure = Server.log(error:)
    }
}

class TestHost : Quark.Host {
    let data: Quark.Data

    init(data: Quark.Data) {
        self.data = data
    }

    func accept(deadline: Double) throws -> Quark.Stream {
        return Drain(buffer: data)
    }
}

enum CustomError :  Error {
    case error
}

class ServerTests : XCTestCase {
    func testServer() throws {
        var called = false

        let responder = BasicResponder { request in
            called = true
            XCTAssertEqual(request.method, .get)
            return Response()
        }

        let server = try Server(
            host: TestHost(data: "GET / HTTP/1.1\r\n\r\n"),
            responder: responder
        )
        let stream = try server.tcpHost.accept()
        server.printHeader()
        try server.process(stream: stream)
        XCTAssert(String(describing: (stream as! Drain).data).contains(substring: "OK"))
        XCTAssert(called)
    }

    func testServerRecover() throws {
        var called = false
        var stream: Quark.Stream = Drain()

        let responder = BasicResponder { request in
            called = true
            (stream as! Drain).closed = false
            XCTAssertEqual(request.method, .get)
            throw HTTPError.badRequest
        }

        let server = try Server(
            host: TestHost(data: "GET / HTTP/1.1\r\n\r\n"),
            responder: responder
        )
        stream = try server.tcpHost.accept()
        try server.process(stream: stream)
        XCTAssert(String(describing: (stream as! Drain).data).contains(substring: "Bad Request"))
        XCTAssert(called)
    }

    func testServerNoRecover() throws {
        var called = false
        var stream: Quark.Stream = Drain()

        let responder = BasicResponder { request in
            called = true
            (stream as! Drain).closed = false
            XCTAssertEqual(request.method, .get)
            throw CustomError.error
        }

        let server = try Server(
            host: TestHost(data: "GET / HTTP/1.1\r\n\r\n"),
            responder: responder
        )
        stream = try server.tcpHost.accept()
        XCTAssertThrowsError(try server.process(stream: stream))
        XCTAssert(String(describing: (stream as! Drain).data).contains(substring: "Internal Server Error"))
        XCTAssert(called)
    }

    func testBrokenPipe() throws {
        var called = false
        var stream: Quark.Stream = Drain()

        let responder = BasicResponder { request in
            called = true
            (stream as! Drain).closed = false
            XCTAssertEqual(request.method, .get)
            throw SystemError.brokenPipe
        }

        let request: Quark.Data = "GET / HTTP/1.1\r\n\r\n"

        let server = try Server(
            host: TestHost(data: request),
            responder: responder
        )
        stream = try server.tcpHost.accept()
        try server.process(stream: stream)
        XCTAssertEqual((stream as! Drain).data, request)
        XCTAssert(called)
    }

    func testNotKeepAlive() throws {
        var called = false
        var stream: Quark.Stream = Drain()

        let responder = BasicResponder { request in
            called = true
            (stream as! Drain).closed = false
            XCTAssertEqual(request.method, .get)
            return Response()
        }

        let request: Quark.Data = "GET / HTTP/1.1\r\nConnection: close\r\n\r\n"

        let server = try Server(
            host: TestHost(data: request),
            responder: responder
        )
        stream = try server.tcpHost.accept()
        try server.process(stream: stream)
        XCTAssert(String(describing: (stream as! Drain).data).contains(substring: "OK"))
        XCTAssertTrue(stream.closed)
        XCTAssert(called)
    }

    func testUpgradeConnection() throws {
        var called = false
        var upgradeCalled = false
        var stream: Quark.Stream = Drain()

        let responder = BasicResponder { request in
            called = true
            (stream as! Drain).closed = false
            XCTAssertEqual(request.method, .get)
            var response = Response()
            response.upgradeConnection { request, stream in
                XCTAssertEqual(request.method, .get)
                XCTAssert(String(describing: (stream as! Drain).data).contains(substring: "OK"))
                XCTAssertFalse(stream.closed)
                upgradeCalled = true
            }
            return response
        }

        let request: Quark.Data = "GET / HTTP/1.1\r\nConnection: close\r\n\r\n"

        let server = try Server(
            host: TestHost(data: request),
            responder: responder
        )
        stream = try server.tcpHost.accept()
        try server.process(stream: stream)
        XCTAssert(String(describing: (stream as! Drain).data).contains(substring: "OK"))
        XCTAssertTrue(stream.closed)
        XCTAssert(called)
        XCTAssert(upgradeCalled)
    }

    func testLogError() {
        Server.log(error: HTTPError.badRequest)
    }
}

extension ServerTests {
    static var allTests : [(String, (ServerTests) -> () throws -> Void)] {
        return [
            ("testServer", testServer),
            ("testServerRecover", testServerRecover),
            ("testServerNoRecover", testServerNoRecover),
            ("testBrokenPipe", testBrokenPipe),
            ("testNotKeepAlive", testNotKeepAlive),
            ("testUpgradeConnection", testUpgradeConnection),
            ("testLogError", testLogError),
        ]
    }
}
