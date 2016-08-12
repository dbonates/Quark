public enum MapperError: Error {
    case noValue(forIndexPath: [IndexPathElement])
    case wrongType(Any.Type)
    case cannotInitializeFromRawValue(Any)
    case cannotRepresentAsArray
}

public protocol MapperProtocol {

    associatedtype Map: MapProtocol

    var highMap: Map { get }

}

extension MapperProtocol {

    fileprivate func dive(to indexPath: [IndexPathElement]) throws -> Map {
        if let value = highMap[indexPath] {
            return value
        } else {
            throw MapperError.noValue(forIndexPath: indexPath)
        }
    }

    fileprivate func get<T>(from map: Map) throws -> T {
        if let value: T = map.get() {
            return value
        } else {
            throw MapperError.wrongType(T.self)
        }
    }

    fileprivate func array(from map: Map) throws -> [Map] {
        if let array = map.asArray {
            return array
        } else {
            throw MapperError.cannotRepresentAsArray
        }
    }

    fileprivate func rawRepresent<T: RawRepresentable>(_ map: Map) throws -> T {
        let raw: T.RawValue = try get(from: map)
        if let value = T(rawValue: raw) {
            return value
        } else {
            throw MapperError.cannotInitializeFromRawValue(raw)
        }
    }

    public func map<T>(from indexPath: IndexPathElement...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try get(from: leveled)
    }

    public func map<T: Mappable>(from indexPath: IndexPathElement...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try T(mapper: Mapper(of: leveled))
    }

    public func map<T: MappableWithContext>(from indexPath: IndexPathElement..., usingContext context: T.Context) throws -> T {
        let leveled = try dive(to: indexPath)
        return try T(mapper: ContextualMapper(of: leveled, context: context))
    }

    public func map<T: RawRepresentable>(from indexPath: IndexPathElement...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try rawRepresent(leveled)
    }

    public func map<T>(arrayFrom indexPath: IndexPathElement...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try get(from: $0) })
    }

    public func map<T: Mappable>(arrayFrom indexPath: IndexPathElement...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: Mapper(of: $0)) })
    }

    public func map<T: MappableWithContext>(arrayFrom indexPath: IndexPathElement..., usingContext context: T.Context) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: ContextualMapper(of: $0, context: context)) })
    }

    public func map<T: RawRepresentable>(arrayFrom indexPath: IndexPathElement...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try self.rawRepresent($0) })
    }

}

public struct Mapper<Map: MapProtocol>: MapperProtocol {

    public let highMap: Map

    public init(of map: Map) {
        self.highMap = map
    }

}

public struct ContextualMapper<Map: MapProtocol, Context>: MapperProtocol {

    public let highMap: Map
    public let context: Context?

    public init(of map: Map, context: Context?) {
        self.highMap = map
        self.context = context
    }

    public func map<T: MappableWithContext>(withContextFrom indexPath: IndexPathElement...) throws -> T
        where T.Context == Context {
        let leveled = try dive(to: indexPath)
        return try T(mapper: ContextualMapper(of: leveled, context: context))
    }

    public func map<T: MappableWithContext>(arrayWithContextFrom indexPath: IndexPathElement...) throws -> [T]
        where T.Context == Context {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: ContextualMapper(of: $0, context: self.context)) })
    }

}
