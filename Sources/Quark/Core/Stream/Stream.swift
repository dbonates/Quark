public enum StreamError : Error {
    case closedStream(data: Data)
    case timeout(data: Data)
}

public protocol OutputStream {
    var closed: Bool { get }
    func close()
    func write(_ data: Data, deadline: Double) throws
    func flush(deadline: Double) throws
}

extension OutputStream {
    public func write(_ data: Data) throws {
        try write(data, deadline: .never)
    }

    public func write(_ convertible: DataConvertible, deadline: Double = .never) throws {
        try write(convertible.data, deadline: deadline)
    }

    public func flush() throws {
        try flush(deadline: .never)
    }
}


public protocol InputStream {
    var closed: Bool { get }
    func close()
    func read(upTo byteCount: Int, deadline: Double) throws -> Data
}

extension InputStream {
    public func read(upTo byteCount: Int) throws -> Data {
        return try read(upTo: byteCount, deadline: .never)
    }
}

public typealias Stream = OutputStream & InputStream
