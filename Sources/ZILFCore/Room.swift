import Foundation

/// Represents a location in the game world that the player can visit.
///
/// A `Room` is a specialized `GameObject` that maintains connections to other rooms
/// via exits in different directions. Rooms can have various action handlers that
/// trigger at specific phases during gameplay.
public class Room: GameObject {
    /// Defines the possible action phases for room-specific behavior.
    public enum ActionPhase {
        /// Beginning of turn, before command processing (M-BEG in ZIL).
        case beginTurn

        /// End of turn (M-END in ZIL).
        case endTurn

        /// When a player enters this room (M-ENTER in ZIL).
        case enter

        /// When important room details should be shown even in brief mode (M-FLASH in ZIL).
        case flash

        /// When looking at the room (M-LOOK in ZIL).
        case look

        /// When a specific command is being processed.
        case command(Command)
    }

    /// Called at the beginning of processing a command while in this room.
    /// - Returns: `true` if the action handled the command (prevents further processing).
    public var beginCommandAction: ((Room, Command) -> Bool)?

    /// Called at the beginning of the turn, before any command processing (M-BEG in ZIL).
    /// - Returns: `true` if the action produced output or handled the command.
    public var beginTurnAction: ((Room) -> Bool)?

    /// Called at the end of each turn while the player is in this room.
    /// - Returns: `true` if the action produced output to display.
    public var endTurnAction: ((Room) -> Bool)?

    /// Called when a player enters this room.
    /// - Returns: `true` if the action produced output to display.
    public var enterAction: ((Room) -> Bool)?

    /// Dictionary of exits mapping directions to destination rooms.
    public var exits: [Direction: Room] = [:]

    /// Called when the room should show important details even in brief mode (M-FLASH in ZIL).
    /// - Returns: `true` if the action produced output.
    public var flashAction: ((Room) -> Bool)?

    /// Called when the room is being looked at (M-LOOK in ZIL).
    /// - Returns: `true` if the action produced a description (prevents default description).
    public var lookAction: ((Room) -> Bool)?
    
    /// Whether the room is currently lit.
    public var isLit: Bool {
        hasFlag(.isOn) || hasFlag(.isNaturallyLit)
    }

    /// Executes the begin-command action for this room.
    /// - Parameter command: The command to process.
    /// - Returns: `true` if the action handled the command.
    public func executeBeginCommandAction(command: Command) -> Bool {
        guard let action = beginCommandAction else { return false }
        return action(self, command)
    }

    /// Executes the begin-turn action for this room (before command processing).
    /// - Returns: `true` if the action produced output.
    public func executeBeginTurnAction() -> Bool {
        guard let action = beginTurnAction else { return false }
        return action(self)
    }

    /// Executes the end-of-turn action for this room.
    /// - Returns: `true` if the action produced output.
    public func executeEndTurnAction() -> Bool {
        guard let action = endTurnAction else { return false }
        return action(self)
    }

    /// Executes the enter action for this room.
    /// - Returns: `true` if the action produced output.
    public func executeEnterAction() -> Bool {
        guard let action = enterAction else { return false }
        return action(self)
    }

    /// Executes a specific action phase for this room.
    /// - Parameter phase: The action phase to execute.
    /// - Returns: `true` if the action produced output or handled a command.
    public func executePhase(_ phase: ActionPhase) -> Bool {
        switch phase {
        case .beginTurn:
            return executeBeginTurnAction()
        case .endTurn:
            return executeEndTurnAction()
        case .enter:
            return executeEnterAction()
        case .look:
            return executeLookAction()
        case .flash:
            return executeFlashAction()
        case .command(let command):
            return executeBeginCommandAction(command: command)
        }
    }

    /// Executes the flash action for this room (important details even in brief mode).
    /// - Returns: `true` if the action produced output.
    public func executeFlashAction() -> Bool {
        guard let action = flashAction else { return false }
        return action(self)
    }

    /// Executes the look action for this room.
    /// - Returns: `true` if the action provided a description.
    public func executeLookAction() -> Bool {
        guard let action = lookAction else { return false }
        return action(self)
    }

    /// Gets the room connected to this room in the specified direction.
    /// - Parameter direction: The direction to check.
    /// - Returns: The connected room, or `nil` if no exit exists in that direction.
    public func getExit(direction: Direction) -> Room? {
        return exits[direction]
    }

    /// Creates an exit from this room to another room in the specified direction.
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - room: The destination room.
    public func setExit(direction: Direction, room: Room) {
        exits[direction] = room
    }
}
