import Foundation
@testable import ZILFCore

/// Test output handler that stores output for verification
public class OutputCapture: OutputManager {
    public var output = ""
    public var capturedOutput: [String] = []

    public init() {}

    // Function that conforms to GameEngine's expected (String) -> Void type
    public lazy var handler: (String) -> Void = { [weak self] text in
        self?.output += text + "\n"
    }

    public func output(_ message: String) {
        output += message + "\n"
        capturedOutput.append(message)
    }

    public func clearCapturedOutput() {
        capturedOutput.removeAll()
    }

    public func updateStatusLine(location: String, score: Int, moves: Int) {
        // No-op for tests
    }

    public func getInput(prompt: String) -> String? {
        return ""
    }

    public func shutdown() {
        // No-op for tests
    }

    public func clear() {
        output = ""
        clearCapturedOutput()
    }
}
