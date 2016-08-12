public struct TrieRouteMatcher {
    private var routesTrie = Trie<String, Route>()
    public let routes: [Route]

    public init(routes: [Route]) {
        self.routes = routes

        for route in routes {
            // break into components
            let components = route.path.split(separator: "/")

            // insert components into trie with route being the ending payload
            routesTrie.insert(components, payload: route)
        }

        // ensure parameter paths are processed later than static paths
        routesTrie.sort { t1, t2 in
            func rank(_ t: Trie<String, Route>) -> Int {
                if t.prefix == "*" {
                    return 3
                }
                if t.prefix?.characters.first == ":" {
                    return 2
                }
                return 1
            }

            return rank(t1) < rank(t2)
        }
    }

    public func match(_ request: Request) -> Route? {
        let path = request.path!
        let components = path.unicodeScalars.split(separator: "/").map(String.init)
        var parameters: [String: String] = [:]

        let matched = searchForRoute(
            head: routesTrie,
            components: components.makeIterator(),
            parameters: &parameters
        )

        guard let route = matched else {
            return nil
        }

        if parameters.isEmpty {
            return route
        }

        // wrap the route to inject the pathParameters upon receiving a request
        return Route(
            path: route.path,
            middleware: [PathParameterMiddleware(parameters)],
            actions: route.actions,
            fallback: route.fallback
        )
    }

    func searchForRoute(head: Trie<String, Route>, components: IndexingIterator<[String]>, parameters: inout [String: String]) -> Route? {

        var components = components

        // if no more components, we hit the end of the path and
        // may have matched something
        guard let component = components.next() else {
            return head.payload
        }

        // store each possible path (ie both a static and a parameter)
        // and then go through them all
        var paths = [(node: Trie<String, Route>, param: String?)]()

        for child in head.children {

            // matched static
            if child.prefix == component {
                paths.append((node: child, param: nil))
                continue
            }

            // matched parameter
            if let prefix = child.prefix, prefix.characters.first == ":" {
                let param = String(prefix.characters.dropFirst())
                paths.append((node: child, param: param))
                continue
            }

            // matched wildstar
            if child.prefix == "*" {
                paths.append((node: child, param: nil))
                continue
            }
        }

        // go through all the paths and recursively try to match them. if
        // any of them match, the route has been matched
        for (node, param) in paths {

            if let route = node.payload, node.prefix == "*" {
                return route
            }

            let matched = searchForRoute(head: node, components: components, parameters: &parameters)

            // this path matched! we're done
            if let matched = matched {

                // add the parameter if there was one
                if let param = param {
                    parameters[param] = component
                }

                return matched
            }
        }

        // we went through all the possible paths and still found nothing. 404
        return nil
    }
}

extension Dictionary {
    func mapValues<T>(_ transform: (Value) -> T) -> [Key: T] {
        var dictionary: [Key: T] = [:]

        for (key, value) in self {
            dictionary[key] = transform(value)
        }

        return dictionary
    }
}
