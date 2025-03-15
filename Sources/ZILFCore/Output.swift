import Foundation

/// Global output function that defaults to standard output but can be redirected
@MainActor public var globalOutput: (String) -> Void = { print($0) }

/// Sets the global output function
@MainActor public func setGlobalOutput(_ handler: @escaping (String) -> Void) {
    globalOutput = handler
}

/// Global function to output text through the current output handler
@MainActor public func output(_ message: String) {
    globalOutput(message)
}
