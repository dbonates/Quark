@_exported import C7
@_exported import S4

public enum QuarkError : Error {
    case invalidConfiguration(description: String)
    case invalidArgument(description: String)
}

extension QuarkError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidConfiguration(let description):
            return description
        case .invalidArgument(let description):
            return description
        }
    }
}

private var configured = false

public var configuration: Map = loadConfiguration() {
    didSet {
        if !configured {
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
}

private func loadConfiguration() -> Map {
    do {
        return try loadConfiguration(
            configurationFile: "Configuration/Configuration",
            arguments: CommandLine.arguments
        )
    } catch {
        fatalError(String(describing: error))
    }
}

private func loadConfiguration(configurationFile: String, arguments: [String]) throws -> Map {
    let environmentVariables = load(environmentVariables: environment.variables)
    let commandLineArguments = try load(arguments: Array(arguments.dropFirst()))

    if let workingDirectory = commandLineArguments["workingDirectory"]?.string ?? environmentVariables["workingDirectory"]?.string {
        try File.changeWorkingDirectory(path: workingDirectory)
    }

    let configurationFile = try load(configurationFile: configurationFile)
    var configuration: Map = [:]

    for (key, value) in configurationFile {
        try configuration.set(value: value, for: key)
    }

    for (key, value) in environmentVariables {
        try configuration.set(value: value, for: key)
    }

    for (key, value) in commandLineArguments {
        try configuration.set(value: value, for: key)
    }

    return configuration
}

private func load(configurationFile: String) throws -> [String: Map] {
    let libraryDirectory = ".build/" + buildConfiguration.buildPath
    let moduleName = "Quark"
    var arguments = ["swiftc"]
    arguments += ["--driver-mode=swift"]
    arguments += ["-I", libraryDirectory, "-L", libraryDirectory, "-l\(moduleName)"]

#if os(OSX)
    arguments += ["-target", "x86_64-apple-macosx10.10"]
#endif

    arguments += [configurationFile]

#if Xcode
    // Xcode's PATH doesn't include swiftenv shims. Let's include it mannualy.
    environment["PATH"] = (environment["HOME"] ?? "") + "/.swiftenv/shims:" + (environment["PATH"] ?? "")
#endif

    try sys(arguments)

    let file = try File(path: "/tmp/QuarkConfiguration")
    let parser = JSONMapParser()
    let data = try file.readAll()
    let configuration = try parser.parse(data).asDictionary()
    configured = true
    return configuration
}

func load(arguments: [String]) throws -> [String: Map] {
    var parameters: Map = [:]

    var currentParameter = ""
    var hasParameter = false
    var value: Map = nil
    var i = 0

    while i < arguments.count {
        if arguments[i].has(prefix: "-") {
            if !hasParameter {
                currentParameter = String(Array(arguments[i].characters).suffix(from: 1))
                hasParameter = true
                i += 1
                continue
            } else {
                value = true
                let indexPath = currentParameter.indexPath()
                try parameters.set(value: value, for: indexPath)
                hasParameter = false
                continue
            }
        }
        if hasParameter {
            let value = parse(value: arguments[i])
            let indexPath = currentParameter.indexPath()
            try parameters.set(value: value, for: indexPath)
            hasParameter = false
            i += 1
        } else {
            throw QuarkError.invalidArgument(description: "\(arguments[i]) is a malformed parameter. Parameters should be provided in the format -parameter [value].")
        }
    }

    if hasParameter {
        let indexPath = currentParameter.indexPath()
        try parameters.set(value: true, for: indexPath)
    }

    return parameters.dictionary!
}

func load(environmentVariables: [String: String]) -> [String: Map] {
    var variables: [String: Map] = [:]

    for (key, value) in environmentVariables {
        let key = convertEnvironmentVariableKeyToCamelCase(key)
        variables[key] = parse(value: value)
    }

    return variables
}

func parse(value: String) -> Map {
    if isNull(value) {
        return .null
    }

    if let intValue = Int(value) {
        return .int(intValue)
    }

    if let doubleValue = Double(value) {
        return .double(doubleValue)
    }

    if let boolValue = convertToBool(value) {
        return .bool(boolValue)
    }

    return .string(value)
}

func isNull(_ string: String) -> Bool {
    switch string {
    case "NULL", "Null", "null", "NIL", "Nil", "nil":
        return true
    default:
        return false
    }
}

func convertToBool(_ string: String) -> Bool? {
    switch string {
    case "TRUE", "True", "true", "YES", "Yes", "yes":
        return true
    case "FALSE", "False", "false", "NO", "No", "no":
        return false
    default:
        return nil
    }
}

func convertEnvironmentVariableKeyToCamelCase(_ variableKey: String) -> String {
    if variableKey == "_" {
        return variableKey
    }

    var key = ""
    let words = variableKey.split(separator: "_", omittingEmptySubsequences: false)

    key += words.first!.lowercased()

    for word in words.suffix(from: 1) {
        key += word.capitalizedWord()
    }

    return key
}

public enum BuildConfiguration {
    case debug
    case release
    case fast

    fileprivate static func currentConfiguration(suppressingWarning: Bool) -> BuildConfiguration {
        if suppressingWarning && _isDebugAssertConfiguration() {
            return .debug
        }
        if suppressingWarning && _isFastAssertConfiguration() {
            return .fast
        }
        return .release
    }
}

extension BuildConfiguration {
    var buildPath: String {
        switch self {
        case .debug: return "debug"
        case .release: return "release"
        case .fast: return "release"
        }
    }
}

public var buildConfiguration: BuildConfiguration {
    return BuildConfiguration.currentConfiguration(suppressingWarning: true)
}

// TODO: refactor this

public enum SpawnError : Error {
    case exitStatus(Int32, [String])
}

extension SpawnError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .exitStatus(let code, let args):
            return "exit(\(code)): \(args)"
        }
    }
}

public func sys(_ arguments: [String]) throws {
    fflush(stdout)
    guard !arguments.isEmpty else {
        throw SystemError.invalidArgument
    }
    
    let pid = try spawn(arguments: arguments)
    let exitStatus = try wait(pid: pid)

    guard exitStatus == 0 else {
        throw SpawnError.exitStatus(exitStatus, arguments)
    }
}

func spawn(arguments: [String]) throws -> pid_t {
    let argv: [UnsafeMutablePointer<CChar>?] = arguments.map {
        $0.withCString(strdup)
    }

    defer {
        for case let a? in argv {
            free(a)
        }
    }

    var envs: [String: String] = [:]

#if Xcode
    let keys = ["SWIFT_EXEC", "HOME", "PATH", "TOOLCHAINS", "DEVELOPER_DIR", "LLVM_PROFILE_FILE"]
#else
    let keys = ["SWIFT_EXEC", "HOME", "PATH", "SDKROOT", "TOOLCHAINS", "DEVELOPER_DIR", "LLVM_PROFILE_FILE"]
#endif

    for key in keys {
        if envs[key] == nil {
            envs[key] = environment[key]
        }
    }

    let env: [UnsafeMutablePointer<CChar>?] = envs.map {
        "\($0.0)=\($0.1)".withCString(strdup)
    }

    defer {
        for case let e? in env {
            free(e)
        }
    }

    var pid = pid_t()
    let rv = posix_spawnp(&pid, argv[0], nil, nil, argv + [nil], env + [nil])

    if rv != 0 {
        try ensureLastOperationSucceeded()
    }

    return pid
}

func wait(pid: pid_t) throws -> Int32 {
    while true {
        var exitStatus: Int32 = 0
        let rv = waitpid(pid, &exitStatus, 0)

        if rv != -1 {
            if exitStatus & 0x7f == 0 {
                return (exitStatus >> 8) & 0xff
            } else {
                try ensureLastOperationSucceeded()
            }
        } else if errno == EINTR {
            continue
        } else {
            try ensureLastOperationSucceeded()
        }
    }
}
