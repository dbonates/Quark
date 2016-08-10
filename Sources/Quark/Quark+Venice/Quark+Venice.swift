extension FileResponder {
    public init(path: String, headers: Headers = [:]) {
        self.init(path: path, headers: headers, fileType: File.self)
    }
}

extension Request {
    public init(method: Method = .get, uri: URI = URI(path: "/"), headers: Headers = [:], filePath: String) throws {
        try self.init(method: method, uri: uri, headers: headers, filePath: filePath, fileType: File.self)
    }
}

extension Response {
    public init(status: Status = .ok, headers: Headers = [:], filePath: String) throws {
        try self.init(status: status, headers: headers, filePath: filePath, fileType: File.self)
    }
}

extension BasicRouter {
    public init(recover: Recover = RecoveryMiddleware.recover, staticFilesPath: String = "Public", middleware: [Middleware] = [], routes: (Routes) -> Void) {
        self.init(recover: recover, staticFilesPath: staticFilesPath, fileType: File.self, middleware: middleware, routes: routes)
    }
}

extension BasicResource {
    public init(recover: Recover = RecoveryMiddleware.recover, staticFilesPath: String = "Public", middleware: [Middleware] = [], routes: (ResourceRoutes) -> Void) {
        self.init(recover: recover, staticFilesPath: staticFilesPath, fileType: File.self, middleware: middleware, routes: routes)
    }
}

// Warning: Due to a swift bug this has to be in the same file the protocol is declared
// When we split Venice from Quark this will have to be uncommented

// extension Resource {
//     public var file: C7.File.Type {
//         return File.self
//     }
// }
//
// extension Router {
//     public var file: C7.File.Type {
//         return File.self
//     }
// }
