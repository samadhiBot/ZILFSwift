import Foundation

/// Represents any object in the game world.
///
/// Items in the game world have type `GameObject`. `Room` and `Player` are subclasses.
///
/// Provides functionality for object relationships, state management, and interactions.
@dynamicMemberLookup
public class GameObject {
    /// The object's primary identifier.
    public let id: GameObject.ID

    /// The object's name.
    public let name: String

    /// The descriptive text for this object.
    public private(set) var description: String

    /// The room or container that holds this object.
    public private(set) var location: GameObject?

    /// Any objects contained within this object.
    public private(set) var contents = [GameObject]()

    /// The set of flags that define object behaviors and states.
    public private(set) var flags = Set<Flag>()

    /// Alternative words that can be used to refer to this object.
    public private(set) var synonyms: Set<String>

    /// The game object type.
    public private(set) var type: GameObject.Category

    /// The maximum number of objects this object can contain.
    public private(set) var capacity: Int?

    /// A dictionary storing dynamic state values.
    var stateValues = [String: Any]()

    /// The world in which the object exists.
    public private(set) weak var world: GameWorld?

    /// Creates a new `GameObject` instance.
    /// 
    /// - Parameters:
    ///   - id: The object's unique identifier.
    ///   - name: The name of the object.
    ///   - description: The description of the object.
    ///   - flags: Variadic list of flags to set on the object.
    ///   - synonyms: Variadic list of synonyms for the object.
    public init(
        id: GameObject.ID? = nil,
        name: String,
        description: String,
        flags: Flag...,
        synonyms: String...
    ) {
        self.id = id ?? GameObject.ID(stringLiteral: name)
        self.name = name
        self.description = description
        self.flags = Set(flags)
        self.synonyms = Set(synonyms)
        self.type = .object
    }

    /// An internal `GameObject` initializer for use in subclasses.
    init(
        id: GameObject.ID? = nil,
        name: String,
        description: String,
        location: GameObject? = nil,
        type: GameObject.Category,
        flags: [Flag] = [],
        synonyms: [String] = []
    ) {
        self.id = id ?? GameObject.ID(stringLiteral: name)
        self.name = name
        self.description = description
        self.location = location
        self.flags = Set(flags)
        self.synonyms = Set(synonyms)
        self.type = type

        if let location {
            moveTo(location)
        }
    }

    /// Sets the world in which the object exists.
    ///
    /// - Parameter world: The world in which the object exists.
    func setWorld(to world: GameWorld) {
        self.world = world
    }
}

// MARK: - Core Functions

extension GameObject {
    /// Attempts to add an object to this container.
    ///
    /// - Parameter obj: The object to add to this container.
    /// - Returns: True if the object was successfully added.
    public func addToContainer(_ obj: GameObject) -> Bool {
        if obj.hasFlags(.isContainer, .isOpen) {
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
    
    /// <#Description#>
    /// - Parameter room: <#room description#>
    /// - Returns: <#description#>
    public func isAccessible(in room: Room) -> Bool {
        switch type {
        case .global: true
        case .localGlobal(let roomIDs): roomIDs.contains(room.id)
        default: isIn(room)
        }
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

    /// Checks whether the object is providing light.
    ///
    /// - Returns: Whether the object is providing light.
    public func isLightSource() -> Bool {
        hasFlags(.isLightSource, .isOn) || hasFlag(.isNaturallyLit)
    }

    /// Adds this object to a container.
    ///
    /// - Parameter destination: The new location for this object.
    public func moveTo(_ destination: GameObject?) {
        // If we already have a location, remove from its contents
        if let oldLocation = location {
            _ = oldLocation.remove(self)
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
    
    /// Sets the object's capacity.
    ///
    /// - Parameter capacity: The object's capacity.
    public func setCapacity(to capacity: Int?) {
        self.capacity = capacity
    }

    /// Sets the object's type.
    ///
    /// - Parameter type: The object's type.
    func setType(to type: GameObject.Category) {
        self.type = type
    }
}

// MARK: - Flag Operations

extension GameObject {
    /// Checks whether the object has a specific flag.
    ///
    /// - Parameter flag: The flag to check for.
    /// - Returns: `true` if the object has the specified flag.
    public func hasFlag(_ flag: Flag) -> Bool {
        flags.contains(flag)
    }

    /// Checks whether the object has all of the specified flags.
    ///
    /// - Parameters:
    ///   - flags: The flags to check for.
    ///   - quantifier: Whether to match `all` or `any` of the specified flags.
    ///
    /// - Returns: `true` if the object has all of the specified flags.
    public func hasFlags(
        _ flags: Flag...,
        matching quantifier: Flag.Quantifier = .all
    ) -> Bool {
        switch quantifier {
        case .all: flags.allSatisfy { hasFlag($0) }
        case .any: flags.contains { hasFlag($0) }
        }
    }

    /// Adds a flag to the object.
    ///
    /// - Parameter flag: The flag to add.
    public func setFlag(_ flag: Flag) {
        flags.insert(flag)
    }

    /// Sets multiple flags at once.
    ///
    /// - Parameter flags: The flags to set.
    public func setFlags(_ flags: Flag...) {
        for flag in flags {
            setFlag(flag)
        }
    }

    /// Removes a flag from the object.
    ///
    /// - Parameter flag: The flag to remove.
    public func clearFlag(_ flag: Flag) {
        flags.remove(flag)
    }
}

// MARK: - Global Object Operations

extension GameObject {
//    /// Checks if this object is a global object.
//    ///
//    /// - Returns: True if this is a global object.
//    public var isGlobal: Bool {
//        switch type {
//        case .global: true
//        default: false
//        }
//    }

    /// Checks if this object is a global object of a specific type.
    ///
    /// - Parameter localGlobal: Whether to check for local-global (false = global).
    /// - Returns: True if this object is a global object of the specified type.
//    public func isGlobalObject(localGlobal: Bool) -> Bool {
//        let objectType: String? = getState(forKey: .globalObjectType)
//        let targetType = localGlobal ? String.localGlobalObject : String.globalObject
//        return objectType == targetType
//    }

    /// Get all rooms where this local-global object is accessible.
    ///
    /// - Returns: Array of rooms where this object is accessible.
//    public func getAccessibleRooms() -> [Room] {
//        guard isGlobalObject(localGlobal: true) else {
//            return []
//        }
//
//        let accessibleRooms: [Room]? = getState(forKey: .accessibleRooms)
//        return accessibleRooms ?? []
//    }

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

//    /// Find the game world by traversing up the object graph.
//    ///
//    /// - Returns: The game world, or nil if not found.
//    public func findWorld() -> GameWorld? {
//        findPlayer()?.world
//    }
}

// MARK: - State Management

extension GameObject {
    /// Set a state value for this object.
    ///
    /// - Parameters:
    ///   - value: Value to store.
    ///   - key: Key to store it under.
    func setState<T>(_ value: T, forKey key: String) {
        print("🎾 setState \(key): \(value)")
        stateValues[key] = value
    }

    /// Get a state value by key.
    ///
    /// - Parameter key: Key to retrieve.
    /// - Returns: The stored value, or nil if not found.
    func getState<T>(forKey key: String) -> T? {
        stateValues[key] as? T
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
}

// MARK: - Command Handling

extension GameObject {
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
    public func setCommandHandler(_ handler: @escaping (GameObject, Command) throws -> Bool) {
        stateValues["commandAction"] = handler
    }

    /// Set a handler for the examine command.
    ///
    /// - Parameter handler: The handler function that takes a GameObject and returns a Bool.
    public func setExamineHandler(_ handler: @escaping (GameObject) throws -> Bool) {
        let commandHandler: (GameObject, Command) throws -> Bool = { obj, command in
            if case .examine = command {
                return try handler(obj)
            }
            return false
        }
        setCommandHandler(commandHandler)
    }

    /// Set a handler for the take command.
    ///
    /// - Parameter handler: The handler function that takes a GameObject and returns a Bool.
    public func setTakeHandler(_ handler: @escaping (GameObject) throws -> Bool) {
        let commandHandler: (GameObject, Command) throws -> Bool = { obj, command in
            if case .take = command {
                return try handler(obj)
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
    public func setCustomCommandHandler(
        verb: String,
        handler: @escaping (GameObject, [GameObject]) throws -> Bool
    ) {
        let commandHandler: (GameObject, Command) throws -> Bool = { obj, command in
            // Check if this is a custom command with the matching verb
            guard
                case .custom(let words) = command,
                words.first == verb
            else {
                return false
            }
            // Extract objects from parser or game context
            // For now, assume we're working with an empty array
            // In a full implementation, we'd need to connect to the parser
            let objects: [GameObject] = []
            return try handler(obj, objects)
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
                case .custom(let words) where !words.isEmpty && words[0] == verb:
                    return handler(obj)
                default:
                    return false
                }
            }
        }

        setCommandHandler(compositHandler)
    }
}

// MARK: - Dynamic Member Lookup

extension GameObject {
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
    ///
    /// Example: object.someProperty.isSet will return true if someProperty exists.
    ///
    /// - Parameter key: The property name to check.
    /// - Returns: A PropertyExistenceChecker for the specified key.
    public subscript(dynamicMember key: String) -> PropertyExistenceChecker {
        PropertyExistenceChecker(object: self, key: key)
    }
}

// MARK: - Synonym Management

extension GameObject {
    /// Adds a new synonym for this object.
    /// - Parameter synonym: The synonym to add.
    public func addSynonym(_ synonym: String) {
        guard !synonym.isEmpty, synonym != name else { return }
        synonyms.insert(synonym)
    }

    /// Adds multiple synonyms for this object using a variadic parameter.
    /// - Parameter newSynonyms: The synonyms to add as a variadic parameter.
    public func addSynonyms(_ newSynonyms: String...) {
        newSynonyms.forEach { addSynonym($0) }
    }

    /// Removes a synonym from this object.
    ///
    /// - Parameter synonym: The synonym to remove.
    public func removeSynonym(_ synonym: String) {
        synonyms.remove(synonym)
    }

    /// Checks if a given word matches this object's name or any of its synonyms.
    ///
    /// - Parameters:
    ///   - word: The word to check.
    ///   - partial: Whether to include partial matches.
    /// - Returns: Whether the word matches this object.
    public func matchesName(
        _ word: String,
        partial: Bool = false
    ) -> Bool {
        let nameLower = name.lowercased()
        let wordLower = word.lowercased()
        if nameLower == wordLower { return true }
        if synonyms.contains(where: { $0.lowercased() == wordLower }) { return true }
        if !partial { return false }
        if nameLower.contains(wordLower) { return true }
        if synonyms.contains(where: { $0.lowercased().contains(wordLower) }) { return true }
        return false
    }
}

// MARK: - PropertyExistenceChecker

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

// MARK: - CustomDebugStringConvertible

extension GameObject: CustomDebugStringConvertible {
    public var debugDescription: String {
        name.capitalized
    }
}

// MARK: - Equatable

extension GameObject: Equatable {
    public static func == (lhs: GameObject, rhs: GameObject) -> Bool {
        lhs === rhs
    }
}
