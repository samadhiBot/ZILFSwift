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

    /// A custom command for extended verb support
    /// - Parameters:
    ///   - verb: The verb string
    ///   - objects: Array of game objects involved in the command
    ///   - additionalData: Optional string data for the command (e.g., topics, text)
    case customCommand(String, [GameObject], additionalData: String? = nil)
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

        case "examine", "x", "look":
            // Handle "look at" separately
            if firstWord == "look" && words.count > 1 && words[1] != "at" {
                return .look
            }

            // Handle "look at <object>", "examine <object>", or "x <object>"
            let startIndex = firstWord == "look" && words.count > 1 && words[1] == "at" ? 2 : 1

            if words.count > startIndex {
                let objName = words.dropFirst(startIndex).joined(separator: " ")
                if objName.lowercased() == "it" && world.lastMentionedObject == nil {
                    return .unknown("I don't know what 'it' refers to.")
                }
                if let obj = findObject(named: objName) {
                    return .examine(obj)
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }

            // If just "look" with no object, return look command
            if firstWord == "look" {
                return .look
            }

            return .unknown("Examine what?")

        case "go":
            if words.count > 1, let direction = Direction.from(string: words[1]) {
                return .move(direction)
            }
            return .unknown("Go where?")

        case "inventory", "i":
            return .inventory

        case "l":
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
                // Check for "take inventory" command
                if words.count == 2 && words[1] == "inventory" {
                    return .inventory
                }

                let objName = words.dropFirst().joined(separator: " ")
                if objName.lowercased() == "it" && world.lastMentionedObject == nil {
                    return .unknown("I don't know what 'it' refers to.")
                }
                if let obj = findObject(named: objName) {
                    return .take(obj)
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }
            return .unknown("Take what?")

        // New verb handlers
        case "wear", "don":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if let obj = findObjectInInventory(named: objName) {
                    if obj.hasFlag(String.wearBit) {
                        return .customCommand("wear", [obj])
                    } else {
                        return .unknown("You can't wear that.")
                    }
                } else {
                    return .unknown("You don't have that.")
                }
            }
            return .unknown("Wear what?")

        case "remove", "doff":
            // Check for removing worn items
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if let obj = findObjectInInventory(named: objName) {
                    if obj.hasFlag(String.wornBit) {
                        return .customCommand("unwear", [obj])
                    } else {
                        return .unknown("You're not wearing that.")
                    }
                } else {
                    return .unknown("You don't have that.")
                }
            }
            return .unknown("Remove what?")

        // Special handling for "take off" command
        case "take" where words.count > 2 && words[1] == "off":
            let objName = words.dropFirst(2).joined(separator: " ")
            if let obj = findObjectInInventory(named: objName) {
                if obj.hasFlag(String.wornBit) {
                    return .customCommand("unwear", [obj])
                } else {
                    return .unknown("You're not wearing that.")
                }
            } else {
                return .unknown("You don't have that.")
            }

        case "turn":
            if words.count > 2 {
                if words[1] == "on" {
                    let objName = words.dropFirst(2).joined(separator: " ")
                    if let obj = findObject(named: objName) {
                        if obj.hasFlag(.deviceBit) {
                            return .customCommand("turn_on", [obj])
                        }
                        return .unknown("You can't turn on \(articleFor(objName)) \(objName).")
                    }
                    return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
                } else if words[1] == "off" {
                    let objName = words.dropFirst(2).joined(separator: " ")
                    if let obj = findObject(named: objName) {
                        if obj.hasFlag(.deviceBit) {
                            return .customCommand("turn_off", [obj])
                        }
                        return .unknown("You can't turn off \(articleFor(objName)) \(objName).")
                    }
                    return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
                }
            }
            return .unknown("Turn what on or off?")

        case "flip", "switch", "toggle":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if let obj = findObject(named: objName) {
                    if obj.hasFlag(.deviceBit) {
                        return .customCommand("flip", [obj])
                    }
                    return .unknown("You can't flip \(articleFor(objName)) \(objName).")
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }
            return .unknown("Flip what?")

        case "wait", "z":
            return .customCommand("wait", [])

        case "again", "g":
            return .customCommand("again", [])

        case "read", "peruse":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                if let obj = findObject(named: objName) {
                    if obj.hasFlag(.readBit) {
                        return .customCommand("read", [obj])
                    }
                    return .unknown("There's nothing to read on \(articleFor(objName)) \(objName).")
                }
                return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
            }
            return .unknown("Read what?")

        case "version":
            return .customCommand("version", [])

        case "save":
            return .customCommand("save", [])

        case "restore":
            return .customCommand("restore", [])

        case "restart":
            return .customCommand("restart", [])

        case "undo":
            return .customCommand("undo", [])

        case "brief":
            return .customCommand("brief", [])

        case "verbose":
            return .customCommand("verbose", [])

        case "superbrief":
            return .customCommand("superbrief", [])

        default:
            return .unknown("I don't understand that command.")
        }
    }

    private func articleFor(_ noun: String) -> String {
        let firstChar = noun.prefix(1).lowercased()
        if "aeiou".contains(firstChar) {
            return "an"
        } else {
            return "a"
        }
    }

    private func findObject(named name: String) -> GameObject? {
        // If "it" is used, return the last mentioned object
        if name.lowercased() == "it" {
            return world.lastMentionedObject
        }

        let player = world.player
        let currentRoom = player.currentRoom
        let nameToFind = name.lowercased()

        // Check player's inventory
        for obj in player.contents {
            // Try exact match first
            if obj.name.lowercased() == nameToFind {
                world.lastMentionedObject = obj
                return obj
            }

            // Try partial match (for tests and user convenience)
            if nameToFind.contains(obj.name.lowercased()) || obj.name.lowercased().contains(nameToFind) {
                world.lastMentionedObject = obj
                return obj
            }
        }

        // Check current room
        if let room = currentRoom {
            for obj in room.contents {
                // Try exact match first
                if obj.name.lowercased() == nameToFind {
                    world.lastMentionedObject = obj
                    return obj
                }

                // Try partial match (for tests and user convenience)
                if nameToFind.contains(obj.name.lowercased()) || obj.name.lowercased().contains(nameToFind) {
                    world.lastMentionedObject = obj
                    return obj
                }

                // Check inside visible containers in the room
                if obj.canSeeInside() {
                    for innerObj in obj.contents {
                        // Try exact match first
                        if innerObj.name.lowercased() == nameToFind {
                            world.lastMentionedObject = innerObj
                            return innerObj
                        }

                        // Try partial match (for tests and user convenience)
                        if nameToFind.contains(innerObj.name.lowercased()) || innerObj.name.lowercased().contains(nameToFind) {
                            world.lastMentionedObject = innerObj
                            return innerObj
                        }
                    }
                }
            }

            // Check for global objects that are accessible in this room
            for globalObj in world.globalObjects {
                // Try exact match first
                if globalObj.name.lowercased() == nameToFind &&
                   world.isGlobalObjectAccessible(globalObj, in: room) {
                    world.lastMentionedObject = globalObj
                    return globalObj
                }

                // Try partial match (for tests and user convenience)
                if (nameToFind.contains(globalObj.name.lowercased()) ||
                    globalObj.name.lowercased().contains(nameToFind)) &&
                   world.isGlobalObjectAccessible(globalObj, in: room) {
                    world.lastMentionedObject = globalObj
                    return globalObj
                }
            }
        }

        return nil
    }

    private func findObjectInInventory(named name: String) -> GameObject? {
        // If "it" is used, return the last mentioned object if it is in the player's inventory
        if name.lowercased() == "it" {
            if let lastObj = world.lastMentionedObject,
               world.player.contents.contains(where: { $0 === lastObj }) {
                return lastObj
            }
            return nil
        }

        let nameToFind = name.lowercased()

        for obj in world.player.contents {
            // Try exact match first
            if obj.name.lowercased() == nameToFind {
                world.lastMentionedObject = obj
                return obj
            }

            // Try partial match (for tests and user convenience)
            if nameToFind.contains(obj.name.lowercased()) || obj.name.lowercased().contains(nameToFind) {
                world.lastMentionedObject = obj
                return obj
            }
        }

        return nil
    }
}
