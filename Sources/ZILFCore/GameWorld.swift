import Foundation

/// `GameWorld` manages the complete game state, including all rooms,
/// objects, and the player. It serves as the central coordination point
/// for game events and state changes.
public class GameWorld {
    /// All rooms available in the game world.
    public var rooms: [Room] = []

    /// Objects that exist in specific locations within the game world.
    public var objects: [GameObject] = []

    /// Objects that are accessible from anywhere in the game world.
    public var globalObjects: [GameObject] = []

    /// The player character and its state.
    public var player: Player

    /// Tracks the most recently referenced object in player commands.
    public var lastMentionedObject: GameObject?

    /// Manages scheduled events that occur after specific numbers of turns.
    public let eventManager = EventManager()

    /// Creates a new game world with the specified player.
    /// - Parameter player: The player character for this game world.
    public init(player: Player) {
        self.player = player
        // Set the player's world reference directly
        player.setWorld(self)
    }

    /// Adds an object to the game world.
    /// - Parameter object: The object to register.
    public func register(_ object: GameObject) {
        objects.append(object)
    }

    /// Adds a room to the game world.
    /// - Parameter room: The room to register.
    public func register(room: Room) {
        rooms.append(room)
    }

    /// Schedules an event to run after a specified number of turns.
    /// - Parameters:
    ///   - name: A unique identifier for the event.
    ///   - turns: The number of turns to wait before executing the event.
    ///   - action: The action to perform when the event triggers. Should return `true`
    ///     if the event produced output.
    public func queueEvent(name: String, turns: Int, action: @escaping () -> Bool) {
        eventManager.scheduleEvent(name: name, turns: turns, action: action)
    }

    /// Cancels a previously scheduled event.
    /// - Parameter name: The unique identifier of the event to cancel.
    /// - Returns: `true` if an event was found and canceled, `false` otherwise.
    public func dequeueEvent(named name: String) -> Bool {
        return eventManager.dequeueEvent(named: name)
    }

    /// Checks if an event is scheduled to run on the current turn.
    /// - Parameter name: The unique identifier of the event to check.
    /// - Returns: `true` if the event is scheduled for the current turn.
    public func isEventRunning(named name: String) -> Bool {
        return eventManager.isEventRunningThisTurn(named: name)
    }

    /// Checks if an event is in the queue for any future turn.
    /// - Parameter name: The unique identifier of the event to check.
    /// - Returns: `true` if the event is scheduled for any future turn.
    public func isEventScheduled(named name: String) -> Bool {
        return eventManager.isEventScheduled(named: name)
    }

    /// Advances the game state by a specified number of turns, or until
    /// an event or room action produces output.
    /// - Parameter turns: The maximum number of turns to wait.
    /// - Returns: `true` if the wait was interrupted by something producing output,
    ///   `false` if all turns elapsed with no output.
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

extension GameWorld {
    enum NotFound: Error {
        case objectNotFound(String)
        case roomNotFound(String)
    }

    public func find(object name: String) throws -> GameObject {
        guard let object = objects.first(where: { $0.name == name }) else {
            throw NotFound.objectNotFound(name)
        }
        return object
    }

    /// Helper function to get a room by name from the world
    public func find(room name: String) throws -> Room {
        guard let room = rooms.first(where: { $0.name == name }) else {
            throw NotFound.roomNotFound(name)
        }
        return room
    }
}
