import Foundation
import Arguments
import Url
import Task
import POSIX
import Terminal

public struct VerboseInfo {
    // MARK: - Properties
    let arguments: Arguments
    let version: String?
    let cwd: Absolute
    let environment: Environment
    let path: PathEnv
    
    // MARK: - Init
    public init(version: String?) {
        let env = ProcessInfo.processInfo.environment
        environment = Environment(all: env)
        arguments = Arguments(CommandLine.arguments)
        self.version = version
        cwd = abscwd()
        path = PathEnv(environment: env, cwd: cwd)
    }
}

extension VerboseInfo: Printable {
    private func text(with options: Print.Options) -> Text {
        var result = Text()
        result += Text(environment.printableString(with: options)) + .newline + .newline
        result += Text("PATH: \(path.raw ?? "<not set>")") + .newline
        result += Text("Search Urls:") + .newline
        result += Text(path.searchUrls.map { $0.path }.joined(separator: "\n")) + .newline
        result += Text("Arguments:") + .newline
        result += Text(arguments.loggableValues.map { $0 }.joined(separator: "\n")) + .newline
        result += Text("cwd: \(cwd.path)") + .newline
        if let version = version {
            result += Text("Version: \(version)") + .newline
        }
        return result
    }
    
    public func printableString(with options: Print.Options) -> String {
        return text(with: options).printableString(with: options)
    }
}

extension VerboseInfo {
    struct PathEnv {
        init(raw: String?, searchUrls: [Absolute]) {
            self.raw = raw
            self.searchUrls = searchUrls
        }
        
        init(environment: [String: String], cwd: Absolute) {
            let urls = PathEnvironmentParser.local().urls
            self.init(raw: environment["PATH"], searchUrls: urls)
        }
        let raw: String?
        let searchUrls: [Absolute]
    }
}

private extension Dictionary where Key == String, Value == String {
    func printableStringForEnvironment(with options: Print.Options) -> String {
        return map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
    }
}


extension VerboseInfo {
    struct Environment {
        // MARK: - Init
        init(all: [String: String]) {
            highway = all.filter { $0.key.isHighwayEnvironmentVariable }
            other = all.filter { !$0.key.isHighwayEnvironmentVariable }
        }
        
        // MARK: - Properties
        let highway: [String: String]
        let other: [String: String]
    }
}

extension VerboseInfo.Environment: Printable {
    func printableString(with options: Print.Options) -> String {
        var text = Text()
        text += Text.text("Other Environment Variables") + .newline
        text += Text.text(other.printableStringForEnvironment(with: options))
        text += (Text.newline + Text.newline)
        text += Text.text("Highway Environment Variables") + .newline
        text += Text.text(highway.printableStringForEnvironment(with: options))

        return text.printableString(with: options)
    }
}


fileprivate extension String {
    private static let HighwayPrefix = "HIGHWAY_"
    var isHighwayEnvironmentVariable: Bool {
        return uppercased().hasPrefix(.HighwayPrefix)
    }
}
