public protocol Mappable {

    init<Map: MapProtocol>(mapper: Mapper<Map>) throws

}

public protocol MappableWithContext: Mappable {

    associatedtype Context

    init<Map: MapProtocol>(mapper: ContextualMapper<Map, Context>) throws

}

extension MappableWithContext {

    public init<Map: MapProtocol>(mapper: Mapper<Map>) throws {
        let contextual = ContextualMapper<Map, Context>(of: mapper.highMap, context: nil)
        try self.init(mapper: contextual)
    }

}

extension Mappable {

    public init<Map: MapProtocol>(from map: Map) throws {
        let mapper = Mapper(of: map)
        try self.init(mapper: mapper)
    }

}

extension MappableWithContext {

    public init<Map: MapProtocol>(from map: Map, withContext context: Context) throws {
        let mapper = ContextualMapper(of: map, context: context)
        try self.init(mapper: mapper)
    }

}
