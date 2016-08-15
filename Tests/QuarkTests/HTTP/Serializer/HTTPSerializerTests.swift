import XCTest
@testable import Quark

class HTTPSerializerTests: XCTestCase {
    func testResponseSerializeBuffer() throws {
        let outStream = Drain()
        let serializer = ResponseSerializer(stream: outStream)
        var response = Response(body: "foo")
        response.cookies = [AttributedCookie(name: "foo", value: "bar")]

        try serializer.serialize(response)
        XCTAssertEqual(outStream.buffer, Data("HTTP/1.1 200 OK\r\nContent-Length: 3\r\nSet-Cookie: foo=bar\r\n\r\nfoo"))
    }

    func testResponseSerializeReaderStream() throws {
        let inStream = Drain(buffer: Data("foo"))
        let outStream = Drain()
        let serializer = ResponseSerializer(stream: outStream)
        let response = Response(body: inStream)

        try serializer.serialize(response)
        XCTAssertEqual(outStream.buffer, Data("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nfoo\r\n0\r\n\r\n"))
    }

    func testResponseSerializeWriterStream() throws {
        let outStream = Drain()
        let serializer = ResponseSerializer(stream: outStream)

        let response = Response { (stream: Quark.OutputStream) in
            try stream.write("foo")
            try stream.flush()
        }

        try serializer.serialize(response)
        XCTAssertEqual(outStream.buffer, Data("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nfoo\r\n0\r\n\r\n"))
    }

    func testRequestSerializeBuffer() throws {
        let outStream = Drain()
        let serializer = RequestSerializer(stream: outStream)
        let request = Request(body: "foo")

        try serializer.serialize(request)
        XCTAssertEqual(outStream.buffer, Data("GET / HTTP/1.1\r\nContent-Length: 3\r\n\r\nfoo"))
    }

    func testRequestSerializeReaderStream() throws {
        let inStream = Drain(buffer: "foo")
        let outStream = Drain()
        let serializer = RequestSerializer(stream: outStream)
        let request = Request(body: inStream as Quark.InputStream)

        try serializer.serialize(request)
        XCTAssertEqual(outStream.buffer, Data("GET / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nfoo\r\n0\r\n\r\n"))
    }

    func testRequestSerializeWriterStream() throws {
        let outStream = Drain()
        let serializer = RequestSerializer(stream: outStream)

        let request = Request { (stream: Quark.OutputStream) in
            try stream.write("foo")
            try stream.flush()
        }

        try serializer.serialize(request)
        XCTAssertEqual(outStream.buffer, Data("GET / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nfoo\r\n0\r\n\r\n"))
    }

    func testBodyStream() throws {
        let transport = Drain()
        let bodyStream = BodyStream(transport)
        bodyStream.close()
        XCTAssertEqual(bodyStream.closed, true)
        do {
            try bodyStream.write(Data(), deadline: .never)
            XCTFail()
        } catch {}
        bodyStream.closed = false
        var buffer = Data(count: 1)
        XCTAssertThrowsError(try bodyStream.read(into: &buffer))
        try bodyStream.flush()
    }
}

extension HTTPSerializerTests {
    static var allTests: [(String, (HTTPSerializerTests) -> () throws -> Void)] {
        return [
            ("testResponseSerializeBuffer", testResponseSerializeBuffer),
            ("testResponseSerializeBuffer", testResponseSerializeReaderStream),
            ("testResponseSerializeBuffer", testResponseSerializeWriterStream),
            ("testResponseSerializeBuffer", testRequestSerializeBuffer),
            ("testResponseSerializeBuffer", testRequestSerializeReaderStream),
            ("testResponseSerializeBuffer", testRequestSerializeWriterStream),
            ("testResponseSerializeBuffer", testBodyStream),
        ]
    }
}
