import Foundation

/// A class responsible for parsing player input and converting it into game commands.
///
/// The parser analyzes text input, identifies verbs and objects, and returns the appropriate
/// `Command` enum value based on the recognized input pattern.
public class CommandParser {
    /// Reference to the game world containing all game objects and state
    private let world: GameWorld

    /// Temporary context storage for command processing
    private var currentDirection: Direction?
    private var targetContainer: GameObject?
    private var targetSurface: GameObject?

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
        guard !words.isEmpty else {
            return .unknown("No command given")
        }

        let firstWord = words[0]

        // Check for direction commands first (these are very common)
        if let direction = Direction(firstWord) {
            return .move(direction)
        }

        // Check for "go" + direction
        if words.count >= 2 && firstWord == "go" {
            if let direction = Direction(words[1]) {
                return .move(direction)
            }
        }

        // Match the first word against all command synonyms
        switch firstWord {
            // Movement
        case "move", "go", "walk", "run":
            if words.count >= 2, let direction = Direction(words[1]) {
        return .move(direction)
    }
            return .move(nil)

            // Look commands
        case "look", "l", "look-around":
            if words.count > 1 && words[1] == "at" && words.count > 2 {
                let objName = words.dropFirst(2).joined(separator: " ")
                let obj = findObject(named: objName)
                return .examine(obj)
            }
            return .look

        case "look-at", "examine", "x", "inspect":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
            return .examine(obj)
        }
            return .examine(nil)

        case "look-under":
            if words.count > 1 {
        let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .lookUnder(obj)
            }
            return .lookUnder(nil)

            // Inventory
        case "inventory", "i", "inv":
            return .inventory

            // Take/Get
        case "take", "get", "pick-up":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .take(obj)
            }
            return .take(nil)

            // Drop
        case "drop", "put-down":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .drop(obj)
            }
            return .drop(nil)

            // Open
        case "open":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .open(obj)
            }
            return .open(nil)

            // Close
        case "close", "shut":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .close(obj)
            }
            return .close(nil)

            // Put in/on
        case "put-in":
            if words.count >= 3 {
                // Format: put-in OBJ CONTAINER
                let objName = words[1]
                let containerName = words.dropFirst(2).joined(separator: " ")
                let obj = findObject(named: objName)
                let container = findObject(named: containerName)
                return .putIn(obj, container: container)
            }
            return .putIn(nil, container: nil)

        case "put-on", "place-on", "set-on":
            if words.count >= 3 {
                // Format: put-on OBJ SURFACE
                let objName = words[1]
                let surfaceName = words.dropFirst(2).joined(separator: " ")
                let obj = findObject(named: objName)
                let surface = findObject(named: surfaceName)
                return .putOn(obj, surface: surface)
            }
            return .putOn(nil, surface: nil)

            // Read
        case "read", "peruse":
            if words.count > 1 {
        let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .read(obj)
            }
            return .read(nil)

            // Turn on/off
        case "turn-on", "activate", "switch-on":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .turnOn(obj)
            }
            return .turnOn(nil)

        case "turn-off", "deactivate", "switch-off":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .turnOff(obj)
            }
            return .turnOff(nil)

            // Flip/Switch
        case "flip", "switch", "toggle":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .flip(obj)
            }
            return .flip(nil)

            // Wear
        case "wear", "don", "put-on":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .wear(obj)
            }
            return .wear(nil)

            // Unwear
        case "unwear", "remove", "doff", "take-off":
            if words.count > 1 {
        let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .unwear(obj)
            }
            return .unwear(nil)

            // Attack
        case "attack", "kill", "destroy":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .attack(obj)
            }
            return .attack(nil)

            // Lock/Unlock
        case "lock":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                // Look for "with" in the command
                if words.count > 3 && words[words.count-2] == "with" {
                    let toolName = words.last!
                    let tool = findObject(named: toolName)
                    return .lock(obj, with: tool)
                }
                return .lock(obj, with: nil)
            }
            return .lock(nil, with: nil)

        case "unlock":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                // Look for "with" in the command
                if words.count > 3 && words[words.count-2] == "with" {
                    let toolName = words.last!
                    let tool = findObject(named: toolName)
                    return .unlock(obj, with: tool)
                }
                return .unlock(obj, with: nil)
            }
            return .unlock(nil, with: nil)

            // Give
        case "give":
            if words.count >= 4 && words.contains("to") {
                let toIndex = words.firstIndex(of: "to")!
                let itemName = words[1..<toIndex].joined(separator: " ")
                let recipientName = words[(toIndex+1)...].joined(separator: " ")
                let item = findObject(named: itemName)
                let recipient = findObject(named: recipientName)
                return .give(item, to: recipient)
            }
            return .give(nil, to: nil)

            // Throw
        case "throw":
            if words.count >= 4 && words.contains("at") {
                let atIndex = words.firstIndex(of: "at")!
                let itemName = words[1..<atIndex].joined(separator: " ")
                let targetName = words[(atIndex+1)...].joined(separator: " ")
                let item = findObject(named: itemName)
                let target = findObject(named: targetName)
                return .throwAt(item, target: target)
            }
            return .throwAt(nil, target: nil)

            // Tell
        case "tell":
            if words.count >= 4 && words.contains("about") {
                let aboutIndex = words.firstIndex(of: "about")!
                let personName = words[1..<aboutIndex].joined(separator: " ")
                let topic = words[(aboutIndex+1)...].joined(separator: " ")
                let person = findObject(named: personName)
                return .tell(person, about: topic)
            }
            return .tell(nil, about: nil)

            // Meta commands without objects
        case "again", "g", "repeat":
            return .again
        case "brief":
            return .brief
        case "help", "?", "info":
            return .help
        case "quit", "q", "exit":
            return .quit
        case "restart":
            return .restart
        case "restore", "load":
            return .restore
        case "save":
            return .save
        case "script":
            return .script
        case "superbrief":
            return .superbrief
        case "undo":
            return .undo
        case "unscript":
            return .unscript
        case "verbose":
            return .verbose
        case "version":
            return .version
        case "wait":
            return .wait
        case "yes":
            return .yes
        case "no":
            return .no
        case "pronouns":
            return .pronouns

            // Simple actions without objects
        case "dance":
            return .dance
        case "jump":
            return .jump
        case "sing":
            return .sing
        case "swim":
            return .swim
        case "wave-hands":
            return .waveHands

            // More object commands
        case "burn", "light":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .burn(obj)
            }
            return .burn(nil)

        case "climb":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .climb(obj)
            }
            return .climb(nil)

        case "drink", "sip", "quaff":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .drink(obj)
            }
            return .drink(nil)

        case "eat", "consume", "devour":
            if words.count > 1 {
        let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .eat(obj)
            }
            return .eat(nil)

        case "empty":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .empty(obj)
            }
            return .empty(nil)

        case "fill":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .fill(obj)
            }
            return .fill(nil)

        case "pull":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .pull(obj)
            }
            return .pull(nil)

        case "push":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .push(obj)
            }
            return .push(nil)

        case "rub":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .rub(obj)
            }
            return .rub(nil)

        case "search":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .search(obj)
            }
            return .search(nil)

        case "smell":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .smell(obj)
            }
            return .smell(nil)

        case "think-about", "ponder", "contemplate":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .thinkAbout(obj)
            }
            return .thinkAbout(nil)

        case "wake":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .wake(obj)
            }
            return .wake(nil)

        case "wave":
            if words.count > 1 {
        let objName = words.dropFirst().joined(separator: " ")
                let obj = findObject(named: objName)
                return .wave(obj)
            }
            return .wave(nil)

            // Custom commands not recognized
        default:
            return .custom(words)
        }
    }

    /// Gets the current direction for a move command
    ///
    /// - Returns: The direction if available
    public func getCurrentDirection() -> Direction? {
        return currentDirection
    }

    /// Gets the target container for a putIn command
    ///
    /// - Returns: The target container if available
    public func getTargetContainer() -> GameObject? {
        return targetContainer
    }

    /// Gets the target surface for a putOn command
    ///
    /// - Returns: The target surface if available
    public func getTargetSurface() -> GameObject? {
        return targetSurface
    }

    // MARK: - Helper methods

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
                return obj
            }

            // Try partial match (for tests and user convenience)
            if nameToFind.contains(obj.name.lowercased())
                || obj.name.lowercased().contains(nameToFind)
            {
                return obj
            }
        }

        // Check current room
        if let room = currentRoom {
            for obj in room.contents where obj !== player {
                // Try exact match first
                if obj.name.lowercased() == nameToFind {
                    return obj
                }

                // Try partial match (for tests and user convenience)
                if nameToFind.contains(obj.name.lowercased())
                    || obj.name.lowercased().contains(nameToFind)
                {
                    return obj
                }

                // Check inside visible containers in the room
                if obj.hasFlags(.isContainer, .isOpen) || obj.hasFlag(.isTransparent) {
                    for innerObj in obj.contents {
                        // Try exact match first
                        if innerObj.name.lowercased() == nameToFind {
                            return innerObj
                        }

                        // Try partial match (for tests and user convenience)
                        if nameToFind.contains(innerObj.name.lowercased())
                            || innerObj.name.lowercased().contains(nameToFind)
                        {
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
                    return globalObj
                }

                // Try partial match (for tests and user convenience)
                if (nameToFind.contains(globalObj.name.lowercased())
                    || globalObj.name.lowercased().contains(nameToFind))
                    && world.isGlobalObjectAccessible(globalObj, in: room)
                {
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
                return obj
            }

            // Try partial match (for tests and user convenience)
            if nameToFind.contains(obj.name.lowercased())
                || obj.name.lowercased().contains(nameToFind)
            {
                return obj
            }
        }

        return nil
    }
}
