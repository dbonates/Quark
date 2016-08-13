public enum StreamError : Error {
    case closedStream(data: Data)
    case timeout(data: Data)
}

public protocol OutputStream {
    var closed: Bool { get }
    func close()
    func write(_ buffer: Data, length: Int, deadline: Double) throws
    func flush(deadline: Double) throws
}

extension OutputStream {
    public func write(_ buffer: Data, length: Int) throws {
        try write(buffer, length: length, deadline: .never)
    }

    public func write(_ buffer: Data, deadline: Double = .never) throws {
        try write(buffer, length: buffer.count, deadline: .never)
    }

    public func write(_ convertible: DataConvertible, length: Int, deadline: Double = .never) throws {
        try write(convertible.data, length: length, deadline: deadline)
    }

    public func write(_ convertible: DataConvertible, deadline: Double = .never) throws {
        let buffer = convertible.data
        try write(buffer, length: buffer.count, deadline: deadline)
    }

    public func flush() throws {
        try flush(deadline: .never)
    }
}


public protocol InputStream {
    var closed: Bool { get }
    func close()
    func read(into buffer: inout Data, deadline: Double) throws -> Int
}

extension InputStream {
    public func read(into buffer: inout Data) throws -> Int {
        return try read(into: &buffer, deadline: .never)
    }
}

public typealias Stream = OutputStream & InputStream
