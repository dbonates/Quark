public struct Data {
    public var bytes: [Byte]

    public init(_ bytes: [Byte]) {
        self.bytes = bytes
    }
}

public protocol DataInitializable {
    init(data: Data) throws
}

public protocol DataRepresentable {
    var data: Data { get }
}

public protocol DataConvertible : DataInitializable, DataRepresentable {}

extension Data {
    public init(_ string: String) {
        self.init([Byte](string.utf8))
    }
}

extension Data {
    public init(_ slice: ArraySlice<Byte>) {
        self.init(Array(slice))
    }
}

extension Data : RangeReplaceableCollection, MutableCollection {
    public init() {
        self.init([])
    }

    public init<S : Sequence>(_ elements: S) where S.Iterator.Element == Byte {
        self.init(Array(elements))
    }

    public mutating func replaceSubrange<C : Collection>(_ subRange: Range<Int>, with newElements: C) where C.Iterator.Element == Byte {
        self.bytes.replaceSubrange(subRange, with: newElements)
    }


    public func makeIterator() -> IndexingIterator<[Byte]> {
        return bytes.makeIterator()
    }

    public var startIndex: Int {
        return bytes.startIndex
    }

    public var endIndex: Int {
        return bytes.endIndex
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }

    public subscript(index: Int) -> Byte {
        get {
            return bytes[index]
        }

        set(value) {
            bytes[index] = value
        }
    }

    public subscript(bounds: Range<Int>) -> ArraySlice<Byte> {
        get {
            return bytes[bounds]
        }

        set(slice) {
            bytes[bounds] = slice
        }
    }
}

extension Data : ExpressibleByArrayLiteral {
    public init(arrayLiteral bytes: Byte...) {
        self.init(bytes)
    }
}

extension Data : ExpressibleByStringLiteral {
    public init(stringLiteral string: String) {
        self.init(string)
    }

    public init(extendedGraphemeClusterLiteral string: String){
        self.init(string)
    }

    public init(unicodeScalarLiteral string: String){
        self.init(string)
    }
}

extension Data : Equatable {}

public func == (lhs: Data, rhs: Data) -> Bool {
    return lhs.bytes == rhs.bytes
}

public func += <S : Sequence>(lhs: inout Data, rhs: S) where S.Iterator.Element == Byte {
    return lhs.bytes += rhs
}

public func += (lhs: inout Data, rhs: Data) {
    return lhs.bytes += rhs.bytes
}

public func += (lhs: inout Data, rhs: DataRepresentable) {
    return lhs += rhs.data
}

public func + (lhs: Data, rhs: Data) -> Data {
    return Data(lhs.bytes + rhs.bytes)
}

public func + (lhs: Data, rhs: DataRepresentable) -> Data {
    return lhs + rhs.data
}

public func + (lhs: DataRepresentable, rhs: Data) -> Data {
    return lhs.data + rhs
}

extension String : DataConvertible {
    public init(data: Data) throws {
        struct StringError: Error {}
        var string = ""
        var decoder = UTF8()
        var generator = data.makeIterator()

        loop: while true {
            switch decoder.decode(&generator) {
            case .scalarValue(let char): string.append(String(char))
            case .emptyInput: break loop
            case .error: throw StringError()
            }
        }

        self = string
    }

    public var data: Data {
        return Data(self)
    }
}

extension Data {
    public func withUnsafeBufferPointer<R>(body: (UnsafeBufferPointer<Byte>) throws -> R) rethrows -> R {
        return try bytes.withUnsafeBufferPointer(body)
    }

    public mutating func withUnsafeMutableBufferPointer<R>(body: (inout UnsafeMutableBufferPointer<Byte>) throws -> R) rethrows -> R {
       return try bytes.withUnsafeMutableBufferPointer(body)
    }

    public static func buffer(with size: Int) -> Data {
        return Data([UInt8](repeating: 0, count: size))
    }
}

extension Data {
    public func hexadecimalString(inGroupsOf characterCount: Int = 0) -> String {
        var string = ""
        for (index, value) in self.enumerated() {
            if characterCount != 0 && index > 0 && index % characterCount == 0 {
                string += " "
            }
            string += (value < 16 ? "0" : "") + String(value, radix: 16)
        }
        return string
    }

    public var hexadecimalDescription: String {
        return hexadecimalString(inGroupsOf: 2)
    }
}

extension Data : CustomStringConvertible {
    public var description: String {
        if let string = try? String(data: self) {
            return string
        }

        return debugDescription
    }
}

extension Data : CustomDebugStringConvertible {
    public var debugDescription: String {
        return hexadecimalDescription
    }
}
