import Foundation
@testable import ZILFCore

/// Test output handler that stores output for verification
public class OutputCapture: OutputManager {
    public var output = ""
    public var capturedOutput: [String] = []
    private var inputResponses: [String] = []
    private var currentResponseIndex = 0

    public init(inputResponses: [String] = []) {
        self.inputResponses = inputResponses
    }

    // Function that conforms to GameEngine's expected (String) -> Void type
    public lazy var handler: (String) -> Void = { [weak self] text in
        self?.output += text + "\n"
    }

    // MARK: - OutputManager Protocol Methods

    public func output(_ message: String) {
        output += message + "\n"
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
        output = ""
        capturedOutput = []
    }
}
