@_exported import Quark

public var configuration: Map = nil {
    willSet(configuration) {
        do {
            let file = try File(path: "/tmp/QuarkConfiguration", mode: .truncateWrite)
            let serializer = JSONMapSerializer()
            let data = try serializer.serialize(configuration)
            try file.write(data)
        } catch {
            fatalError(String(describing: error))
        }
    }
}
