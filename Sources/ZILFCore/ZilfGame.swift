import Foundation

/// Protocol defining the core requirements for a game using the ZILF framework
///
/// Games implement this protocol to provide their content and logic to the engine.
public protocol ZilfGame {
    /// Welcome text displayed when the game starts
    var welcomeText: String { get }

    /// Version and authorship information
    var versionInfo: String { get }

    /// Creates the game world including rooms, objects, and player
    /// - Returns: A fully set up game world
    func createWorld() -> GameWorld

    /// Optional method to handle custom commands not recognized by the standard parser
    /// - Parameter command: The custom command to handle
    /// - Returns: True if the command was handled, false otherwise
    func handleCustomCommand(_ command: Command) -> Bool
}

// Default implementation
extension ZilfGame {
    public func handleCustomCommand(_ command: Command) -> Bool {
        return false
    }
}
