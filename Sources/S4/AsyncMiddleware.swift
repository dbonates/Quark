public protocol AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder, result: ((Void) throws -> Response) -> Void)
}

extension AsyncMiddleware {
    public func chain(to responder: AsyncResponder) -> AsyncResponder {
        return BasicAsyncResponder { request, result in
            self.respond(to: request, chainingTo: responder, result: result)
        }
    }
}

extension Collection where Self.Iterator.Element == AsyncMiddleware {
    public func chain(to responder: AsyncResponder) -> AsyncResponder {
        var responder = responder

        for middleware in self.reversed() {
            responder = middleware.chain(to: responder)
        }

        return responder
    }
}

