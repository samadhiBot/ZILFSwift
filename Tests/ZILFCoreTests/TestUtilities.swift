import Foundation
@testable import ZILFCore

/// Test output handler that stores output for verification
public class OutputCapture {
    public var output = ""

    public init() {}

    // Function that conforms to GameEngine's expected (String) -> Void type
    public lazy var handler: (String) -> Void = { [weak self] text in
        self?.output += text + "\n"
    }

    public func clear() {
        output = ""
    }
}
