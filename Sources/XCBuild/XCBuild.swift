import Foundation
import Task
import FileSystem
import Url
import Arguments
import Result
import Terminal

/// Low-level Wrapper around xcodebuild. This is a starting point for additonal wrappers that do things like auto detection
/// of certain settings/options. However there are some things XCBuild already does which makes it a little bit more than
/// just a wrapper. It offers a nice struct around the export-plist, it interprets the results of executed commands
/// and finds generated files (ipas, ...). xcrun is also used throughout this class.
public final class XCBuild {
    // MARK: - Properties
    public let system: System
    public let fileSystem: FileSystem
    private let ui: UI
    
    // MARK: - Init
    public init(system: System, fileSystem: FileSystem, ui: UI) {
        self.system = system
        self.fileSystem = fileSystem
        self.ui = ui
        Terminal.shared.verbose = true
    }
    
    // MARK: - Archiving
    @discardableResult
    public func archive(using options: ArchiveOptions) throws -> Archive {
        var options = options
        if options.destination == nil {
            options.destination = Destination.generic(platform: ArchivePlatform.iOS.rawValue)
        }
        let task = try _archiveTask(using: options).dematerialize()
        try system.execute(task).assertSuccess()
        guard let archivePath = options.archivePath else {
            throw "Archive failed. No archivePath set."
        }
        return try Archive(url: archivePath, fileSystem: fileSystem)
    }
    
    private func _archiveTask(using options: ArchiveOptions) throws -> Result<Task, TaskCreationError> {
        let result = _xcodebuild()
        result.value?.arguments += options.arguments
        return result
    }
    
    // MARK: Exporting
    @discardableResult
    public func export(using options: ExportArchiveOptions) throws -> Export {
        let task = try _exportTask(using: options).dematerialize()
        try system.execute(task).assertSuccess()
        guard let exportPath = options.exportPath else {
            throw "Export failed. No archivePath set."
        }
        return try Export(url: exportPath, fileSystem: fileSystem)
    }
    
    private func _exportTask(using options: ExportArchiveOptions) -> Result<Task, TaskCreationError> {
        let result = _xcodebuild()
        result.value?.arguments += options.arguments
        return result
    }
    
    // MARK: Testing
    @discardableResult
    public func buildAndTest(using options: TestOptions) throws -> TestReport {
        var options = options
        if options.destination == nil {
            options.destination = try _buildAndTestDestination(using: options)
        }
        let xcbuild = try _buildTestTask(using: options).dematerialize()
        if let xcpretty = system.task(named: "xcpretty").value {
            xcbuild.output = .pipe()
            xcbuild.environment["NSUnbufferedIO"] = "YES" // otherwise xcpretty might not get everything
            xcpretty.input = xcbuild.output
            try system.launch(xcbuild, wait: false).assertSuccess()
            try system.execute(xcpretty).assertSuccess()
        } else {
            try system.execute(xcbuild).assertSuccess()
        }
        return TestReport()
    }
    
    @discardableResult
    public func _buildAndTestDestination(using options: TestOptions) throws -> Destination? {
        ui.message("Trying to detect destination…")
        var options = options
        options.destinationTimeout = 1
        options.destination = Destination.named("NoSuchName")
        let xcbuild = try _buildTestTask(using: options).dematerialize()
        xcbuild.enableErrorOutputCapturing()
        _ = system.execute(xcbuild)
        guard let output = xcbuild.trimmedErrorOutput else {
            ui.error("Unable to detect destionation. Got no output from xcodebuild.")
            return nil
        }
        ui.verbose("xcodebuild output:\n\n\(output)")
        return try Destination.destinations(xcbuildOutput: output).first
    }
    
    private func _buildTestTask(using options: TestOptions) -> Result<Task, TaskCreationError> {
        let result = _xcodebuild()
        result.value?.arguments += options.arguments
        return result
    }
    
    // MARK: Helper
    private func _xcodebuild() -> Result<Task, TaskCreationError> {
        let result = system.task(named: "xcrun")
        result.value?.arguments = ["xcodebuild"]
        return result
    }
}

fileprivate struct XCodeBuildOption {
    fileprivate init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
    fileprivate let name: String
    fileprivate var value: String?
}

extension XCodeBuildOption: ArgumentsConvertible {
    func arguments() -> Arguments? {
        guard let value = value else { return nil }
        return Arguments(["-" + name, value])
    }
}

private func _option(_ name: String, value: String?) -> XCodeBuildOption {
    return XCodeBuildOption(name: name, value: value)
}
private func _option(_ name: String, value: Int?) -> XCodeBuildOption {
    let stringValue: String?
    if let value = value {
        stringValue = String(value)
    } else {
        stringValue = nil
    }
    return XCodeBuildOption(name: name, value: stringValue)
}

fileprivate extension ArchiveOptions {
    var arguments: Arguments {
        var args = Arguments.empty
        args += _option("scheme", value: scheme)
        args += _option("project", value: project?.path)
        args += _option("destination", value: destination.map { "\($0.asString)" })
        args += _option("archivePath", value: archivePath?.path)
        args.append("archive")
        return args
    }
}

fileprivate extension ExportArchiveOptions {
    var arguments: Arguments {
        var args = Arguments("-exportArchive")
        args += _option("exportOptionsPlist", value: exportOptionsPlist?.url.path)
        args += _option("archivePath", value: archivePath?.path)
        args += _option("exportPath", value: exportPath?.path)
        return args
    }
}

fileprivate extension TestOptions {
    var arguments: Arguments {
        var args = Arguments.empty
        args += _option("scheme", value: scheme)
        args += _option("project", value: project)
        args += _option("destination", value: destination.map { "\($0.asString)" })
        args += _option("destination-timeout", value: destinationTimeout)
        args.append(["build", "test"])
        return args
    }
}

