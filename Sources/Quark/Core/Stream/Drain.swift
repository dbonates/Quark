public final class Drain : DataRepresentable, Stream {
    var buffer: Data
    public var closed = false

    public var data: Data {
        return buffer
    }

    public convenience init() {
        self.init(buffer: Data())
    }

    public init(stream: InputStream, deadline: Double = .never) {
        var inputBuffer = Data(count: 2048)
        var outputBuffer = Data()

        if stream.closed {
            self.closed = true
        }

        while !stream.closed {
            if let bytesRead = try? stream.read(into: &inputBuffer, deadline: deadline) {
                outputBuffer.append(Data(inputBuffer.prefix(bytesRead)))
            } else {
                break
            }
        }

        self.buffer = outputBuffer
    }

    public init(buffer: Data) {
        self.buffer = buffer
    }

    public convenience init(buffer: DataRepresentable) {
        self.init(buffer: buffer.data)
    }

    public func close() {
        closed = true
    }

    public func read(into buffer: inout Data, deadline: Double = .never) throws -> Int {
        if buffer.count >= self.buffer.count {
            close()
            return self.buffer.count
        }

        buffer = Data(self.buffer.prefix(upTo: buffer.count))
        self.buffer.removeFirst(buffer.count)

        return buffer.count
    }

    public func write(_ data: Data, length: Int, deadline: Double = .never) throws {
        buffer.append(data)
    }

    public func flush(deadline: Double = .never) throws {}
}
