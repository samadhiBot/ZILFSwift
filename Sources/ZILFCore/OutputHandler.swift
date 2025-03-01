// Protocol for handling output from the game engine
public protocol OutputHandler {
    func output(_ text: String, terminator: String)
    func output(_ text: String)
}

// Default implementation that prints to stdout
public class StandardOutputHandler: OutputHandler {
    public init() {}

    public func output(_ text: String, terminator: String) {
        print(text, terminator: terminator)
    }

    public func output(_ text: String) {
        output(text, terminator: "\n")
    }
}
