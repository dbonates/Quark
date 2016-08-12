@_exported import Quark
@_exported import ExampleDomain

let development = try Configuration(file: "Development.swift")
let production = try Configuration(file: "Production.swift")
let store = InMemoryStore()
let app = Application(store: store)
let router = MainRouter(app: app)
let server = try Server(configuration: development["server"], responder: router)
try server.start()
