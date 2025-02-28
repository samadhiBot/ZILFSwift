//
//  GameModel.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation

// Game objects (rooms, items, etc.)
public class GameObject {
    public var capacity: Int = -1  // -1 means unlimited capacity
    public var contents: [GameObject] = []
    public var description: String
    public var flags: Set<String> = []
    public var location: GameObject?
    public var name: String

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
}

// Room is a specialized GameObject
public class Room: GameObject {
    public var exits: [Direction: Room] = [:]

    // Action handlers for different phases
    public var enterAction: ((Room) -> Void)?
    public var endTurnAction: ((Room) -> Void)?
    public var beginCommandAction: ((Room, Command) -> Bool)?

    public init(name: String, description: String) {
        super.init(name: name, description: description)
    }

    public func setExit(direction: Direction, room: Room) {
        exits[direction] = room
    }

    public func getExit(direction: Direction) -> Room? {
        return exits[direction]
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
        guard let currentRoom = self.currentRoom,
              let newRoom = currentRoom.getExit(direction: direction) else {
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
        if let enterAction = newRoom.enterAction {
            enterAction(newRoom)
        }

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
}
