//
//  CommandParser.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation

public enum Command {
    case close(GameObject)
    case drop(GameObject)
    case examine(GameObject)
    case inventory
    case look
    case move(Direction)
    case open(GameObject)
    case quit
    case take(GameObject)
    case unknown(String)
}

public class CommandParser {
    private let world: GameWorld

    public init(world: GameWorld) {
        self.world = world
    }

    public func parse(_ input: String) -> Command {
        let words = input.lowercased().split(separator: " ").map(String.init)
        guard let firstWord = words.first else {
            return .unknown("No command given")
        }

        switch firstWord {
        case "close":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if objName.lowercased() == "it" && world.lastMentionedObject == nil {
                    return .unknown("I don't know what 'it' refers to.")
                }
                if let obj = findObject(named: objName) {
                    return .close(obj)
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }
            return .unknown("Close what?")

        case "drop":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if let obj = findObjectInInventory(named: objName) {
                    return .drop(obj)
                }
                return .unknown("You're not carrying \(articleFor(objName)) \(objName).")
            }
            return .unknown("Drop what?")

        case "examine", "x":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if objName.lowercased() == "it" && world.lastMentionedObject == nil {
                    return .unknown("I don't know what 'it' refers to.")
                }
                if let obj = findObject(named: objName) {
                    return .examine(obj)
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }
            return .unknown("Examine what?")

        case "go":
            if words.count > 1, let direction = Direction.from(string: words[1]) {
                return .move(direction)
            }
            return .unknown("Go where?")

        case "inventory", "i":
            return .inventory

        case "look", "l":
            // Check if this is "look at <object>" or just "look"
            if words.count > 1 && words[1] == "at" && words.count > 2 {
                // This is "look at <object>"
                let objName = words.dropFirst(2).joined(separator: " ")
                if let obj = findObject(named: objName) {
                    return .examine(obj)
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }
            return .look

        case "north", "n", "south", "s", "east", "e", "west", "w", "up", "u", "down", "d":
            if let direction = Direction.from(string: firstWord) {
                return .move(direction)
            }
            return .unknown("Unknown direction: \(firstWord)")

        case "open":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if objName.lowercased() == "it" && world.lastMentionedObject == nil {
                    return .unknown("I don't know what 'it' refers to.")
                }
                if let obj = findObject(named: objName) {
                    return .open(obj)
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }
            return .unknown("Open what?")

        case "quit", "q":
            return .quit

        case "take", "get":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if let obj = findObject(named: objName) {
                    return .take(obj)
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }
            return .unknown("Take what?")

        default:
            return .unknown("I don't understand '\(input)'.")
        }
    }

    private func articleFor(_ noun: String) -> String {
        // Simple logic for articles - could be expanded
        let firstChar = noun.first?.lowercased() ?? ""
        if "aeiou".contains(firstChar) {
            return "an"
        }
        return "a"
    }

    private func findObject(named rawName: String) -> GameObject? {
        // Remove articles
        let name = removeArticles(from: rawName)

        // Handle "it" references
        if name.lowercased() == "it" {
            if let lastObject = world.lastMentionedObject {
                // Check if the object is visible (either in inventory, current room, or open container)
                if isObjectAccessible(lastObject) {
                    return lastObject
                }
            }
            return nil
        }

        // First check the player's inventory
        for obj in world.player.contents {
            if objectMatchesName(obj, name) {
                return obj
            }
        }

        // Then check the current room
        if let room = world.player.currentRoom {
            // Look for direct matches in the room
            for obj in room.contents where obj !== world.player {
                if objectMatchesName(obj, name) {
                    return obj
                }
            }

            // Then look inside open containers in the room
            for container in room.contents where container !== world.player {
                if container.isContainer() && container.canSeeInside() {
                    for obj in container.contents {
                        if objectMatchesName(obj, name) {
                            return obj
                        }
                    }
                }
            }

            // Check for global and local-global objects accessible from this room
            for obj in world.globalObjects {
                if objectMatchesName(obj, name) && world.isGlobalObjectAccessible(obj, in: room) {
                    return obj
                }
            }
        }

        // Also check for objects in open containers in inventory
        for container in world.player.contents {
            if container.isContainer() && container.canSeeInside() {
                for obj in container.contents {
                    if objectMatchesName(obj, name) {
                        return obj
                    }
                }
            }
        }

        return nil
    }

    // Helper to check if an object's name matches a search term
    private func objectMatchesName(_ obj: GameObject, _ name: String) -> Bool {
        // Exact match
        if obj.name.lowercased() == name.lowercased() {
            return true
        }

        // Partial match (last word or substring)
        let objWords = obj.name.lowercased().split(separator: " ").map(String.init)
        return objWords.last == name.lowercased() || obj.name.lowercased().contains(name.lowercased())
    }

    // Helper to check if an object is currently accessible to the player
    private func isObjectAccessible(_ obj: GameObject) -> Bool {
        // In player's inventory
        if obj.location === world.player {
            return true
        }

        // Directly in the current room
        if obj.location === world.player.currentRoom {
            return true
        }

        // Inside an open container in the room
        if let container = obj.location,
           container.isContainer() && container.canSeeInside() &&
            container.location === world.player.currentRoom {
            return true
        }

        // Inside an open container in inventory
        if let container = obj.location,
           container.isContainer() && container.canSeeInside() &&
            container.location === world.player {
            return true
        }

        // Check if it's a global or local-global object accessible from the current room
        if let room = world.player.currentRoom, obj.isGlobalObject() {
            return world.isGlobalObjectAccessible(obj, in: room)
        }

        return false
    }

    private func findObjectInInventory(named rawName: String) -> GameObject? {
        // Remove articles
        let name = removeArticles(from: rawName)

        // Look for exact match
        for obj in world.player.contents {
            if obj.name.lowercased() == name.lowercased() {
                return obj
            }
        }

        // Try suffix matching
        for obj in world.player.contents {
            let objWords = obj.name.lowercased().split(separator: " ").map(String.init)
            if objWords.last == name.lowercased() || obj.name.lowercased().contains(name.lowercased()) {
                return obj
            }
        }

        return nil
    }

    private func removeArticles(from text: String) -> String {
        let words = text.lowercased().split(separator: " ").map(String.init)
        if words.first == "the" || words.first == "a" || words.first == "an" {
            return words.dropFirst().joined(separator: " ")
        }
        return text
    }
}
