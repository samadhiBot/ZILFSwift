//
//  GameObject.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 3/1/25.
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

    // Add a proper typed gameWorld property
    public var gameWorld: GameWorld? {
        get { stateValues["gameWorld"] as? GameWorld }
        set { stateValues["gameWorld"] = newValue }
    }

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
    ///   - value: Value to store
    ///   - key: Key to store it under
    internal func setState<T>(_ value: T, forKey key: String) {
        stateValues[key] = value
    }

    /// Get a state value by key
    /// - Parameter key: Key to retrieve
    /// - Returns: The stored value, or nil if not found
    internal func getState<T>(forKey key: String) -> T? {
        return stateValues[key] as? T
    }

    /// Remove a state value for this object
    /// - Parameter key: Key to remove
    internal func removeState(forKey key: String) {
        stateValues.removeValue(forKey: key)
    }

    /// Check if a state key has a boolean true value
    /// - Parameter key: The key to check
    /// - Returns: True if the state exists and is true
    internal func hasState(_ key: String) -> Bool {
        getState(forKey: key) ?? false
    }

    /// Check if a property exists in the object's state dictionary
    /// - Parameter propertyName: The name of the property to check
    /// - Returns: True if the property exists
    public func hasProperty(_ propertyName: String) -> Bool {
        stateValues[propertyName] != nil
    }

    /// Dynamic member lookup subscript for getting and setting state values with nice syntax
    /// Always returns an optional value for safety
    public subscript<T>(dynamicMember key: String) -> T? {
        get {
            getState(forKey: key)
        }
        set {
            if let newValue = newValue {
                setState(newValue, forKey: key)
            } else {
                // If nil is assigned, remove the state
                removeState(forKey: key)
            }
        }
    }

    /// Provides access to a property existence check with the .isSet suffix
    /// Example: object.someProperty.isSet will return true if someProperty exists
    public subscript(dynamicMember key: String) -> PropertyExistenceChecker {
        PropertyExistenceChecker(object: self, key: key)
    }
}

/// Helper class to check if a property exists through the .isSet property
/// Example usage:
/// ```swift
/// // Check if a property exists
/// if object.someProperty.isSet {
///     // Property exists, now we can safely use it
///     let value = object.someProperty as? String
/// }
/// ```
public struct PropertyExistenceChecker {
    private let object: GameObject
    private let key: String

    internal init(object: GameObject, key: String) {
        self.object = object
        self.key = key
    }

    /// Returns true if the property exists in the object's state dictionary
    public var isSet: Bool {
        object.stateValues[key] != nil
    }
}

/// String constants for global object types
public extension String {
    /// Global object type accessible from anywhere
    static let globalObjectType = "global-object-type"

    /// Global object type value for global objects
    static let globalObject = "global"

    /// Global object type value for local-global objects
    static let localGlobalObject = "local-global"
}

/// Global objects extension for GameWorld
public extension GameWorld {
    /// Register an object as a global object
    /// - Parameters:
    ///   - object: The object to register as global
    ///   - isLocalGlobal: Whether this is a local-global (false = global)
    func registerGlobalObject(_ object: GameObject, isLocalGlobal: Bool = false) {
        // First make sure it's not already registered
        guard !globalObjects.contains(where: { $0 === object }) else {
            return
        }

        // Add to global objects list
        globalObjects.append(object)

        // Mark the object with its global type
        let typeValue = isLocalGlobal ? String.localGlobalObject : String.globalObject
        object.setState(typeValue, forKey: String.globalObjectType)
    }

    /// Get all global objects of a specific type
    /// - Parameter localGlobal: Whether to get local-globals (nil = all global types)
    /// - Returns: Array of global objects of the specified type
    func getGlobalObjects(localGlobal: Bool? = nil) -> [GameObject] {
        return globalObjects.filter { object in
            let objectType: String? = object.getState(forKey: String.globalObjectType)
            if let objectType = objectType {
                if let isLocalGlobal = localGlobal {
                    let targetType = isLocalGlobal ? String.localGlobalObject : String.globalObject
                    return objectType == targetType
                }
                return true
            }
            return false
        }
    }

    /// Check if a global object is accessible in a specific room
    /// - Parameters:
    ///   - object: The object to check
    ///   - room: The room to check
    /// - Returns: True if the object is accessible in this room
    func isGlobalObjectAccessible(_ object: GameObject, in room: Room) -> Bool {
        // Get the object's global type
        let objectType: String? = object.getState(forKey: String.globalObjectType)
        guard let objectType = objectType else {
            return false
        }

        if objectType == String.globalObject {
            // Global objects are accessible from anywhere
            return true
        } else if objectType == String.localGlobalObject {
            // Local-global objects are only accessible from rooms that list them
            let accessibleRooms: [Room]? = object.getState(forKey: "accessibleRooms")
            return accessibleRooms?.contains { $0 === room } ?? false
        }

        return false
    }
}

/// Room extension for managing local-global objects
public extension Room {
    /// Make a local-global object accessible from this room
    /// - Parameter object: The local-global object
    func addLocalGlobal(_ object: GameObject) {
        // Make sure the object is registered as a local-global
        let objectType: String? = object.getState(forKey: String.globalObjectType)

        if objectType == nil {
            // Register it as a local-global if not already registered
            let world: GameWorld? = getState(forKey: "world")
            if let world {
                world.registerGlobalObject(object, isLocalGlobal: true)
            }
        } else if objectType != String.localGlobalObject {
            // Cannot add a global object as a local-global
            return
        }

        // Add this room to the object's accessible rooms
        var accessibleRooms: [Room] = object.getState(forKey: "accessibleRooms") ?? []

        // Check if this room is already in the list
        if !accessibleRooms.contains(where: { $0 === self }) {
            accessibleRooms.append(self)
            object.setState(accessibleRooms, forKey: "accessibleRooms")
        }
    }

    /// Remove a local-global object's accessibility from this room
    /// - Parameter object: The local-global object
    func removeLocalGlobal(_ object: GameObject) {
        var accessibleRooms: [Room] = object.getState(forKey: "accessibleRooms") ?? []

        // Filter out this room
        accessibleRooms = accessibleRooms.filter { $0 !== self }
        object.setState(accessibleRooms, forKey: "accessibleRooms")
    }

    /// Get all local-global objects accessible from this room
    /// - Returns: Array of local-global objects accessible from this room
    func getAccessibleLocalGlobals() -> [GameObject] {
        let world: GameWorld? = getState(forKey: "world")
        guard let world = world else {
            return []
        }

        return world.getGlobalObjects(localGlobal: true).filter { object in
            let accessibleRooms: [Room]? = object.getState(forKey: "accessibleRooms")
            return accessibleRooms?.contains { $0 === self } ?? false
        }
    }
}

/// Extension for GameObject to handle global object functionality
public extension GameObject {
    /// Check if this object is a global object
    /// - Returns: True if this is a global object
    func isGlobalObject() -> Bool {
        let objectType: String? = getState(forKey: String.globalObjectType)
        return objectType != nil
    }

    /// Check if this object is a global object of a specific type
    /// - Parameter localGlobal: Whether to check for local-global (false = global)
    /// - Returns: True if this object is a global object of the specified type
    func isGlobalObject(localGlobal: Bool) -> Bool {
        let objectType: String? = getState(forKey: String.globalObjectType)
        let targetType = localGlobal ? String.localGlobalObject : String.globalObject
        return objectType == targetType
    }

    /// Get all rooms where this local-global object is accessible
    /// - Returns: Array of rooms where this object is accessible
    func getAccessibleRooms() -> [Room] {
        guard isGlobalObject(localGlobal: true) else {
            return []
        }

        let accessibleRooms: [Room]? = getState(forKey: "accessibleRooms")
        return accessibleRooms ?? []
    }
}

// Add moveTo functionality to GameObject
public extension GameObject {
    /// Move this object to a new location
    /// - Parameter destination: The new location
    func moveTo(destination: GameObject) {
        // Remove from current location if any
        if let currentLocation = location,
           let index = currentLocation.contents.firstIndex(where: { $0 === self }) {
            currentLocation.contents.remove(at: index)
        }

        // Update location and add to new container's contents
        location = destination
        destination.contents.append(self)
    }

    /// Get the inventory objects for an object
    var inventory: [GameObject] {
        return contents
    }

    /// Check if object is takeable
    func isTakeable() -> Bool {
        return hasFlag(.takeBit)
    }
}

// Add command handling extension to GameObject
public extension GameObject {
    /// Process a command against this game object, using its command handler if available
    /// - Parameter command: The command to process
    /// - Returns: True if the command was handled by this object
    func processCommand(_ command: Command) -> Bool {
        // Get the command handler using getState
        if let handler = stateValues["commandAction"] as? ((GameObject, Command) -> Bool) {
            return handler(self, command)
        }
        return false
    }

    /// Set a command handler for this game object
    /// - Parameter handler: The command handler function
    func setCommandHandler(_ handler: @escaping (GameObject, Command) -> Bool) {
        stateValues["commandAction"] = handler
    }

    /// Set a handler for the examine command
    /// - Parameter handler: The handler function that takes a GameObject and returns a Bool
    func setExamineHandler(_ handler: @escaping (GameObject) -> Bool) {
        let commandHandler: (GameObject, Command) -> Bool = { obj, command in
            if case .examine = command {
                return handler(obj)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set a handler for the take command
    /// - Parameter handler: The handler function that takes a GameObject and returns a Bool
    func setTakeHandler(_ handler: @escaping (GameObject) -> Bool) {
        let commandHandler: (GameObject, Command) -> Bool = { obj, command in
            if case .take = command {
                return handler(obj)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set a handler for the drop command
    /// - Parameter handler: The handler function that takes a GameObject and returns a Bool
    func setDropHandler(_ handler: @escaping (GameObject) -> Bool) {
        let commandHandler: (GameObject, Command) -> Bool = { obj, command in
            if case .drop = command {
                return handler(obj)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set a handler for a custom command
    /// - Parameters:
    ///   - verb: The verb to handle
    ///   - handler: The handler function that takes a GameObject and an array of objects and returns a Bool
    func setCustomCommandHandler(verb: String, handler: @escaping (GameObject, [GameObject]) -> Bool) {
        let commandHandler: (GameObject, Command) -> Bool = { obj, command in
            if case .customCommand(let cmdVerb, let objects, _) = command, cmdVerb == verb {
                return handler(obj, objects)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set handlers for multiple commands at once
    /// - Parameter handlers: Dictionary mapping command verbs to handler functions
    func setCommandHandlers(handlers: [String: (GameObject) -> Bool]) {
        var compositHandler: (GameObject, Command) -> Bool = { _, _ in false }

        for (verb, handler) in handlers {
            let previousHandler = compositHandler
            compositHandler = { obj, command in
                // First try the previous handlers
                if previousHandler(obj, command) {
                    return true
                }

                // Check if this is the command for this handler
                switch command {
                case .examine where verb == "examine":
                    return handler(obj)
                case .take where verb == "take":
                    return handler(obj)
                case .drop where verb == "drop":
                    return handler(obj)
                case .customCommand(let cmdVerb, _, _) where cmdVerb == verb:
                    return handler(obj)
                default:
                    return false
                }
            }
        }

        setCommandHandler(compositHandler)
    }

    /// Convenience method to set multiple flags at once
    /// - Parameter flags: The flags to set
    func setFlags(_ flags: String...) {
        for flag in flags {
            setFlag(flag)
        }
    }
}

// Convenience initializers for GameObject
public extension GameObject {
    /// Convenience initializer with location and flags
    /// - Parameters:
    ///   - name: The name of the object
    ///   - description: The description of the object
    ///   - location: The location of the object (optional)
    ///   - flags: Array of flags to set on the object
    convenience init(name: String, description: String, location: GameObject? = nil, flags: [String]) {
        self.init(name: name, description: description, location: location)
        for flag in flags {
            setFlag(flag)
        }
    }

    /// Convenience initializer with location and variadic flags
    /// - Parameters:
    ///   - name: The name of the object
    ///   - description: The description of the object
    ///   - location: The location of the object (optional)
    ///   - flags: Variadic list of flags to set on the object
    convenience init(name: String, description: String, location: GameObject? = nil, flags: String...) {
        self.init(name: name, description: description, location: location)
        for flag in flags {
            setFlag(flag)
        }
    }
}

// Extension to add player finding functionality to GameObject
public extension GameObject {
    /// Find the player by traversing up the object graph
    /// - Returns: The player object, or nil if not found
    func findPlayer() -> Player? {
        // Check if this object's location is a room
        if let room = location as? Room {
            // Try to find the player in this room
            return room.contents.first { $0 is Player } as? Player
        }

        // If this object is in another container, traverse up
        if let container = location {
            return container.findPlayer()
        }

        // Could not find player
        return nil
    }
}
