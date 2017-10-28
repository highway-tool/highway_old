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

open class Highway<T: RawRepresentable>: _Highway<T> where T.RawValue == String {
    public let fileSystem: FileSystem = LocalFileSystem()
    public let cwd = abscwd()
    public let system = LocalSystem.local()
    public let ui: UI = Terminal.shared
    public lazy var git: GitTool = {
        return _GitTool(system: system)
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
}
