//
//  GameModel.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation

// Game objects (rooms, items, etc.)
@dynamicMemberLookup
public class GameObject {
    public var capacity: Int = -1  // -1 means unlimited capacity
    public var contents: [GameObject] = []
    public var description: String
    public var flags: Set<String> = []
    public var location: GameObject?
    public var name: String
    internal var stateValues: [String: Any] = [:]

    public init(name: String, description: String, location: GameObject? = nil) {
        self.name = name
        self.description = description
        if let location = location {
            self.location = location
            location.contents.append(self)
        }
    }

    public func isIn(_ obj: GameObject) -> Bool {
        var current = self.location
        while let loc = current {
            if loc === obj {
                return true
            }
            current = loc.location
        }
        return false
    }

    public func hasFlag(_ flag: String) -> Bool {
        return flags.contains(flag)
    }

    public func setFlag(_ flag: String) {
        flags.insert(flag)
    }

    public func clearFlag(_ flag: String) {
        flags.remove(flag)
    }

    public func isContainer() -> Bool {
        return hasFlag("container")
    }

    public func isOpen() -> Bool {
        return hasFlag("open")
    }

    public func isOpenable() -> Bool {
        return hasFlag("openable")
    }

    public func canSeeInside() -> Bool {
        return isContainer() && (isOpen() || hasFlag("transparent"))
    }

    public func open() -> Bool {
        if isContainer() && isOpenable() && !isOpen() {
            setFlag("open")
            return true
        }
        return false
    }

    public func close() -> Bool {
        if isContainer() && isOpenable() && isOpen() {
            clearFlag("open")
            return true
        }
        return false
    }

    public func addToContainer(_ obj: GameObject) -> Bool {
        if isContainer() && isOpen() {
            // Check capacity if it's limited
            if capacity >= 0 && contents.count >= capacity {
                return false
            }

            // Remove from current location
            if let loc = obj.location, let index = loc.contents.firstIndex(where: { $0 === obj }) {
                loc.contents.remove(at: index)
            }

            // Add to this container
            obj.location = self
            contents.append(obj)
            return true
        }
        return false
    }

    // MARK: - State Management

    /// Set a state value for this object
    /// - Parameters:
    ///   - value: The value to store
    ///   - key: The key to store it under
    public func setState<T>(_ value: T, forKey key: String) {
        stateValues[key] = value
    }

    /// Get a state value for this object
    /// - Parameter key: The key to retrieve
    /// - Returns: The stored value, or nil if not found
    public func getState<T>(forKey key: String) -> T? {
        return stateValues[key] as? T
    }

    /// Check if a boolean state is true
    /// - Parameter key: The key to check
    /// - Returns: The boolean value, or false if not set
    public func hasState(_ key: String) -> Bool {
        return getState(forKey: key) ?? false
    }

    /// Dynamic member lookup subscript for getting state values with nice syntax
    public subscript<T>(dynamicMember key: String) -> T? {
        return getState(forKey: key)
    }

    /// Dynamic member lookup subscript for setting state values with nice syntax
    public subscript<T>(dynamicMember key: String) -> T {
        get {
            guard let value: T = getState(forKey: key) else {
                fatalError("State value for key '\(key)' does not exist or cannot be converted to type \(T.self)")
            }
            return value
        }
        set { setState(newValue, forKey: key) }
    }
}

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

// Directions for room connections
public enum Direction: String, CaseIterable {
    case north, south, east, west, up, down

    // Support common abbreviations
    public static func from(string: String) -> Direction? {
        switch string.lowercased() {
        case "n", "north": return .north
        case "s", "south": return .south
        case "e", "east": return .east
        case "w", "west": return .west
        case "u", "up": return .up
        case "d", "down": return .down
        default: return nil
        }
    }

    // Opposite direction - useful for two-way connections
    public var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        case .up: return .down
        case .down: return .up
        }
    }
}

// Player representation
public class Player: GameObject {
    public init(startingRoom: Room) {
        super.init(name: "player", description: "As good-looking as ever.")
        self.location = startingRoom
        startingRoom.contents.append(self)
    }

    public var currentRoom: Room? {
        return location as? Room
    }

    public func move(direction: Direction) -> Bool {
        guard let currentRoom = self.currentRoom else {
            return false
        }

        // First check if there's a special exit in this direction
        if let specialExit = currentRoom.getSpecialExit(direction: direction) {
            // Check if the exit condition passes
            if specialExit.checkCondition() {
                // Display success message if there is one
                if let successMessage = specialExit.successMessage {
                    print(successMessage)
                }

                // Execute onTraverse action if there is one
                specialExit.executeTraverse()

                // Move the player to the destination
                let destination = specialExit.destination

                // Remove from old room
                if let index = currentRoom.contents.firstIndex(where: { $0 === self }) {
                    currentRoom.contents.remove(at: index)
                }

                // Add to new room
                self.location = destination
                destination.contents.append(self)

                // Trigger the room's enter action
                destination.executeEnterAction()

                return true
            } else {
                // Display failure message if there is one
                if let failureMessage = specialExit.failureMessage {
                    print(failureMessage)
                }
                return false
            }
        }

        // If no special exit, use the regular exit
        guard let newRoom = currentRoom.getExit(direction: direction) else {
            return false
        }

        // Remove from old room
        if let index = currentRoom.contents.firstIndex(where: { $0 === self }) {
            currentRoom.contents.remove(at: index)
        }

        // Add to new room
        self.location = newRoom
        newRoom.contents.append(self)

        // Trigger the room's enter action
        newRoom.executeEnterAction()

        return true
    }
}

// GameWorld contains all game objects and state
public class GameWorld {
    public var rooms: [Room] = []
    public var objects: [GameObject] = []
    public var player: Player
    public var lastMentionedObject: GameObject?
    public let eventManager = EventManager()

    public init(player: Player) {
        self.player = player
    }

    public func registerRoom(_ room: Room) {
        rooms.append(room)
    }

    public func registerObject(_ object: GameObject) {
        objects.append(object)
    }

    /// Schedule an event to run after a number of turns
    public func queueEvent(name: String, turns: Int, action: @escaping () -> Bool) {
        eventManager.scheduleEvent(name: name, turns: turns, action: action)
    }

    /// Cancel a scheduled event
    public func dequeueEvent(named name: String) -> Bool {
        return eventManager.dequeueEvent(named: name)
    }

    /// Check if an event is scheduled for this turn
    public func isEventRunning(named name: String) -> Bool {
        return eventManager.isEventRunningThisTurn(named: name)
    }

    /// Checks if an event is in the queue at all (this turn or future turns)
    public func isEventScheduled(named name: String) -> Bool {
        // Use the direct method from EventManager instead of parsing event strings
        return eventManager.isEventScheduled(named: name)
    }

    /// Waits for a specified number of turns or until an event or room action produces output
    /// This is similar to the WAIT-TURNS routine in ZIL
    /// - Parameter turns: The number of turns to wait
    /// - Returns: True if the wait was interrupted by something producing output
    public func waitTurns(_ turns: Int) -> Bool {
        var turnCount = 0
        var outputProduced = false

        while turnCount < turns && !outputProduced {
            // Process room end-of-turn action first
            if let room = player.currentRoom {
                let roomOutput = room.executeEndTurnAction()
                outputProduced = roomOutput
            }

            // Process events for this turn if no output was produced by the room
            if !outputProduced {
                let eventsOutput = eventManager.processEvents()
                outputProduced = eventsOutput
            }

            turnCount += 1
        }

        return outputProduced
    }
}
