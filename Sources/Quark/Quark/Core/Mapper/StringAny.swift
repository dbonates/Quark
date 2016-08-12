internal enum StringAny {

    case dict([String: Any])
    case any(Any)

}

extension StringAny: MapProtocol {

    internal subscript(indexPath: IndexPathElement) -> StringAny? {
        switch indexPath.indexPathValue {
        case .key(let key):
            switch self {
            case .dict(let dict):
                return dict[key].map({ .any($0) })
            case .any(let any):
                return (any as? [String: Any])?[key].map({ .any($0) })
            }
        case .index: return nil
        }
    }

    internal func get<T>() -> T? {
        switch self {
        case .any(let any):
            return any as? T
        case .dict(let dict):
            return dict as? T
        }
    }

    internal var asArray: [StringAny]? {
        if case .any(let any) = self {
            if let anies = any as? [Any] {
                return anies.map({ .any($0) })
            }
            if let dicts = any as? [[String: Any]] {
                return dicts.map({ .dict($0) })
            }
            return nil
        }
        return nil
    }

}

extension Mappable {

    public init(from dict: [String: Any]) throws {
        try self.init(from: StringAny.dict(dict))
    }

}

extension MappableWithContext {

    public init(from dict: [String: Any], withContext context: Context) throws {
        try self.init(from: StringAny.dict(dict), withContext: context)
    }

}
