import Foundation

/// Custom error type for test failures
public struct TestFailure: Error, CustomStringConvertible {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var description: String {
        return message
    }
}
