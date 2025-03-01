// Room is a specialized GameObject
public class Room: GameObject {
    public var exits: [Direction: Room] = [:]

    // Define the possible room action phases
    public enum ActionPhase {
        /// Beginning of turn, before command processing (M-BEG in ZIL)
        case beginTurn
        /// End of turn (M-END in ZIL)
        case endTurn
        /// When a player enters this room (M-ENTER in ZIL)
        case enter
        /// When looking at the room (M-LOOK in ZIL)
        case look
        /// When important room details should be shown even in brief mode (M-FLASH in ZIL)
        case flash
        /// When a specific command is being processed
        case command(Command)
    }

    // Action handlers for different phases
    /// Called when a player enters this room
    /// - Returns: true if the action produced output to display
    public var enterAction: ((Room) -> Bool)?

    /// Called at the end of each turn while the player is in this room
    /// - Returns: true if the action produced output to display
    public var endTurnAction: ((Room) -> Bool)?

    /// Called at the beginning of processing a command while in this room
    /// - Returns: true if the action handled the command (prevents further processing)
    public var beginCommandAction: ((Room, Command) -> Bool)?

    /// Called at the beginning of the turn, before any command processing (M-BEG in ZIL)
    /// - Returns: true if the action produced output or handled the command
    public var beginTurnAction: ((Room) -> Bool)?

    /// Called when the room is being looked at (M-LOOK in ZIL)
    /// - Returns: true if the action produced a description (prevents default description)
    public var lookAction: ((Room) -> Bool)?

    /// Called when the room should show important details even in brief mode (M-FLASH in ZIL)
    /// - Returns: true if the action produced output
    public var flashAction: ((Room) -> Bool)?

    public init(name: String, description: String) {
        super.init(name: name, description: description)
    }

    public func setExit(direction: Direction, room: Room) {
        exits[direction] = room
    }

    public func getExit(direction: Direction) -> Room? {
        return exits[direction]
    }

    /// Execute the enter action for this room
    /// - Returns: true if the action produced output
    public func executeEnterAction() -> Bool {
        guard let action = enterAction else { return false }
        return action(self)
    }

    /// Execute the end-of-turn action for this room
    /// - Returns: true if the action produced output
    public func executeEndTurnAction() -> Bool {
        guard let action = endTurnAction else { return false }
        return action(self)
    }

    /// Execute the begin-command action for this room
    /// - Parameter command: The command to process
    /// - Returns: true if the action handled the command
    public func executeBeginCommandAction(command: Command) -> Bool {
        guard let action = beginCommandAction else { return false }
        return action(self, command)
    }

    /// Execute the begin-turn action for this room (before command processing)
    /// - Returns: true if the action produced output
    public func executeBeginTurnAction() -> Bool {
        guard let action = beginTurnAction else { return false }
        return action(self)
    }

    /// Execute the look action for this room
    /// - Returns: true if the action provided a description
    public func executeLookAction() -> Bool {
        guard let action = lookAction else { return false }
        return action(self)
    }

    /// Execute the flash action for this room (important details even in brief mode)
    /// - Returns: true if the action produced output
    public func executeFlashAction() -> Bool {
        guard let action = flashAction else { return false }
        return action(self)
    }

    /// A generic phase handler that can handle any room action phase
    /// - Parameter phase: The action phase to execute
    /// - Returns: true if the action produced output or handled a command
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
}

// Make Room equatable by object identity
extension Room: Equatable {
    public static func == (lhs: Room, rhs: Room) -> Bool {
        return lhs === rhs
    }
}