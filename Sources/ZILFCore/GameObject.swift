import Foundation

/// Represents any object in the game world including rooms, items, and characters.
/// Provides functionality for object relationships, state management, and interactions.
@dynamicMemberLookup
public class GameObject {
    /// The maximum number of objects this object can contain.
    public private(set) var capacity: Int?

    /// Any objects contained within this object.
    public private(set) var contents: [GameObject] = []

    /// The descriptive text for this object.
    public private(set) var description: String

    /// The set of flags that define object behaviors and states.
    public private(set) var flags: Set<String> = []

    /// The container that holds this object.
    public private(set) var location: GameObject?

    /// The identifier for this object.
    public var name: String

    /// A dictionary storing dynamic state values.
    var stateValues: [String: Any] = [:]

    // MARK: - Initialization

    /// Creates a new game object with name, description and optional location.
    ///
    /// - Parameters:
    ///   - name: The name of the object.
    ///   - description: The description of the object.
    ///   - location: The location of the object (optional).
    ///   - flags: Array of flags to set on the object.
    public init(
        name: String,
        description: String,
        location: GameObject? = nil,
        flags: [String] = []
    ) {
        self.name = name
        self.description = description
        self.location = nil
        flags.forEach { setFlag($0) }

        if let location {
            moveTo(location)
        }
    }

    /// Convenience initializer with location and variadic flags.
    ///
    /// - Parameters:
    ///   - name: The name of the object.
    ///   - description: The description of the object.
    ///   - location: The location of the object (optional).
    ///   - flags: Variadic list of flags to set on the object.
    public convenience init(
        name: String,
        description: String,
        location: GameObject? = nil,
        flags: String...
    ) {
        self.init(name: name, description: description, location: location, flags: flags)
    }

    // MARK: - Core Functions

    /// Attempts to add an object to this container.
    ///
    /// - Parameter obj: The object to add to this container.
    /// - Returns: True if the object was successfully added.
    public func addToContainer(_ obj: GameObject) -> Bool {
        if isContainer() && isOpen() {
            // Check capacity if it's limited
            if let capacity, contents.count >= capacity {
                return false
            }

            // Use setLocation which handles removing from current location
            // and adding to this container's contents
            obj.moveTo(self)
            return true
        }
        return false
    }

    /// Checks if this object is inside another object, directly or indirectly.
    ///
    /// - Parameter obj: The object to check if this object is inside.
    /// - Returns: True if this object is inside the specified object.
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

    /// Adds this object to a container.
    ///
    /// - Parameter destination: The new location for this object.
    public func moveTo(_ destination: GameObject?) {
        // If we already have a location, remove from its contents
        if let oldLocation = location {
            oldLocation.remove(self)
        }

        // Update our location reference
        location = destination

        // Add to new location's contents if not nil
        if let destination {
            // Only add if not already in contents to avoid duplicates
            if !destination.contents.contains(where: { $0 === self }) {
                destination.contents.append(self)
            }
        }
    }
    
    /// Attempts to remove an object from `contents`.
    ///
    /// - Parameter obj: The object to remove.
    /// - Returns: Whether the object was removed.
    public func remove(_ obj: GameObject) -> Bool {
        if contents.contains(where: { $0 === obj }) {
            contents.removeAll { $0 === obj }
            obj.moveTo(nil)
            return true
        }
        return false
    }

    /// Remove all objects from `contents`.
    public func removeAll() {
        contents.removeAll()
    }

    public func setCapacity(to capacity: Int?) {
        self.capacity = capacity
    }

    // MARK: - Flag Operations

    /// Checks if the object has a specific flag.
    ///
    /// - Parameter flag: The flag to check for.
    /// - Returns: True if the object has the specified flag.
    public func hasFlag(_ flag: String) -> Bool {
        return flags.contains(flag)
    }

    /// Adds a flag to the object.
    ///
    /// - Parameter flag: The flag to add.
    public func setFlag(_ flag: String) {
        flags.insert(flag)
    }

    /// Removes a flag from the object.
    ///
    /// - Parameter flag: The flag to remove.
    public func clearFlag(_ flag: String) {
        flags.remove(flag)
    }

    /// Sets multiple flags at once.
    ///
    /// - Parameter flags: The flags to set.
    public func setFlags(_ flags: String...) {
        for flag in flags {
            setFlag(flag)
        }
    }

    // MARK: - Container Operations

    /// Checks if this object is a container.
    ///
    /// - Returns: True if the object is a container.
    public func isContainer() -> Bool {
        return hasFlag("container")
    }

    /// Checks if this object is open.
    ///
    /// - Returns: True if the object is open.
    public func isOpen() -> Bool {
        return hasFlag("open")
    }

    /// Checks if this object can be opened.
    ///
    /// - Returns: True if the object can be opened.
    public func isOpenable() -> Bool {
        return hasFlag("openable")
    }

    /// Checks if the contents of this object are visible.
    ///
    /// - Returns: True if the contents are visible.
    public func canSeeInside() -> Bool {
        return isContainer() && (isOpen() || hasFlag("transparent"))
    }

    /// Attempts to open this object.
    ///
    /// - Returns: True if the object was successfully opened.
    public func open() -> Bool {
        if isContainer() && isOpenable() && !isOpen() {
            setFlag("open")
            return true
        }
        return false
    }

    /// Attempts to close this object.
    ///
    /// - Returns: True if the object was successfully closed.
    public func close() -> Bool {
        if isContainer() && isOpenable() && isOpen() {
            clearFlag("open")
            return true
        }
        return false
    }

    /// Checks if object is takeable.
    ///
    /// - Returns: True if the object can be taken.
    public func isTakeable() -> Bool {
        return hasFlag(.takeBit)
    }

    // MARK: - Global Object Operations

    /// Checks if this object is a global object.
    ///
    /// - Returns: True if this is a global object.
    public func isGlobalObject() -> Bool {
        let objectType: String? = getState(forKey: .globalObjectType)
        return objectType != nil
    }

    /// Checks if this object is a global object of a specific type.
    ///
    /// - Parameter localGlobal: Whether to check for local-global (false = global).
    /// - Returns: True if this object is a global object of the specified type.
    public func isGlobalObject(localGlobal: Bool) -> Bool {
        let objectType: String? = getState(forKey: .globalObjectType)
        let targetType = localGlobal ? String.localGlobalObject : String.globalObject
        return objectType == targetType
    }

    /// Get all rooms where this local-global object is accessible.
    ///
    /// - Returns: Array of rooms where this object is accessible.
    public func getAccessibleRooms() -> [Room] {
        guard isGlobalObject(localGlobal: true) else {
            return []
        }

        let accessibleRooms: [Room]? = getState(forKey: "accessibleRooms")
        return accessibleRooms ?? []
    }

    /// Find the player by traversing up the object graph.
    ///
    /// - Returns: The player object, or nil if not found.
    public func findPlayer() -> Player? {
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
    
    /// Find the game world by traversing up the object graph.
    ///
    /// - Returns: The game world, or nil if not found.
    public func findWorld() -> GameWorld? {
        findPlayer()?.world
    }

    // MARK: - State Management

    /// Set a state value for this object.
    ///
    /// - Parameters:
    ///   - value: Value to store.
    ///   - key: Key to store it under.
    func setState<T>(_ value: T, forKey key: String) {
        stateValues[key] = value
    }

    /// Get a state value by key.
    ///
    /// - Parameter key: Key to retrieve.
    /// - Returns: The stored value, or nil if not found.
    func getState<T>(forKey key: String) -> T? {
        return stateValues[key] as? T
    }

    /// Remove a state value for this object.
    ///
    /// - Parameter key: Key to remove.
    func removeState(forKey key: String) {
        stateValues.removeValue(forKey: key)
    }

    /// Check if a state key has a boolean true value.
    ///
    /// - Parameter key: The key to check.
    /// - Returns: True if the state exists and is true.
    func hasState(_ key: String) -> Bool {
        getState(forKey: key) ?? false
    }

    /// Check if a property exists in the object's state dictionary.
    ///
    /// - Parameter propertyName: The name of the property to check.
    /// - Returns: True if the property exists.
    public func hasProperty(_ propertyName: String) -> Bool {
        stateValues[propertyName] != nil
    }

    // MARK: - Command Handling

    /// Process a command against this game object, using its command handler if available.
    ///
    /// - Parameter command: The command to process.
    /// - Returns: True if the command was handled by this object.
    public func processCommand(_ command: Command) -> Bool {
        // Get the command handler using getState
        if let handler = stateValues["commandAction"] as? ((GameObject, Command) -> Bool) {
            return handler(self, command)
        }
        return false
    }

    /// Set a command handler for this game object.
    ///
    /// - Parameter handler: The command handler function.
    public func setCommandHandler(_ handler: @escaping (GameObject, Command) -> Bool) {
        stateValues["commandAction"] = handler
    }

    /// Set a handler for the examine command.
    ///
    /// - Parameter handler: The handler function that takes a GameObject and returns a Bool.
    public func setExamineHandler(_ handler: @escaping (GameObject) -> Bool) {
        let commandHandler: (GameObject, Command) -> Bool = { obj, command in
            if case .examine = command {
                return handler(obj)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set a handler for the take command.
    ///
    /// - Parameter handler: The handler function that takes a GameObject and returns a Bool.
    public func setTakeHandler(_ handler: @escaping (GameObject) -> Bool) {
        let commandHandler: (GameObject, Command) -> Bool = { obj, command in
            if case .take = command {
                return handler(obj)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set a handler for the drop command.
    ///
    /// - Parameter handler: The handler function that takes a GameObject and returns a Bool.
    public func setDropHandler(_ handler: @escaping (GameObject) -> Bool) {
        let commandHandler: (GameObject, Command) -> Bool = { obj, command in
            if case .drop = command {
                return handler(obj)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set a handler for a custom command.
    ///
    /// - Parameters:
    ///   - verb: The verb to handle.
    ///   - handler: The handler function that takes a GameObject and an array of objects and returns a Bool.
    public func setCustomCommandHandler(verb: String, handler: @escaping (GameObject, [GameObject]) -> Bool) {
        let commandHandler: (GameObject, Command) -> Bool = { obj, command in
            if case .customCommand(let cmdVerb, let objects, _) = command, cmdVerb == verb {
                return handler(obj, objects)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set handlers for multiple commands at once.
    ///
    /// - Parameter handlers: Dictionary mapping command verbs to handler functions.
    public func setCommandHandlers(handlers: [String: (GameObject) -> Bool]) {
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

    // MARK: - Dynamic Member Lookup

    /// Dynamic member lookup subscript for getting and setting state values with nice syntax.
    /// Always returns an optional value for safety.
    ///
    /// - Parameter key: The property name to access.
    /// - Returns: The value associated with the key, or nil if not found.
    public subscript<T>(dynamicMember key: String) -> T? {
        get {
            getState(forKey: key)
        }
        set {
            if let newValue {
                setState(newValue, forKey: key)
            } else {
                // If nil is assigned, remove the state
                removeState(forKey: key)
            }
        }
    }

    /// Provides access to a property existence check with the .isSet suffix.
    /// Example: object.someProperty.isSet will return true if someProperty exists.
    ///
    /// - Parameter key: The property name to check.
    /// - Returns: A PropertyExistenceChecker for the specified key.
    public subscript(dynamicMember key: String) -> PropertyExistenceChecker {
        PropertyExistenceChecker(object: self, key: key)
    }
}

/// Helper class to check if a property exists through the .isSet property.
///
/// Example usage:
/// ```swift
/// // Check if a property exists
/// if object.someProperty.isSet {
///     // Property exists, now we can safely use it
///     let value = object.someProperty as? String
/// }
/// ```
public struct PropertyExistenceChecker {
    /// The game object to check.
    private let object: GameObject

    /// The property key to check.
    private let key: String

    /// Initialize a new property existence checker.
    ///
    /// - Parameters:
    ///   - object: The game object to check.
    ///   - key: The property key to check.
    internal init(object: GameObject, key: String) {
        self.object = object
        self.key = key
    }

    /// Returns true if the property exists in the object's state dictionary.
    public var isSet: Bool {
        object.stateValues[key] != nil
    }
}

// MARK: - String Constants

/// String constants for global object types.
public extension String {
    /// Global object type accessible from anywhere.
    static let globalObjectType = "global-object-type"

    /// Global object type value for global objects.
    static let globalObject = "global"

    /// Global object type value for local-global objects.
    static let localGlobalObject = "local-global"
}

// MARK: - GameWorld Extensions

/// Global objects extension for GameWorld.
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
        globalObjects.append(object)

        // Mark the object with its global type
        let typeValue = isLocalGlobal ? String.localGlobalObject : String.globalObject
        object.setState(typeValue, forKey: String.globalObjectType)
    }

    /// Get all global objects of a specific type.
    ///
    /// - Parameter localGlobal: Whether to get local-globals (nil = all global types).
    /// - Returns: Array of global objects of the specified type.
    func getGlobalObjects(localGlobal: Bool? = nil) -> [GameObject] {
        return globalObjects.filter { object in
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
            return accessibleRooms?.contains { $0 === room } ?? false
        }

        return false
    }
}

// MARK: - Room Extensions

/// Room extension for managing local-global objects.
public extension Room {
    /// Make a local-global object accessible from this room.
    ///
    /// - Parameter object: The local-global object.
    func addLocalGlobal(_ object: GameObject) {
        // Make sure the object is registered as a local-global
        let objectType: String? = object.getState(forKey: .globalObjectType)

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

    /// Remove a local-global object's accessibility from this room.
    ///
    /// - Parameter object: The local-global object.
    func removeLocalGlobal(_ object: GameObject) {
        var accessibleRooms: [Room] = object.getState(forKey: "accessibleRooms") ?? []

        // Filter out this room
        accessibleRooms = accessibleRooms.filter { $0 !== self }
        object.setState(accessibleRooms, forKey: "accessibleRooms")
    }

    /// Get all local-global objects accessible from this room.
    ///
    /// - Returns: Array of local-global objects accessible from this room.
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

extension GameObject: CustomStringConvertible {
    
}
