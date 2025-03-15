import Foundation

public enum OutputMode {
    case standard
    case terminal
    case mock([String])  // For testing with predefined inputs
}

public class OutputManagerFactory {
    public static func create(mode: OutputMode) -> OutputManager {
        switch mode {
        case .standard:
            return StandardOutputManager()
        case .terminal:
            #if os(macOS) || os(Linux)
            return TerminalOutputManager()
            #else
            return StandardOutputManager()
            #endif
        case .mock(let inputs):
            return MockOutputManager(inputResponses: inputs)
        }
    }
}
