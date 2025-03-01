//
//  GlobalObjects.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 8/2/25.
//

import Foundation

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
            if let world = world {
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
