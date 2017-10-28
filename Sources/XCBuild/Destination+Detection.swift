import Foundation
import Errors

extension Destination {
    
    /// Creates a destination from it's raw xcodebuild representation. For example:
    ///
    /// > "{ platform:iOS Simulator, id:AD911BF6-5421-47D3-AD80-DACBEB9B4B24, OS:11.0.1, name:iPhone 7 }"
    ///
    /// - Parameter raw: A raw destination
    private static func destination(raw: String) -> Destination? {
        guard raw.hasPrefix("{") && raw.hasSuffix("}") else {
            return nil
        }
        guard let idKeyIndex = raw.range(of: "id:") else {
            return nil
        }
        // Contains:
        // "AD911BF6-5421-47D3-AD80-DACBEB9B4B24, OS:11.0.1, name:iPhone 7 }"
        // Read up to the next ","
        let idToEnd = raw[idKeyIndex.upperBound...]
        guard let idEnd = idToEnd.index(of: ",") else {
            return nil
        }
        let id = idToEnd.prefix(upTo: idEnd)
        return Destination.byId(String(id))
    }
    static func destinations(xcbuildOutput output: String) throws -> [Destination] {
        let lines = output.trimmpedLines
        guard let availableIndex = (lines.index { $0.hasPrefix("Available destinations") }) else {
            return []
        }
        
        // lines.suffix(from: availableIndex) also contains " for the "highwayiostest" scheme:\n"
        // so lets drop the first element which results in:
        //
        // " $destination1\n"
        // " $destination2\n"
        // \n
        // ...
        let potentialDestinations = lines.suffix(from: availableIndex).dropFirst()
        
        // Now we try to create destinations for each line until we first get nil
        // as the destination.
        var result = [Destination]()
        for potentialDestination in potentialDestinations {
            guard let dest = Destination.destination(raw: potentialDestination) else {
                return result
            }
            result.append(dest)
        }
        return result
    }
}

private extension String {
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var trimmpedLines: [String] {
        var result = [String]()
        enumerateLines { (line, _) in
            result.append(line.trimmed)
        }
        return result
    }
}

private let fixture3 = """
xcodebuild: error: Unable to find a destination matching the provided destination specifier:
{ name:NoSuchName }

Unsupported device specifier option.
The device “My Mac” does not support the following options: name
Please supply only supported device specifier options.

Available destinations for the "highwayiostest" scheme:
{ platform:iOS Simulator, id:F1ED5B2E-FCD2-414A-83E8-194EA496B91B, OS:10.3.1, name:iPhone 6 - 10.3 }
{ platform:iOS Simulator, id:EA60BBA3-4F0E-4FDA-95F7-1D9A404D033D, OS:11.0.1, name:iPhone 6 - 11 }

Ineligible destinations for the "highwayiostest" scheme:
{ platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Generic iOS Device }
{ platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Generic iOS Simulator Device }

"""
