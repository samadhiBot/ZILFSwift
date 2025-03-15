import Foundation
import SwiftCursesTerm

/// Protocol defining the interface for game output management
public protocol OutputManager {
    /// Outputs a message to the appropriate destination
    func output(_ message: String)

    /// Captures all output for testing purposes
    var capturedOutput: [String] { get }

    /// Clears the captured output
    func clearCapturedOutput()

    /// Updates the status line if supported
    func updateStatusLine(location: String, score: Int, moves: Int)

    /// Gets input from the user with an optional prompt
    func getInput(prompt: String) -> String?

    /// Clean up resources when done
    func shutdown()
}

/// Standard output manager that uses print() for output
public class StandardOutputManager: OutputManager {
    private(set) public var capturedOutput: [String] = []

    public init() {}

    public func output(_ message: String) {
        print(message)
        capturedOutput.append(message)
    }

    public func clearCapturedOutput() {
        capturedOutput.removeAll()
    }

    public func updateStatusLine(location: String, score: Int, moves: Int) {
        // No status line implementation in standard output mode
    }

    public func getInput(prompt: String = "> ") -> String? {
        print(prompt, terminator: "")
        return readLine()
    }

    public func shutdown() {
        // Nothing to clean up
    }
}

/// Terminal UI output manager that uses SwiftCursesTerm
public class TerminalOutputManager: OutputManager {
    private var term: SwiftCursesTerm
    private var statusWindow: SCTWindowId?
    private var mainWindow: SCTWindowId?
    private var inputWindow: SCTWindowId?

    private var termHeight: Int = 24
    private var termWidth: Int = 80

    private var statusColor: Int = 0
    private var inputColor: Int = 0

    private(set) public var capturedOutput: [String] = []
    private var mainWindowContent: String = ""

    public init() {
        // Initialize terminal
        self.term = SwiftCursesTerm()

        // Get terminal dimensions - hardcoded for now
        self.termHeight = 24
        self.termWidth = 80

        // Define colors
        self.statusColor = term.defineColorPair(foreground: .white, background: .blue)
        self.inputColor = term.defineColorPair(foreground: .white, background: .black)

        // Create windows
        self.statusWindow = term.newWindow(height: 1, width: termWidth, line: 0, column: 0)
        term.setColor(window: statusWindow, colorPair: statusColor)
        term.setAttributes(window: statusWindow, [.bold])

        self.mainWindow = term.newWindow(height: termHeight - 2, width: termWidth, line: 1, column: 0)

        self.inputWindow = term.newWindow(height: 1, width: termWidth, line: termHeight - 1, column: 0)
        term.setColor(window: inputWindow, colorPair: inputColor)

        // Refresh all windows
        term.refresh(window: statusWindow)
        term.refresh(window: mainWindow)
        term.refresh(window: inputWindow)
    }

    public func output(_ message: String) {
        // Append to main window content
        if !mainWindowContent.isEmpty {
            mainWindowContent += "\n"
        }
        mainWindowContent += message

        // Display in terminal
        display(mainWindowContent)

        // Store for testing
        capturedOutput.append(message)
    }

    public func clearCapturedOutput() {
        capturedOutput.removeAll()
    }

    /// Updates the status line with current game information
    public func updateStatusLine(location: String, score: Int, moves: Int) {
        guard let statusWin = statusWindow else { return }

        // Clear the status window
        term.addStrTo(window: statusWin, content: String(repeating: " ", count: termWidth), line: 0, column: 0)

        // Create status text
        let statusText = " \(location) | Score: \(score) | Moves: \(moves) "

        // Center the text if possible
        let startPos = max(0, (termWidth - statusText.count) / 2)
        term.addStrTo(window: statusWin, content: statusText, line: 0, column: startPos)

        // Fill the rest of the line with spaces (for consistent background color)
        if startPos + statusText.count < termWidth {
            let padding = String(repeating: " ", count: termWidth - (startPos + statusText.count))
            term.addStrTo(window: statusWin, content: padding, line: 0, column: startPos + statusText.count)
        }

        // Refresh the window
        term.refresh(window: statusWin)
    }

    /// Displays text in the main content area
    private func display(_ text: String) {
        guard let mainWin = mainWindow else { return }

        // Clear the main window
        term.addStrTo(window: mainWin, content: String(repeating: " ", count: termWidth * (termHeight - 2)), line: 0, column: 0)

        // Split text into lines and display
        let lines = text.split(separator: "\n")

        // Calculate how many lines we can display
        let maxLines = termHeight - 2

        // If we have more lines than can fit, show the last maxLines
        let startIndex = lines.count > maxLines ? lines.count - maxLines : 0

        for (index, line) in lines[startIndex...].enumerated() {
            term.addStrTo(window: mainWin, content: String(line), line: index, column: 0)
        }

        // Refresh the window
        term.refresh(window: mainWin)
    }

    /// Gets input from the user
    public func getInput(prompt: String = "> ") -> String? {
        guard let inputWin = inputWindow else { return nil }

        // Clear the input window
        term.addStrTo(window: inputWin, content: String(repeating: " ", count: termWidth), line: 0, column: 0)

        // Display prompt
        term.addStrTo(window: inputWin, content: prompt, line: 0, column: 0)
        term.refresh(window: inputWin)

        // Basic line input implementation
        var input = ""
        var cursorPos = prompt.count

        // Loop until user presses Enter
        var ch = getch()
        while ch != 10 { // 10 is ASCII for Enter/Return
            if ch == 127 || ch == 8 { // Backspace/Delete
                if !input.isEmpty {
                    input.removeLast()
                    cursorPos -= 1

                    // Redraw input line
                    term.addStrTo(window: inputWin, content: String(repeating: " ", count: termWidth), line: 0, column: 0)
                    term.addStrTo(window: inputWin, content: prompt + input, line: 0, column: 0)
                }
            } else if ch >= 32 && ch <= 126 { // Printable characters
                let char = String(UnicodeScalar(UInt8(ch)))
                input.append(char)

                // Add character to display
                term.addStrTo(window: inputWin, content: char, line: 0, column: cursorPos)
                cursorPos += 1
            }

            term.refresh(window: inputWin)
            ch = getch()
        }

        return input
    }

    /// Handle terminal resize event
    public func handleResize() {
        // For now, we'll just redisplay the content
        // since we can't easily get the terminal dimensions

        // Redisplay content
        display(mainWindowContent)

        term.refresh(window: inputWindow)
    }

    /// Clean up resources
    public func shutdown() {
        term.shutdown()
    }

    deinit {
        shutdown()
    }
}

/// Mock output manager for testing
public class MockOutputManager: OutputManager {
    private(set) public var capturedOutput: [String] = []
    public var inputResponses: [String] = []
    private var inputIndex = 0

    public init(inputResponses: [String] = []) {
        self.inputResponses = inputResponses
    }

    public func output(_ message: String) {
        capturedOutput.append(message)
    }

    public func clearCapturedOutput() {
        capturedOutput.removeAll()
    }

    public func updateStatusLine(location: String, score: Int, moves: Int) {
        // We can optionally capture status line updates for testing
        capturedOutput.append("STATUS: \(location) | Score: \(score) | Moves: \(moves)")
    }

    public func getInput(prompt: String = "> ") -> String? {
        guard inputIndex < inputResponses.count else {
            return ""
        }

        let response = inputResponses[inputIndex]
        inputIndex += 1
        return response
    }

    public func shutdown() {
        // Nothing to clean up
    }
}
