import Foundation
import FileSystem
import XCBuild
import Task
import HighwayCore
import Terminal
import Deliver
import POSIX
import Git
import SwiftTool
import HWKit
import Keychain

open class Highway<T: RawRepresentable>: _Highway<T> where T.RawValue == String {
    public let fileSystem: FileSystem = LocalFileSystem()
    public let cwd = abscwd()
    public let system: System = LocalSystem.local()
    public lazy var ui: UI = {
        let invocation = CommandLineInvocationProvider().invocation()
        Terminal.shared.verbose = invocation.verbose
        return Terminal.shared
    }()
    public lazy var git: GitTool = {
        return _GitTool(system: system)
    }()
    
    public lazy var keychain: Keychain = {
        return Keychain(system: system)
    }()

    public lazy var deliver: _Deliver = {
        return Deliver.Local(altool: Altool(system: system, fileSystem: fileSystem))
    }()
    public lazy var xcbuild: XCBuild = {
        return XCBuild(system: system, fileSystem: fileSystem, ui: ui)
    }()
    public lazy var swift: SwiftTool = {
        return _SwiftTool(system: system)
    }()
    open override func didFinishLaunching(with invocation: Invocation) {
        ui.verbosePrint(VerboseInfo(version: nil))
        super.didFinishLaunching(with: invocation)
        do {
            let text = try descriptions.jsonString()
            let config = HighwayBundle.Configuration.standard
            let url = cwd.appending(config.directoryName).appending(config.projectDescriptionName)
            try fileSystem.writeString(text, to: url)
        } catch {
            ui.error(error.localizedDescription)
        }
    }
}
