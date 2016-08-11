public struct Server : S4.Server {
    public let tcpHost: Host
    public let middleware: [Middleware]
    public let responder: Responder
    public let failure: (Error) -> Void

    public let host: String
    public let port: Int
    public let bufferSize: Int

    public init(configuration: Map, middleware: [Middleware], responder: Responder, failure: @escaping (Error) -> Void) throws {
        let host = configuration["tcp", "host"]?.string ?? "0.0.0.0"
        let port = configuration["tcp", "port"]?.int ?? 8080
        let backlog = configuration["tcp", "host"]?.int ?? 128
        let reusePort = configuration["tcp", "reusePort"]?.bool ?? false

        let bufferSize = configuration["bufferSize"]?.int ?? 2048
        let enableLog = configuration["log"]?.bool ?? true
        let enableSession = configuration["session"]?.bool ?? true
        let enableContentNegotiation = configuration["contentNegotiation"]?.bool ?? true

        self.tcpHost = try TCPHost(
            configuration: [
                "host": Map(host),
                "port": Map(port),
                "backlog": Map(backlog),
                "reusePort": Map(reusePort),
            ]
        )

        var chain: [Middleware] = []

        if enableLog {
            chain.append(LogMiddleware())
        }

        if enableSession {
            chain.append(SessionMiddleware())
        }

        if enableContentNegotiation {
            chain.append(ContentNegotiationMiddleware(mediaTypes: [JSON.self, URLEncodedForm.self]))
        }

        chain.append(contentsOf: middleware)

        self.host = host
        self.port = port
        self.bufferSize = bufferSize
        self.middleware = chain
        self.responder = responder
        self.failure = failure
    }

    public init(configuration: Map, middleware: [Middleware] = [], responder representable: ResponderRepresentable, failure: @escaping (Error) -> Void = Server.log(error:)) throws {
        try self.init(
            configuration: configuration,
            middleware: middleware,
            responder: representable.responder,
            failure: failure
        )
    }

    public init(configuration: Map, middleware: [Middleware] = [], responder: Responder) throws {
        try self.init(
            configuration: configuration,
            middleware: middleware,
            responder: responder,
            failure: Server.log(error:)
        )
    }
}

extension Server {
    public func start() throws {
        printHeader()
        while true {
            let stream = try tcpHost.accept()
            co { do { try self.process(stream: stream) } catch { self.failure(error) } }
        }
    }

    public func startInBackground() {
        co { do { try self.start() } catch { self.failure(error) } }
    }

    public func process(stream: Stream) throws {
        let parser = RequestParser(stream: stream)
        let serializer = ResponseSerializer(stream: stream)

        while !stream.closed {
            do {
                let request = try parser.parse()
                let response = try middleware.chain(to: responder).respond(to: request)
                try serializer.serialize(response)

                if let upgrade = response.upgradeConnection {
                    try upgrade(request, stream)
                    try stream.close()
                }

                if !request.isKeepAlive {
                    try stream.close()
                }
            } catch SystemError.brokenPipe {
                break
            } catch {
                if stream.closed {
                    break
                }

                let (response, unrecoveredError) = Server.recover(error: error)
                try serializer.serialize(response)

                if let error = unrecoveredError {
                    throw error
                }
            }
        }
    }

    private static func recover(error: Error) -> (Response, Error?) {
        switch error {
        case let error as HTTPError:
            return (Response(status: error.status), nil)
        default:
            return (Response(status: .internalServerError), error)
        }
    }

    public static func log(error: Error) -> Void {
        print("Error: \(error)")
    }

    public func printHeader() {
        var header = "\n"
        header += "\n"
        header += "\n"
        header += "                             _____\n"
        header += "     ,.-``-._.-``-.,        /__  /  ___ _      ______\n"
        header += "    |`-._,.-`-.,_.-`|         / /  / _ \\ | /| / / __ \\\n"
        header += "    |   |ˆ-. .-`|   |        / /__/  __/ |/ |/ / /_/ /\n"
        header += "    `-.,|   |   |,.-`       /____/\\___/|__/|__/\\____/ (c)\n"
        header += "        `-.,|,.-`           -----------------------------\n"
        header += "\n"
        header += "================================================================================\n"
        header += "Started HTTP server at \(host), listening on port \(port)."
        print(header)
    }
}
