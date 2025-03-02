import Foundation

/// Represents the possible actions a player can take in the game.
/// Each case encapsulates a specific command with its associated parameters.
public enum Command {
    /// Command to close a specific game object
    ///
    /// - Parameter GameObject: The object to be closed
    case close(GameObject)

    /// Command to drop an item from the player's inventory
    ///
    /// - Parameter GameObject: The object to be dropped
    case drop(GameObject)

    /// Command to examine or look at a specific game object in detail
    ///
    /// - Parameter GameObject: The object to be examined
    case examine(GameObject)

    /// Command to display the contents of the player's inventory
    case inventory

    /// Command to look around and observe the current location
    case look

    /// Command to move the player in a specific direction
    ///
    /// - Parameter Direction: The direction to move in
    case move(Direction)

    /// Command to open a specific game object
    ///
    /// - Parameter GameObject: The object to be opened
    case open(GameObject)

    /// Command to exit the game
    case quit

    /// Command to pick up a specific game object and add it to inventory
    ///
    /// - Parameter GameObject: The object to be taken
    case take(GameObject)

    /// Represents an unrecognized or invalid command
    ///
    /// - Parameter String: The original input text that wasn't recognized
    case unknown(String)

    /// A custom command for extended verb support
    ///
    /// - Parameters:
    ///   - verb: The verb string
    ///   - objects: Array of game objects involved in the command
    ///   - additionalData: Optional string data for the command (e.g., topics, text)
    case customCommand(String, [GameObject], additionalData: String? = nil)
}
