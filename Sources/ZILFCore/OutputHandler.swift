import Foundation

/// Protocol defining how text output from the game engine should be handled.
///
/// The `OutputHandler` protocol allows for different output mechanisms to be
/// used with the game engine, such as standard console output, a custom UI,
/// or logging to a file.
public protocol OutputHandler {
    /// Outputs text with a specified terminator string.
    /// - Parameters:
    ///   - text: The text to output.
    ///   - terminator: The string to append after the text.
    func output(_ text: String, terminator: String)

    /// Outputs text with a default line terminator.
    /// - Parameter text: The text to output.
    func output(_ text: String)
}

/// Standard implementation of `OutputHandler` that prints to the console.
///
/// This handler uses Swift's `print` function to display output to the standard
/// output stream (typically the console).
public class StandardOutputHandler: OutputHandler {
    /// Initializes a new standard output handler.
    public init() {}

    /// Outputs text to the console with the specified terminator.
    /// - Parameters:
    ///   - text: The text to output.
    ///   - terminator: The string to append after the text.
    public func output(_ text: String, terminator: String) {
        print(text, terminator: terminator)
    }

    /// Outputs text to the console with a newline terminator.
    /// - Parameter text: The text to output.
    public func output(_ text: String) {
        output(text, terminator: "\n")
    }
}
