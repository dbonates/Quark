public struct Request : Message {
    public var method: Method
    public var uri: URI
    public var version: Version
    public var headers: Headers
    public var body: Body
    public var storage: [String: Any]

    public init(method: Method, uri: URI, version: Version, headers: Headers, body: Body) {
        self.method = method
        self.uri = uri
        self.version = version
        self.headers = headers
        self.body = body
        self.storage = [:]
    }
}

public protocol RequestInitializable {
    init(request: Request)
}

public protocol RequestRepresentable {
    var request: Request { get }
}

public protocol RequestConvertible : RequestInitializable, RequestRepresentable {}

extension Request : RequestConvertible {
    public init(request: Request) {
        self = request
    }

    public var request: Request {
        return self
    }
}

extension Request {
    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: Body) {
        self.init(
            method: method,
            uri: uri,
            version: Version(major: 1, minor: 1),
            headers: headers,
            body: body
        )

        switch body {
        case let .buffer(body):
            self.headers["Content-Length"] = body.count.description
        default:
            self.headers["Transfer-Encoding"] = "chunked"
        }
    }

    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: Data = []) {
        self.init(
            method: method,
            uri: uri,
            headers: headers,
            body: .buffer(body)
        )
    }

    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: InputStream) {
        self.init(
            method: method,
            uri: uri,
            headers: headers,
            body: .reader(body)
        )
    }

    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: @escaping (C7.OutputStream) throws -> Void) {
        self.init(
            method: method,
            uri: uri,
            headers: headers,
            body: .writer(body)
        )
    }
}

extension Request {
    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], body: DataRepresentable) {
        self.init(
            method: method,
            uri: uri,
            headers: headers,
            body: body.data
        )
    }
}
