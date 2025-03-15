import Foundation
@testable import ZILFCore

/// Test output handler that stores output for verification
public class OutputCapture: OutputManager {
    public private(set) var capturedOutput: [String] = []
    private var inputResponses: [String] = []
    private var currentResponseIndex = 0

    public init(inputResponses: [String] = []) {
        self.inputResponses = inputResponses
    }

    public func flush() -> String {
        defer { clear() }
        return output
    }

    public var output: String {
        capturedOutput.joined(separator: "\n")
    }

    // MARK: - OutputManager Protocol Methods

    public func output(_ message: String) {
        capturedOutput.append(message)
    }

    public func clearCapturedOutput() {
        clear()
    }

    public func updateStatusLine(location: String, score: Int, moves: Int) {
        let statusLine = "Location: \(location) | Score: \(score) | Moves: \(moves)"
        capturedOutput.append(statusLine)
    }

    public func getInput(prompt: String) -> String? {
        if currentResponseIndex < inputResponses.count {
            let response = inputResponses[currentResponseIndex]
            currentResponseIndex += 1
            return response
        }
        return "quit" // Default response to avoid hanging in tests
    }

    public func shutdown() {
        // No-op for testing
    }

    public func clear() {
        if capturedOutput.isEmpty { return }
        print("Clearing: `\(capturedOutput.joined(separator: "\n"))`")
        capturedOutput = []
    }
}
