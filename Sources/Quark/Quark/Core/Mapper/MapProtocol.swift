public protocol MapProtocol {

    subscript(indexPath: IndexPathElement) -> Self? { get }
    subscript(indexPath: [IndexPathElement]) -> Self? { get }
    var asArray: [Self]? { get }
    func get<T>() -> T?

}

extension MapProtocol {

    public subscript(indexPath: [IndexPathElement]) -> Self? {
        get {
            var result = self
            for index in indexPath {
                if let deeped = result[index] {
                    result = deeped
                } else {
                    break
                }
            }
            return result
        }
    }

    public subscript(indexPath: IndexPathElement...) -> Self? {
        get {
            return self[indexPath]
        }
    }

}
