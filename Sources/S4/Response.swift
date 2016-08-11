public struct Response : Message {
    public var version: Version
    public var status: Status
    public var headers: Headers
    public var cookieHeaders: Set<String>
    public var body: Body
    public var storage: [String: Any] = [:]

    public init(version: Version, status: Status, headers: Headers, cookieHeaders: Set<String>, body: Body) {
        self.version = version
        self.status = status
        self.headers = headers
        self.cookieHeaders = cookieHeaders
        self.body = body
    }
}

public protocol ResponseInitializable {
    init(response: Response)
}

public protocol ResponseRepresentable {
    var response: Response { get }
}

public protocol ResponseConvertible : ResponseInitializable, ResponseRepresentable {}

extension Response : ResponseConvertible {
    public init(response: Response) {
        self = response
    }

    public var response: Response {
        return self
    }
}

extension Response {
    public init(status: Status = .ok, headers: Headers = [:], body: Body) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: [],
            body: body
        )

        switch body {
        case let .buffer(body):
            self.headers["Content-Length"] = body.count.description
        default:
            self.headers["Transfer-Encoding"] = "chunked"
        }
    }

    public init(status: Status = .ok, headers: Headers = [:], body: Data = []) {
        self.init(
            status: status,
            headers: headers,
            body: .buffer(body)
        )
    }

    public init(status: Status = .ok, headers: Headers = [:], body: InputStream) {
        self.init(
            status: status,
            headers: headers,
            body: .reader(body)
        )
    }

    public init(status: Status = .ok, headers: Headers = [:], body: @escaping (C7.OutputStream) throws -> Void) {
        self.init(
            status: status,
            headers: headers,
            body: .writer(body)
        )
    }
}

extension Response {
    public init(status: Status = .ok, headers: Headers = [:], body: DataConvertible) {
        self.init(
            status: status,
            headers: headers,
            body: body.data
        )
    }
}
