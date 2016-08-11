public struct FileResponder : Responder {
    let path: String
    let headers: Headers

    public init(path: String, headers: Headers = [:]) {
        self.path = path
        self.headers = headers
    }

    public func respond(to request: Request) throws -> Response {
        if request.method != .get {
            throw ClientError.methodNotAllowed
        }

        guard let filepath = request.path else {
            throw ServerError.internalServerError
        }

        return try Response(status: .ok, headers: headers, filePath: self.path + filepath)
    }
}
