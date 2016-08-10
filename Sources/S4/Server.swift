public protocol Server {
    init(configuration: Map, middleware: [Middleware], responder: Responder) throws
    func start() throws
}
