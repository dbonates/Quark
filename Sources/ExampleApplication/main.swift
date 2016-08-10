@_exported import Quark
@_exported import ExampleDomain

let store = InMemoryStore()
let app = Application(store: store)
let router = MainRouter(app: app)
let server = try Server(configuration: configuration["server"] ?? nil, responder: router)
try server.start()
 
