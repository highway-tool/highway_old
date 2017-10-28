import Foundation

/// Options for xcodebuild's build & test actions:
public struct TestOptions {
    // MARK: - Init
    public init() {}
    
    // MARK: - Properties
    public var scheme: String? // -scheme
    public var project: String? // -project [sub-type: path]
    
    // If nil XCBuild tries to auto-detect the destination.
    public var destination: Destination? // -destination
    public var destinationTimeout: Int? // -destination-timeout (in seconds)
}
