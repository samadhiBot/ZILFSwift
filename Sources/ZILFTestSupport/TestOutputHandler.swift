import Foundation
@testable import ZILFCore

/// Output handler for tests - captures text instead of printing it
public class TestOutputHandler: OutputHandler {
    public var output = ""

    public init() {}

    public func output(_ text: String, terminator: String) {
        output += text + terminator
    }

    public func output(_ text: String) {
        output(text, terminator: "\n")
    }

    public func clear() {
        output = ""
    }
}
