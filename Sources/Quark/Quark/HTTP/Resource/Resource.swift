public protocol CustomResource : RouterRepresentable {
    associatedtype ID : PathParameterConvertible = String
    associatedtype Model : MapInitializable = Map

    associatedtype DetailID : PathParameterConvertible = ID
    associatedtype UpdateID : PathParameterConvertible = ID
    associatedtype DestroyID : PathParameterConvertible = ID

    associatedtype CreateInput : MapInitializable = Model
    associatedtype UpdateInput : MapInitializable = Model

    var staticFilesPath: String { get }
    var fileType: C7.File.Type { get }
    var middleware: [Middleware] { get }

    func list(request: Request) throws -> Response
    func create(request: Request, content: CreateInput) throws -> Response
    func detail(request: Request, id: DetailID) throws -> Response
    func update(request: Request, id: UpdateID, content: UpdateInput) throws -> Response
    func destroy(request: Request, id: DestroyID) throws -> Response

    func recover(error: Error) throws -> Response
    func custom(routes: ResourceRoutes)
}

// Warning: This is here due to a compiler bug.
// This will have to be deleted once we split Venice from Quark

public extension CustomResource {
    var fileType: C7.File.Type {
        return File.self
    }
}

public extension CustomResource {
    var staticFilesPath: String {
        return "Public"
    }

    var middleware: [Middleware] {
        return []
    }
}

public extension CustomResource {
    func list(request: Request) throws -> Response {
        throw ClientError.notFound
    }
}

public extension CustomResource {
    func create(request: Request, content: CreateInput) throws -> Response {
        throw ClientError.notFound
    }
}

public extension CustomResource {
    func detail(request: Request, id: DetailID) throws -> Response {
        throw ClientError.notFound
    }
}

public extension CustomResource {
    func update(request: Request, id: UpdateID, content: UpdateInput) throws -> Response {
        throw ClientError.notFound
    }
}

public extension CustomResource {
    func destroy(request: Request, id: DestroyID) throws -> Response {
        throw ClientError.notFound
    }
}

public extension CustomResource {
    func recover(error: Error) throws -> Response {
        return try RecoveryMiddleware.recover(error: error)
    }

    func custom(routes: ResourceRoutes) {}
}

extension CustomResource {
    public var router: BasicRouter {
        let routes = ResourceRoutes(staticFilesPath: staticFilesPath, fileType: fileType)
        custom(routes: routes)
        routes.list(respond: list)
        routes.create(respond: create)
        routes.detail(respond: detail)
        routes.update(respond: update)
        routes.destroy(respond: destroy)
        return BasicRouter(recover: recover, middleware: middleware, routes: routes)
    }
}
