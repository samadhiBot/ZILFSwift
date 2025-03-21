import Foundation
import ZILFCore

/// Output capture console for testing.
public class OutputCapture: GameConsole {
    private(set) public var capturedOutput: [String] = []

    public init() {}

    public func output(_ message: String) {
        capturedOutput.append(message)
    }

    public func clearCapturedOutput() {
        capturedOutput.removeAll()
    }

    public func flush() -> String {
        defer { clearCapturedOutput() }
        return capturedOutput.joined(separator: "\n")
    }

    public func updateStatusLine(location: String, score: Int, moves: Int) {
        // Not needed for testing
    }

    public func getInput(prompt: String) -> String? {
        // This should never be called during testing
        nil
    }

    public func shutdown() {
        // Not needed for testing
    }
}
