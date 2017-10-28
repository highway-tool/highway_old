import Foundation

extension _Highway {
    public class Raw<T: RawRepresentable> where T.RawValue == String {
        // MARK: - Types
        typealias HighwayBody = (Invocation) throws -> Any?
        
        // MARK: - Properties
        public var name: String
        public var usage: String?
        public var dependencies = [T]()
        var body: HighwayBody?
        public var result: Any?
        public var description: HighwayDescription {
            return HighwayDescription(name: name, usage: usage)
        }
        
        // MARK: - Init
        init(name: String, usage: String? = nil) {
            self.name = name
            self.usage = usage
        }
        
        // MARK: - Setting Bodies
        public static func ==> (lhs: Raw, rhs: @escaping () throws -> ()) { lhs.execute(rhs) }
        public static func ==> (lhs: Raw, rhs: @escaping () throws -> (Any)) { lhs.execute(rhs) }
        public static func ==> (lhs: Raw, rhs: @escaping (Invocation) throws -> (Any?)) { lhs.execute(rhs) }
        public static func ==> (lhs: Raw, rhs: @escaping (Invocation) throws -> ()) { lhs.execute(rhs) }
        
        // MARK: - Set Bodies
        private func execute(_ newBody: @escaping () throws -> ()) {
            body = { _ in try newBody() }
        }
        
        private func execute(_ newBody: @escaping (_ invocation: Invocation) throws -> ()) {
            body = {
                try newBody($0)
                return ()
            }
        }
        
        private func execute(_ newBody: @escaping (_ invocation: Invocation) throws -> (Any?)) {
            body = { try newBody($0) }
        }
        
        private func execute(_ newBody: @escaping () throws -> (Any?)) {
            body = { _ in try newBody() }
        }
        
        // MARK: - Set Dependencies
        public func depends(on highways: T...) -> Raw {
            dependencies = highways
            return self
        }
        public func usage(_ string: String) -> Raw {
            usage = string
            return self
        }
        
        // MARK: - Invoke the Highway
        func invoke(with invocation: Invocation) throws {
            result = try body?(invocation)
        }
    }
}
