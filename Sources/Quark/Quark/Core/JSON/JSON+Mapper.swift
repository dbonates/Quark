import C7

extension JSON: MapProtocol {

    public subscript(indexPath: IndexPathElement) -> JSON? {
        get {
            switch indexPath.indexPathValue {
            case .index(let index):
                guard case .array(let array) = self else { return nil }
                return array[index]
            case .key(let key):
                guard case .object(let object) = self else { return nil }
                return object[key]
            }
        }
    }

    public func get<T>() -> T? {
        switch self {
        case .null: return nil
        case .number(let number):
            switch number {
            case .integer(let value as T): return value
            case .double(let value as T): return value
            case .unsignedInteger(let value as T): return value
            default: return nil
            }
        case .boolean(let value as T): return value
        case .string(let value as T): return value
        case .array(let value as T): return value
        case .object(let value as T): return value
        default: return nil
        }
    }

    public var asArray: [JSON]? {
        if case .array(let array) = self {
            return array
        }
        return nil
    }

}
