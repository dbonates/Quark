extension Response {
    public var statusCode: Int {
        return status.statusCode
    }

    public var reasonPhrase: String {
        return status.reasonPhrase
    }
}

extension Response {
    public var cookies: Set<AttributedCookie> {
        get {
            var cookies = Set<AttributedCookie>()

            for header in cookieHeaders {
                if let cookie = AttributedCookie(header) {
                    cookies.insert(cookie)
                }
            }

            return cookies
        }

        set(cookies) {
            var headers = Set<String>()

            for cookie in cookies {
                let header = String(describing: cookie)
                headers.insert(header)
            }

            cookieHeaders = headers
        }
    }
}

extension Response {
    public typealias UpgradeConnection = (Request, Stream) throws -> Void

    public var upgradeConnection: UpgradeConnection? {
        return storage["response-connection-upgrade"] as? UpgradeConnection
    }

    public mutating func upgradeConnection(_ upgrade: UpgradeConnection)  {
        storage["response-connection-upgrade"] = upgrade
    }
}

extension Response : CustomStringConvertible {
    public var statusLineDescription: String {
        return "HTTP/" + String(version.major) + "." + String(version.minor) + " " + String(statusCode) + " " + reasonPhrase + "\n"
    }

    public var description: String {
        return statusLineDescription +
            headers.description
    }
}

extension Response : CustomDebugStringConvertible {
    public var debugDescription: String {
        return description + "\n" + storageDescription
    }
}
