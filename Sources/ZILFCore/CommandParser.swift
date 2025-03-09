import Foundation

/// A class responsible for parsing player input and converting it into game commands.
///
/// The parser analyzes text input, identifies verbs and objects, and returns the appropriate
/// `Command` enum value based on the recognized input pattern.
public class CommandParser {
    /// Reference to the game world containing all game objects and state
    private let world: GameWorld

    /// Initializes a new command parser with a reference to the game world
    ///
    /// - Parameter world: The game world that contains objects to be referenced in commands
    public init(world: GameWorld) {
        self.world = world
    }

    /// Parses a string input from the player and converts it to a Command
    ///
    /// - Parameter input: The raw text input from the player
    ///
    /// - Returns: A Command representing the action to be taken
    public func parse(_ input: String) -> Command {
        let words = input.lowercased().split(separator: " ").map(String.init)
        guard let firstWord = words.first else {
            return .unknown("No command given")
        }
        
        // Try to create a command from the input
        let command = Command(from: words)
        
        // Handle the command based on its type
        switch command {
        case .again:
            return .again
        case .brief:
            return .brief
        case .close:
            return handleClose(words)
        case .drop:
            return handleDrop(words)
        case .examine:
            return handleExamine(words)
        case .flip:
            return handleFlip(words)
        case .inventory:
            return .inventory
        case .look:
            return handleLook(words)
        case .moveNorth, .moveSouth, .moveEast, .moveWest, 
             .moveUp, .moveDown, .moveNorthEast, .moveNorthWest,
             .moveSouthEast, .moveSouthWest, .moveInside, .moveOutside:
            return handleMove(command)
        case .open:
            return handleOpen(words)
        case .putIn:
            return handlePutIn(words)
        case .putOn:
            return handlePutOn(words)
        case .quit:
            return .quit
        case .read:
            return handleRead(words)
        case .remove:
            return handleRemove(words)
        case .restart:
            return .restart
        case .restore:
            return .restore
        case .save:
            return .save
        case .superbrief:
            return .superbrief
        case .take:
            return handleTake(words)
        case .turnOff, .turnOn:
            return handleTurn(command, words)
        case .undo:
            return .undo
        case .verbose:
            return .verbose
        case .version:
            return .version
        case .wait:
            return .wait
        case .wear:
            return handleWear(words)
        case .custom(let customWords):
            // Handle custom commands that weren't recognized
            return .unknown("I don't understand that command.")
        case .help:
            return .help
        default:
            return .unknown("I don't understand that command.")
        }
    }

    // MARK: - Command Handlers
    
    /// Handles the close command
    private func handleClose(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Close what?")
        }

        let objName = words.dropFirst().joined(separator: " ")
        if objName.lowercased() == "it" && world.lastMentionedObject == nil {
            return .unknown("I don't know what 'it' refers to.")
        }

        if let obj = findObject(named: objName) {
            return .close(obj)
        }

        return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
    }

    /// Handles the drop command
    private func handleDrop(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Drop what?")
        }

        let objName = words.dropFirst().joined(separator: " ")
        if let obj = findObjectInInventory(named: objName) {
            return .drop(obj)
        }

        return .unknown("You're not carrying \(articleFor(objName)) \(objName).")
    }

    /// Handles the examine command
    private func handleExamine(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Examine what?")
        }

        let objName = words.dropFirst().joined(separator: " ")
        if objName.lowercased() == "it" && world.lastMentionedObject == nil {
            return .unknown("I don't know what 'it' refers to.")
        }

        if let obj = findObject(named: objName) {
            return .examine(obj)
        }

        return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
    }

    /// Handles the flip, switch, and toggle commands
    private func handleFlip(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Flip what?")
        }

        let objName = words.dropFirst().joined(separator: " ")
        if let obj = findObject(named: objName) {
            if obj.hasFlag(.deviceBit) {
                return .flip(obj)
            }
            return .unknown("You can't flip \(articleFor(objName)) \(objName).")
        }

        return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
    }

    /// Handles move commands
    private func handleMove(_ command: Command) -> Command {
        // Map the movement command to a direction
        let direction: Direction
        switch command {
        case .moveNorth: direction = .north
        case .moveSouth: direction = .south
        case .moveEast: direction = .east
        case .moveWest: direction = .west
        case .moveUp: direction = .up
        case .moveDown: direction = .down
        case .moveNorthEast: direction = .northeast
        case .moveNorthWest: direction = .northwest
        case .moveSouthEast: direction = .southeast
        case .moveSouthWest: direction = .southwest
        case .moveInside: direction = .in
        case .moveOutside: direction = .out
        default: 
            return .unknown("Go where?")
        }
        
        return .move(direction)
    }

    /// Handles the look command
    private func handleLook(_ words: [String]) -> Command {
        // Just "look" with no arguments
        if words.count == 1 {
            return .look
        }

        // If "look" is not followed by "at", return basic look command
        if words.count > 1 && words[1] != "at" {
            return .look
        }

        // Handle "look at <object>"
        guard words.count > 2 else {
            return .unknown("Look at what?")
        }

        let objName = words.dropFirst(2).joined(separator: " ")
        if objName.lowercased() == "it" && world.lastMentionedObject == nil {
            return .unknown("I don't know what 'it' refers to.")
        }

        if let obj = findObject(named: objName) {
            return .examine(obj)
        }

        return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
    }

    /// Handles the open command
    private func handleOpen(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Open what?")
        }

        let objName = words.dropFirst().joined(separator: " ")
        if objName.lowercased() == "it" && world.lastMentionedObject == nil {
            return .unknown("I don't know what 'it' refers to.")
        }

        if let obj = findObject(named: objName) {
            return .open(obj)
        }

        return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
    }

    /// Handles the put-in command
    private func handlePutIn(_ words: [String]) -> Command {
        // Need at least "put X in Y"
        guard words.count >= 4 else {
            return .unknown("Put what where?")
        }
        
        let objIndex = words.firstIndex(where: { $0 == "in" })
        guard let prepositionIndex = objIndex, prepositionIndex > 1 else {
            return .unknown("I don't understand what you want to put where.")
        }
        
        let directObjName = words[1..<prepositionIndex].joined(separator: " ")
        let containerName = words[(prepositionIndex+1)...].joined(separator: " ")
        
        guard let directObj = findObject(named: directObjName) else {
            return .unknown("I don't see \(articleFor(directObjName)) \(directObjName) here.")
        }
        
        guard let container = findObject(named: containerName) else {
            return .unknown("I don't see \(articleFor(containerName)) \(containerName) here.")
        }
        
        return .putIn(directObj, container)
    }
    
    /// Handles the put-on command
    private func handlePutOn(_ words: [String]) -> Command {
        // Handle "put on X" (wear X)
        if words.count >= 3 && words[1] == "on" {
            let objName = words.dropFirst(2).joined(separator: " ")
            if let obj = findObjectInInventory(named: objName) {
                if obj.hasFlag(.wearBit) {
                    return .wear(obj)
                } else {
                    return .unknown("You can't wear \(articleFor(objName)) \(objName).")
                }
            }
            return .unknown("You don't have \(articleFor(objName)) \(objName).")
        }
        
        // Handle "put X on Y"
        if words.count >= 4 {
            let objIndex = words.firstIndex(where: { $0 == "on" })
            guard let prepositionIndex = objIndex, prepositionIndex > 1 else {
                return .unknown("I don't understand what you want to put where.")
            }
            
            let directObjName = words[1..<prepositionIndex].joined(separator: " ")
            let surfaceName = words[(prepositionIndex+1)...].joined(separator: " ")
            
            guard let directObj = findObject(named: directObjName) else {
                return .unknown("I don't see \(articleFor(directObjName)) \(directObjName) here.")
            }
            
            guard let surface = findObject(named: surfaceName) else {
                return .unknown("I don't see \(articleFor(surfaceName)) \(surfaceName) here.")
            }
            
            return .putOn(directObj, surface)
        }
        
        return .unknown("Put what where?")
    }

    /// Handles the read command
    private func handleRead(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Read what?")
        }

        let objName = words.dropFirst().joined(separator: " ")
        if let obj = findObject(named: objName) {
            if obj.hasFlag(.readBit) {
                return .read(obj)
            }
            return .unknown("There's nothing to read on \(articleFor(objName)) \(objName).")
        }

        return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
    }

    /// Handles the remove and doff commands
    private func handleRemove(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Remove what?")
        }

        let objName = words.dropFirst().joined(separator: " ")
        if let obj = findObjectInInventory(named: objName) {
            if obj.hasFlag(.wornBit) {
                return .unwear(obj)
            } else {
                return .unknown("You're not wearing that.")
            }
        } else {
            return .unknown("You don't have that.")
        }
    }

    /// Handles the take and get commands
    private func handleTake(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Take what?")
        }

        // Check for "take inventory" command
        if words.count == 2 && words[1] == "inventory" {
            return .inventory
        }

        // Special case: "take off <item>"
        if words.count > 2 && words[1] == "off" {
            let objName = words.dropFirst(2).joined(separator: " ")
            if let obj = findObjectInInventory(named: objName) {
                if obj.hasFlag(.wornBit) {
                    return .unwear(obj)
                } else {
                    return .unknown("You're not wearing that.")
                }
            } else {
                return .unknown("You don't have that.")
            }
        }

        // Special case: "take <item> off"
        if words.count > 2 && words.last == "off" {
            let objName = words.dropFirst(1).dropLast().joined(separator: " ")
            if let obj = findObjectInInventory(named: objName) {
                if obj.hasFlag(.wornBit) {
                    return .unwear(obj)
                } else {
                    return .unknown("You're not wearing that.")
                }
            } else {
                return .unknown("You don't have that.")
            }
        }

        // Regular take command
        let objName = words.dropFirst().joined(separator: " ")
        if objName.lowercased() == "it" && world.lastMentionedObject == nil {
            return .unknown("I don't know what 'it' refers to.")
        }

        if let obj = findObject(named: objName) {
            return .take(obj)
        }

        return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
    }

    /// Handles turn on/off commands
    private func handleTurn(_ command: Command, _ words: [String]) -> Command {
        // Determine if it's turn on or turn off
        let isOn = command == .turnOn
        let actionWord = isOn ? "on" : "off"
        
        // Extract object name from different patterns:
        // "turn on X", "turn X on"
        var objName = ""
        
        if words.count >= 3 && words[1] == actionWord {
            // "turn on X"
            objName = words.dropFirst(2).joined(separator: " ")
        } else if words.count >= 3 && words.last == actionWord {
            // "turn X on"
            objName = words.dropFirst(1).dropLast().joined(separator: " ")
        } else {
            return .unknown("Turn what \(actionWord)?")
        }
        
        if let obj = findObject(named: objName) {
            if obj.hasFlag(.deviceBit) {
                return isOn ? .turnOn(obj) : .turnOff(obj)
            }
            return .unknown("You can't turn \(actionWord) \(articleFor(objName)) \(objName).")
        }
        
        return .unknown("I don't see \(articleFor(objName)) \(objName) here.")
    }

    /// Handles the wear command
    private func handleWear(_ words: [String]) -> Command {
        guard words.count > 1 else {
            return .unknown("Wear what?")
        }

        let objName = words.dropFirst().joined(separator: " ")
        if let obj = findObjectInInventory(named: objName) {
            if obj.hasFlag(.wearBit) {
                return .wear(obj)
            } else {
                return .unknown("You can't wear that.")
            }
        } else {
            return .unknown("You don't have that.")
        }
    }

    // MARK: - Helper methods

    /// Determines the appropriate indefinite article ("a" or "an") for a noun
    ///
    /// - Parameter noun: The noun to find an article for
    ///
    /// - Returns: Either "a" or "an" based on the noun's first letter
    private func articleFor(_ noun: String) -> String {
        let firstChar = noun.prefix(1).lowercased()
        if "aeiou".contains(firstChar) {
            return "an"
        } else {
            return "a"
        }
    }

    /// Finds a game object by name in the player's location or inventory
    ///
    /// - Parameter name: The name of the object to find
    ///
    /// - Returns: The game object if found, nil otherwise
    private func findObject(named name: String) -> GameObject? {
        // If "it" is used, return the last mentioned object
        if name.lowercased() == "it" {
            return world.lastMentionedObject
        }

        let player = world.player
        let currentRoom = player.currentRoom
        let nameToFind = name.lowercased()

        // Check player's inventory
        for obj in player.inventory {
            // Try exact match first
            if obj.name.lowercased() == nameToFind {
                world.lastMentionedObject = obj
                return obj
            }

            // Try partial match (for tests and user convenience)
            if nameToFind.contains(obj.name.lowercased())
                || obj.name.lowercased().contains(nameToFind)
            {
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
                if nameToFind.contains(obj.name.lowercased())
                    || obj.name.lowercased().contains(nameToFind)
                {
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
                        if nameToFind.contains(innerObj.name.lowercased())
                            || innerObj.name.lowercased().contains(nameToFind)
                        {
                            world.lastMentionedObject = innerObj
                            return innerObj
                        }
                    }
                }
            }

            // Check for global objects that are accessible in this room
            for globalObj in world.globalObjects {
                // Try exact match first
                if globalObj.name.lowercased() == nameToFind
                    && world.isGlobalObjectAccessible(globalObj, in: room)
                {
                    world.lastMentionedObject = globalObj
                    return globalObj
                }

                // Try partial match (for tests and user convenience)
                if (nameToFind.contains(globalObj.name.lowercased())
                    || globalObj.name.lowercased().contains(nameToFind))
                    && world.isGlobalObjectAccessible(globalObj, in: room)
                {
                    world.lastMentionedObject = globalObj
                    return globalObj
                }
            }
        }

        return nil
    }

    /// Finds a game object specifically in the player's inventory
    ///
    /// - Parameter name: The name of the object to find
    ///
    /// - Returns: The game object if found in inventory, nil otherwise
    private func findObjectInInventory(named name: String) -> GameObject? {
        // If "it" is used, return the last mentioned object if it is in the player's inventory
        if name.lowercased() == "it" {
            if let lastObj = world.lastMentionedObject,
                world.player.inventory.contains(where: { $0 === lastObj })
            {
                return lastObj
            }
            return nil
        }

        let nameToFind = name.lowercased()

        for obj in world.player.inventory {
            // Try exact match first
            if obj.name.lowercased() == nameToFind {
                world.lastMentionedObject = obj
                return obj
            }

            // Try partial match (for tests and user convenience)
            if nameToFind.contains(obj.name.lowercased())
                || obj.name.lowercased().contains(nameToFind)
            {
                world.lastMentionedObject = obj
                return obj
            }
        }

        return nil
    }
}
