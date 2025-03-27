import Foundation

/// `GameWorld` manages the complete game state, including all rooms,
/// objects, and the player. It serves as the central coordination point
/// for game events and state changes.
public class GameWorld {
    /// All rooms available in the game world.
    public private(set) var rooms = [Room]()

    /// Objects that exist in specific locations within the game world.
    public private(set) var objects = [GameObject]()

    /// The player character and its state.
    public let player: Player

    /// Manages scheduled events that occur after specific numbers of turns.
    public let eventManager = EventManager()

    /// Tracks the most recently referenced object in player commands.
    var lastMentionedObject: GameObject?

    /// Creates a new game world with the specified player.
    ///
    /// Also adds the player's starting room to the world if not already added.
    ///
    /// - Parameter player: The player character for this game world.
    public init(player: Player) throws {
        self.player = player
        player.setWorld(to: self)
        if let currentRoom = player.currentRoom, !rooms.contains(currentRoom) {
            try add(currentRoom)
        }
    }
}

// MARK: - Adding Rooms

extension GameWorld {
    /// Adds a room to the game world.
    ///
    /// - Parameter room: The room to add.
    /// - Returns: The added room.
    @discardableResult
    public func add(_ room: Room) throws -> Room {
        guard !rooms.contains(room) else {
            throw Error.duplicateRoomAdded(room.id)
        }
        rooms.append(room)
        return room
    }

    /// Adds a collection of rooms to the game world.
    ///
    /// - Parameter rooms: The rooms to add.
    public func add(_ rooms: Room...) throws {
        for room in rooms {
            try add(room)
        }
    }
}

// MARK: - Inserting Objects

extension GameWorld {
    /// Inserts an object into a location in the game world.
    ///
    /// - Parameters:
    ///   - objects: The object to insert.
    ///   - locations: The location(s) where the object goes.
    /// - Returns: The inserted object.
    @discardableResult
    public func insert(
        _ object: GameObject,
        in locations: Room...
    ) throws -> GameObject {
        try insert(object: object, locations: locations)
    }

    /// Inserts a collection of objects into a location in the game world.
    ///
    /// - Parameters:
    ///   - objects: The objects to insert.
    ///   - locations: The location(s) where the objects go.
    public func insert(
        _ objects: GameObject...,
        in locations: Room...
    ) throws {
        for object in objects {
            _ = try insert(object: object, locations: locations)
        }
    }

    /// Inserts an object into a container in the game world.
    ///
    /// - Parameters:
    ///   - object: The object to insert.
    ///   - container: <#container description#>
    /// - Returns: The inserted object.
    @discardableResult
    public func insert(
        _ object: GameObject,
        into container: GameObject
    ) throws -> GameObject {
        guard !objects.contains(object) else {
            throw Error.cannotInsertObjectMultipleTimes(object.id)
        }
        switch object.type {
        case .global: throw Error.cannotInsertGlobalInContainer(object.id)
        case .localGlobal: throw Error.cannotInsertLocalGlobalInContainer(object.id)
        case .player: throw Error.cannotInsertPlayer(object.id)
        case .room: throw Error.cannotInsertRoom(object.id)
        default: break
        }
        objects.append(object)
        object.moveTo(container)
        object.setWorld(to: self)
        return object
    }

    private func insert(
        object: GameObject,
        locations: [Room]
    ) throws -> GameObject {
        guard !objects.contains(object) else {
            throw Error.cannotInsertObjectMultipleTimes(object.id)
        }
        switch object.type {
        case .global:
            guard locations.isEmpty else {
                throw Error.cannotInsertGlobalInLocation(object.id)
            }
        case .localGlobal:
            guard locations.count > 1 else {
                throw Error.localGlobalRequiresMultipleLocations(object.id)
            }
            object.setType(to: .localGlobal(locations.map(\.id)))
        case .object:
            switch locations.count {
            case 0: object.setType(to: .global)
            case 1: object.moveTo(locations[0])
            default: object.setType(to: .localGlobal(locations.map(\.id)))
            }
        case .player: throw Error.cannotInsertPlayer(object.id)
        case .room: throw Error.cannotInsertRoom(object.id)
        }
        objects.append(object)
        object.setWorld(to: self)
        return object
    }
}

// MARK: - Managing Events

extension GameWorld {
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

    /// Advances the game state by a specified number of turns, or until an event or room action
    /// produces output.
    ///
    /// - Parameter turns: The maximum number of turns to wait.
    /// - Returns: `true` if the wait was interrupted by something producing output, or `false`
    ///            if all turns elapsed with no output.
    public func waitTurns(_ turns: Int) throws -> Bool {
        var turnCount = 0
        var outputProduced = false

        while turnCount < turns && !outputProduced {
            // Process room end-of-turn action first
            if let room = player.currentRoom {
                let roomOutput = try room.executeEndTurnAction()
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

// MARK: - Helpers

extension GameWorld {
    /// Finds an object in the world by its `id`.
    ///
    /// - Parameter object: The object's `id`.
    /// - Returns: The found object.
    /// - Throws: When an object cannot be found.
    public func find(_ id: GameObject.ID) throws -> GameObject {
        guard let found = objects.first(where: { $0.id == id }) else {
            throw Error.objectNotFound(id)
        }
        return found
    }

    /// Finds a room in the world by its `id`.
    ///
    /// - Parameter room: The room's `id`.
    /// - Returns: The found room.
    /// - Throws: When a room cannot be found.
    public func find(room id: GameObject.ID) throws -> Room {
        guard
            let found = rooms.first(where: { $0.id == id })
        else {
            throw Error.roomNotFound(id)
        }
        return found
    }

    /// Outputs a message through the configured console.
    ///
    /// - Parameter message: The message to output.
    public func output(_ message: String) throws {
        guard let engine = player.engine else {
            throw Error.engineNotFound(output: message)
        }
        engine.output("\(message)\n")
    }
}

//public extension GameWorld {
//    /// Register an object as a global object.
//    ///
//    /// - Parameters:
//    ///   - object: The object to register as global.
//    ///   - isLocalGlobal: Whether this is a local-global (false = global).
//    func registerGlobalObject(_ object: GameObject, isLocalGlobal: Bool = false) {
//        // First make sure it's not already registered
//        guard !globalObjects.contains(where: { $0 === object }) else {
//            return
//        }
//
//        // Add to global objects list
//        register(object, .global)
//
//        // Mark the object with its global type
//        let typeValue = isLocalGlobal ? String.localGlobalObject : String.globalObject
//        object.setState(typeValue, forKey: String.globalObjectType)
//    }
//
//    /// Get all global objects of a specific type.
//    ///
//    /// - Parameter localGlobal: Whether to get local-globals (nil = all global types).
//    /// - Returns: Array of global objects of the specified type.
//    func getGlobalObjects(localGlobal: Bool? = nil) -> [GameObject] {
//        globalObjects.filter { object in
//            let objectType: String? = object.getState(forKey: .globalObjectType)
//            if let objectType {
//                if let isLocalGlobal = localGlobal {
//                    let targetType: String = isLocalGlobal ? .localGlobalObject : .globalObject
//                    return objectType == targetType
//                }
//                return true
//            }
//            return false
//        }
//    }
//
//    /// Check if a global object is accessible in a specific room.
//    ///
//    /// - Parameters:
//    ///   - object: The object to check.
//    ///   - room: The room to check.
//    /// - Returns: True if the object is accessible in this room.
//    func isGlobalObjectAccessible(_ object: GameObject, in room: Room) -> Bool {
//        // Get the object's global type
//        let objectType: String? = object.getState(forKey: .globalObjectType)
//        guard let objectType = objectType else {
//            return false
//        }
//
//        if objectType == String.globalObject {
//            // Global objects are accessible from anywhere
//            return true
//        } else if objectType == String.localGlobalObject {
//            // Local-global objects are only accessible from rooms that list them
//            let accessibleRooms: [Room]? = object.getState(forKey: .accessibleRooms)
//            return accessibleRooms?.contains(room) ?? false
//        }
//
//        return false
//    }
//}

// MARK: - GameWorld.Error

extension GameWorld {
    enum Error: Swift.Error {
        case cannotInsertGlobalInContainer(GameObject.ID)
        case cannotInsertGlobalInLocation(GameObject.ID)
        case cannotInsertLocalGlobalInContainer(GameObject.ID)
        case cannotInsertObjectMultipleTimes(GameObject.ID)
        case cannotInsertPlayer(GameObject.ID)
        case cannotInsertRoom(GameObject.ID)
        case duplicateRoomAdded(GameObject.ID)
        case localGlobalRequiresMultipleLocations(GameObject.ID)
        case engineNotFound(output: String)
        case objectNotFound(GameObject.ID)
        case roomNotFound(GameObject.ID)
    }
}
