import Foundation

/// `GameWorld` manages the complete game state, including all rooms,
/// objects, and the player. It serves as the central coordination point
/// for game events and state changes.
public class GameWorld {
    /// All rooms available in the game world.
    public private(set) var rooms = [Room]()

    /// Objects that exist in specific locations within the game world.
    public private(set) var objects = [GameObject]()

    /// Objects that are accessible from anywhere in the game world.
    public private(set) var globalObjects = [GameObject]()

    /// The player character and its state.
    public let player: Player

    /// Tracks the most recently referenced object in player commands.
    public var lastMentionedObject: GameObject?

    /// Manages scheduled events that occur after specific numbers of turns.
    public let eventManager = EventManager()

    /// Creates a new game world with the specified player.
    ///
    /// - Parameter player: The player character for this game world.
    public init(player: Player) {
        self.player = player
        player.setWorld(to: self)
    }
    
    /// <#Description#>
    public enum RegistrationType {
        case object
        case room
        case global
    }
    /// Adds an object to the game world.
    ///
    /// - Parameter object: The object to register.
    public func register(
        _ object: GameObject,
        _ type: RegistrationType? = nil
    ) {
        switch type {
        case .object:
            objects.append(object)
        case .room:
            guard let room = object as? Room else {
                assert(false, "Attempted to register \(object) as a room")
                return
            }
            rooms.append(room)
        case .global:
            globalObjects.append(object)
        case nil:
            if let room = object as? Room {
                rooms.append(room)
            } else {
                objects.append(object)
            }
        }

        object.setWorld(to: self)
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
        eventManager.dequeueEvent(named: name)
    }

    /// Checks if an event is scheduled to run on the current turn.
    /// - Parameter name: The unique identifier of the event to check.
    /// - Returns: `true` if the event is scheduled for the current turn.
    public func isEventRunning(named name: String) -> Bool {
        eventManager.isEventRunningThisTurn(named: name)
    }

    /// Checks if an event is in the queue for any future turn.
    /// - Parameter name: The unique identifier of the event to check.
    /// - Returns: `true` if the event is scheduled for any future turn.
    public func isEventScheduled(named name: String) -> Bool {
        eventManager.isEventScheduled(named: name)
    }
    
    /// Outputs a message through the configured console.
    ///
    /// - Parameter message: The message to output.
    public func output(_ message: String) {
        if let engine = player.engine {
            engine.output("\(message)\n")
        } else {
            print("❗ \(message)\n")
        }
    }

    /// Outputs an error message through the configured console.
    ///
    /// - Parameter message: The error message to output.
    func error(_ message: String) {
        if let engine = player.engine {
            engine.error("\(message)\n")
        } else {
            print("❗💥 \(message)\n")
        }
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

// MARK: - Finders

extension GameWorld {
    enum NotFound: Error {
        case objectNotFound(String)
        case roomNotFound(String)
    }

    public func find(_ object: String) throws -> GameObject {
        if let object = objects.first(where: { $0.name == object }) {
            return object
        }
        if let globalObject = globalObjects.first(where: { $0.name == object }) {
            return globalObject
        }
        throw NotFound.objectNotFound(object)
    }

    /// Helper function to get a room by name from the world
    public func find(room: String) throws -> Room {
        guard let room = rooms.first(where: { $0.name == room }) else {
            throw NotFound.roomNotFound(room)
        }
        return room
    }
}

// MARK: - Global objects

public extension GameWorld {
    /// Register an object as a global object.
    ///
    /// - Parameters:
    ///   - object: The object to register as global.
    ///   - isLocalGlobal: Whether this is a local-global (false = global).
    func registerGlobalObject(_ object: GameObject, isLocalGlobal: Bool = false) {
        // First make sure it's not already registered
        guard !globalObjects.contains(where: { $0 === object }) else {
            return
        }

        // Add to global objects list
        register(object, .global)

        // Mark the object with its global type
        let typeValue = isLocalGlobal ? String.localGlobalObject : String.globalObject
        object.setState(typeValue, forKey: String.globalObjectType)
    }

    /// Get all global objects of a specific type.
    ///
    /// - Parameter localGlobal: Whether to get local-globals (nil = all global types).
    /// - Returns: Array of global objects of the specified type.
    func getGlobalObjects(localGlobal: Bool? = nil) -> [GameObject] {
        globalObjects.filter { object in
            let objectType: String? = object.getState(forKey: .globalObjectType)
            if let objectType {
                if let isLocalGlobal = localGlobal {
                    let targetType = isLocalGlobal ? String.localGlobalObject : String.globalObject
                    return objectType == targetType
                }
                return true
            }
            return false
        }
    }

    /// Check if a global object is accessible in a specific room.
    ///
    /// - Parameters:
    ///   - object: The object to check.
    ///   - room: The room to check.
    /// - Returns: True if the object is accessible in this room.
    func isGlobalObjectAccessible(_ object: GameObject, in room: Room) -> Bool {
        // Get the object's global type
        let objectType: String? = object.getState(forKey: .globalObjectType)
        guard let objectType = objectType else {
            return false
        }

        if objectType == String.globalObject {
            // Global objects are accessible from anywhere
            return true
        } else if objectType == String.localGlobalObject {
            // Local-global objects are only accessible from rooms that list them
            let accessibleRooms: [Room]? = object.getState(forKey: "accessibleRooms")
            return accessibleRooms?.contains(room) ?? false
        }

        return false
    }
}
