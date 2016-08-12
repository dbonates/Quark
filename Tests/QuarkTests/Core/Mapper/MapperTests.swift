import XCTest
@testable import Quark
import C7

class MapperTests: XCTestCase {

    func testBasicTypesMappings() {

        struct Test: Mappable, MapInitializable {
            let int: Int
            let string: String
            let double: Double
            let bool: Bool

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                int = try mapper.map(from: "int")
                string = try mapper.map(from: "string")
                double = try mapper.map(from: "double")
                bool = try mapper.map(from: "bool")
            }
        }

        let primitiveDict: Map = ["int": 5, "string": "String", "double": 7.8, "bool": true]
        let test = try! Test(map: primitiveDict)
        XCTAssertEqual(test.int, 5)
        XCTAssertEqual(test.string, "String")
        XCTAssertEqual(test.double, 7.8)
        XCTAssertEqual(test.bool, true)
    }

    func testBasicMappings() {

        struct Nest: Mappable {
            let int: Int
            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.int = try mapper.map(from: "int")
            }
        }

        struct Test: Mappable {
            let string: String
            let ints: [Int]
            let nest: Nest

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.string = try mapper.map(from: "string")
                self.ints = try mapper.map(arrayFrom: "ints")
                self.nest = try mapper.map(from: "nest")
            }
        }

        let dict: Map = ["string": "Quark", "ints": [3, 1, 4], "nest": ["int": 7]]
        let test = try! Test(from: dict)
        XCTAssertEqual(test.string, "Quark")
        XCTAssertEqual(test.ints, [3, 1, 4])
        XCTAssertEqual(test.nest.int, 7)
    }

    func testFailNoValue() {

        struct Test: Mappable {
            let string: String

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                string = try mapper.map(from: "rio-2016")
            }
        }

        let dict: Map = ["string": "Rio-2016"]
        XCTAssertThrowsError(try Test(from: dict)) { error in
            guard let error = error as? MapperError, case .noValue = error else {
                XCTFail("Wrong error thrown; must be .noValue")
                return
            }
        }

    }

    func testFailWrongType() {
        struct Test: Mappable {
            let string: String

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                string = try mapper.map(from: "string")
            }
        }

        let dict: Map = ["string": 5]
        XCTAssertThrowsError(try Test(from: dict)) { error in
            guard let error = error as? MapperError, case .wrongType = error else {
                XCTFail("Wrong error thrown; must be .wrongType")
                return
            }
        }
    }

    func testFailRepresentAsArray() {
        struct Test: Mappable {
            let ints: [Int]

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                ints = try mapper.map(arrayFrom: "ints")
            }
        }

        let dict: Map = ["ints": false]
        XCTAssertThrowsError(try Test(from: dict)) { error in
            guard let rError = error as? MapperError, case .cannotRepresentAsArray = rError else {
                print(error)
                XCTFail("Wrong error thrown; must be .cannotRepresentAsArray")
                return
            }
        }

    }

    func testArrayOfMappables() {

        struct Nest: Mappable {
            let int: Int

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                int = try mapper.map(from: "int")
            }
        }

        struct Test: Mappable {
            let nests: [Nest]

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                nests = try mapper.map(arrayFrom: "nests")
            }
        }

        let nests: [Map] = [3, 1, 4, 6, 19].map({ .dictionary(["int": .int($0)]) })
        let dict: Map = ["nests": .array(nests)]
        let test = try! Test(from: dict)
        XCTAssertEqual(test.nests.map({ $0.int }), [3, 1, 4, 6, 19])
    }

    enum SEnum: String {
        case venice
        case annecy
        case quark
    }

    enum IEnum: Int {
        case kharkiv = 1
        case kiev = 2
    }

    func testEnumMap() {

        struct Test: Mappable {
            let string: SEnum
            let int: IEnum

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.string = try mapper.map(from: "next-big-thing")
                self.int = try mapper.map(from: "city")
            }
        }

        let dict: Map = ["next-big-thing": "quark", "city": 1]
        let test = try! Test(from: dict)
        XCTAssertEqual(test.string, .quark)
        XCTAssertEqual(test.int, .kharkiv)
    }

    func testEnumArrayMap() {

        struct Test: Mappable {
            let strings: [SEnum]
            let ints: [IEnum]

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                strings = try mapper.map(arrayFrom: "zewo-projects")
                ints = try mapper.map(arrayFrom: "ukraine-capitals")
            }
        }

        let dict: Map = ["zewo-projects": ["venice", "annecy", "quark"], "ukraine-capitals": [1, 2]]
        let test = try! Test(from: dict)
        XCTAssertEqual(test.strings, [.venice, .annecy, .quark])
        XCTAssertEqual(test.ints, [.kharkiv, .kiev])
    }

    func testEnumFail() {

        enum Device: String {
            case iphone
            case ipod
            case mac
        }

        struct Apple: Mappable {
            let device: Device

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.device = try mapper.map(from: "device")
            }
        }

        let dict: Map = ["device": "windows-pc"]
        XCTAssertThrowsError(try Apple(from: dict)) { error in
            guard let error = error as? MapperError, case .cannotInitializeFromRawValue = error else {
                XCTFail("Wrong error thrown; must be .cannotInitializeFromRawValue")
                return
            }
        }
    }

    enum TestContext {
        case apple
        case peach
        case orange
    }

    struct NestMappableContext: MappableWithContext {
        let int: Int

        init<Map : MapProtocol>(mapper: ContextualMapper<Map, TestContext>) throws {
            let context = mapper.context ?? .apple
            switch context {
            case .apple:
                int = try mapper.map(from: "apple-int")
            case .peach:
                int = try mapper.map(from: "peach-int")
            case .orange:
                int = try mapper.map(from: "orange-int")
            }
        }
    }

    func testContextualMapping() {

        let appleDict: Map = ["apple-int": 1]
        let apple = try! NestMappableContext(from: appleDict, withContext: .apple)
        XCTAssertEqual(apple.int, 1)

        let defaulted = try! NestMappableContext(from: appleDict)
        XCTAssertEqual(defaulted.int, 1)

        let peachDict: Map = ["peach-int": 2]
        let peach = try! NestMappableContext(from: peachDict, withContext: .peach)
        XCTAssertEqual(peach.int, 2)

        let orangeDict: Map = ["orange-int": 3]
        let orange = try! NestMappableContext(from: orangeDict, withContext: .orange)
        XCTAssertEqual(orange.int, 3)

    }

    struct TestMappableContext: MappableWithContext {

        let nest: NestMappableContext

        init<Map : MapProtocol>(mapper: ContextualMapper<Map, TestContext>) throws {
            nest = try mapper.map(withContextFrom: "nest")
        }

    }

    func testMapContextInference() {
        let peach: Map = ["nest": ["peach-int": 207]]
        _ = try! TestMappableContext(from: peach, withContext: .peach)
    }

    struct TestMappableContextArray: MappableWithContext {

        let nests: [NestMappableContext]

        init<Map : MapProtocol>(mapper: ContextualMapper<Map, TestContext>) throws {
            nests = try mapper.map(arrayWithContextFrom: "nests")
        }

    }

    func testContextualArrayMapping() {
        let oranges: [Map] = [2, 0, 1, 6].map({ .dictionary(["orange-int": $0]) })
        let dict: Map = ["nests": .array(oranges)]
        _ = try! TestMappableContextArray(from: dict, withContext: .orange)
    }

    func testMappableUsingContext() {

        struct Test: Mappable {

            let nest: NestMappableContext
            let nests: [NestMappableContext]

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                nest = try mapper.map(from: "nest", usingContext: .peach)
                nests = try mapper.map(arrayFrom: "nests", usingContext: .orange)
            }

        }

        let dict: Map = ["nest": ["peach-int": 10], "nests": [["orange-int": 15]]]
        _ = try! Test(from: dict)
    }

    func testDeep() {

        struct DeepTest: Mappable {

            let hiddenFar: Int

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                hiddenFar = try mapper.map(from: "deeper", "stillDeeper", "close", "gotcha")
            }

        }

        let deepDict: Map = ["deeper": ["stillDeeper": ["close": ["gotcha": 15]]]]
        let deep = try! DeepTest(from: deepDict)
        XCTAssertEqual(deep.hiddenFar, 15)

    }

    func testExhaustiveJSONMapping() {

        struct JSONTest: Mappable {

            let null: Int?
            let int: Int
            let double: Double
            let uint: UInt
            let bool: Bool
            let string: String
            let jsonArray: [JSON]
            let jsonObject: [String: JSON]
            let strings: [String]

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.null = try? mapper.map(from: "null")
                self.int = try mapper.map(from: "int", 0)
                self.double = try mapper.map(from: "double")
                self.uint = try mapper.map(from: "uint")
                self.bool = try mapper.map(from: "bool")
                self.string = try mapper.map(from: "string")
                self.jsonArray = try mapper.map(from: "array")
                self.jsonObject = try mapper.map()
                self.strings = try mapper.map(arrayFrom: "strings")
            }

        }

        let json: JSON = .object([
            "null": .null,
            "int": .array([.number(.integer(15))]),
            "double": .number(.double(5.0)),
            "uint": .number(.unsignedInteger(10)),
            "bool": .boolean(false),
            "string": .string("Quark"),
            "array": .array([.string("UA")]),
            "strings": .array([.string("JP"), .string("UA"), .string("GB")])
        ])
        _ = try! JSONTest(from: json)

    }
    
    func testExhaustiveStringAnyMapping() {
        
        struct DictNest: Mappable {
            let int: Int
            
            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.int = try mapper.map(from: "int")
            }
        }
        
        struct DictTest: Mappable {
            
            let int: Int
            let string: String
            let double: Double
            let nest: DictNest
            let strings: [String]
            let nests: [DictNest]
            let null: Bool?
            
            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.int = try mapper.map(from: "int")
                self.string = try mapper.map(from: "here", "string")
                self.double = try mapper.map(from: "double")
                self.nest = try mapper.map(from: "nest")
                self.strings = try mapper.map(arrayFrom: "strings")
                self.nests = try mapper.map(arrayFrom: "nests")
                self.null = try? mapper.map(from: 5)
            }
            
        }
        
        let stringDict: [String: Any] = ["string": "Quark"]
        let nestDict: [String: Any] = ["int": 3]
        let nestsDictArray: [[String: Any]] = sequence(first: 1, next: { if $0 < 6 { return $0 + 1 } else { return nil } }).map({ ["int": $0] })
        let stringsArray: [Any] = ["rope", "summit"]
        let hugeDict: [String: Any] = [
            "int": Int(5),
            "here": stringDict,
            "double": Double(8.1),
            "nest": nestDict,
            "strings": stringsArray,
            "nests": nestsDictArray,
        ]
        
        _ = try! DictTest(from: hugeDict)
    }

    func testFlatArray() {

        struct Person: Mappable {
            let id: Int
            let name: String

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.id = try mapper.map(from: "id")
                self.name = try mapper.map(from: "name")
            }
        }

        struct PersonCollection: Mappable {
            let people: [Person]

            init<Map : MapProtocol>(mapper: Mapper<Map>) throws {
                self.people = try mapper.map()
            }
        }

        let dict: Map = [["id": 15, "name": "Alfred"], ["id": 21, "name": "Bruce"]]
        let collection = try! PersonCollection(from: dict)
        XCTAssertEqual(collection.people.map({ $0.id }), [15, 21])
        XCTAssertEqual(collection.people.map({ $0.name }), ["Alfred", "Bruce"])
    }

}
