public protocol Mappable {
    
    init<Map: MapProtocol>(mapper: Mapper<Map>) throws
    
}

public protocol MappableWithContext: Mappable {
    
    associatedtype Context
    
    init<Map: MapProtocol>(mapper: ContextualMapper<Map, Context>) throws
    
}

extension MappableWithContext {
    
    public init<Map: MapProtocol>(mapper: Mapper<Map>) throws {
        let contextual = ContextualMapper<Map, Context>(mapper.map, context: nil)
        try self.init(mapper: contextual)
    }
    
}
