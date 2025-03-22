import Foundation

/// A class responsible for parsing player input and converting it into game commands.
///
/// The parser analyzes text input, identifies verbs and objects, and returns the appropriate
/// `Command` enum value based on the recognized input pattern.
struct CommandParser {
    // Temporary context storage for command processing
    private(set) var currentDirection: Direction?
    private(set) var targetContainer: GameObject?
    private(set) var targetSurface: GameObject?

    /// Initializes a new command parser with a reference to the game world
    ///
    /// - Parameter world: The game world that contains objects to be referenced in
    /// //    public init(for world: GameWorld) {
    //        self.world = world
    //    }

    /// Parses a string input from the player and converts it to a Command
    ///
    /// - Parameter input: The raw text input from the player
    ///
    /// - Returns: A Command representing the action to be taken
    func parse(
        _ input: String,
        in world: GameWorld
    ) -> Command {
        // Normalize input
        let normalizedInput = input.lowercased().trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Handle empty input
        if normalizedInput.isEmpty {
            return .unknown("No command given")
        }

        // Split into words
        let words = normalizedInput.components(
            separatedBy: .whitespacesAndNewlines
        )
            .filter { !$0.isEmpty }

        // Early return if no words
        guard !words.isEmpty else {
            return .unknown("No command given")
        }

        // 1. Handle single-word commands first (these are common and simple)
        if words.count == 1 {
            return parseSingleWordCommand(words[0])

        }

        // 2. Process natural language

        // Extract the verb (first word)
        let verb = words[0]

        // Handle different verb patterns
        switch verb {
            // MARK: Attack
        case "attack", "kill", "destroy":
            return if words.count > 1 {
                parseCommandWithTool(
                    Array(words.dropFirst()),
                    commandType: "attack",
                    in: world
                )
            } else {
                .attack(nil)
            }

            // MARK: Close
        case "close", "shut":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .close(obj)
            }
            return .close(nil)

            // MARK: Drop
        case "drop":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .drop(obj)
            }
            return .drop(nil)

            // MARK: Examine
        case "examine", "x", "inspect":
            return if words.count > 1 {
                parseCommandWithTool(
                    Array(words.dropFirst()),
                    commandType: "examine",
                    in: world
                )
            } else {
                .examine(nil)
            }

            // MARK: Look/Examine
        case "look":
            if words.count > 1 && words[1] == "at" && words.count > 2 {
                return parseCommandWithTool(
                    Array(words.dropFirst(2)),
                    commandType: "examine",
                    in: world
                )
            } else if words.count > 1 && words[1] == "under" && words.count > 2 {
                let objName = words.dropFirst(2).joined(separator: " ")
                let obj = find(objName, in: world)
                return .lookUnder(obj)
            }
            return .look

            // MARK: Movement related
        case "move", "walk", "run", "go":
            if words.count >= 2, let direction = Direction(words[1]) {
                return .move(direction)
            }
            return .move(nil)

            // MARK: Open
        case "open":
            return if words.count > 1 {
                parseCommandWithTool(
                    Array(words.dropFirst()),
                    commandType: "open",
                    in: world
                )
            } else {
                .open(nil)
            }

            // MARK: Put
        case "put", "place", "set":
            return parsePutCommand(words, in: world)

            // MARK: Read
        case "read", "peruse":
            return if words.count > 1 {
                parseCommandWithTool(
                    Array(words.dropFirst()),
                    commandType: "read",
                    in: world
                )
            } else {
                .read(nil)
            }

            // MARK: Take/Get
        case "take", "get", "grab", "pick":
            if words.count > 1 {
                // Check for "pick up" pattern
                if words.count >= 3 && words[1] == "up" {
                    let objName = words.dropFirst(2).joined(separator: " ")
                    let obj = find(objName, in: world)
                    return .take(obj)
                }

                // Check for "take off" pattern (for removing worn items)
                if words.count >= 3 && words[1] == "off" {
                    let objName = words.dropFirst(2).joined(separator: " ")
                    let obj = find(objName, in: world)
                    return .unwear(obj)
                }

                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .take(obj)
            }
            return .take(nil)

            // MARK: Turn on/off
        case "turn":
            // Natural language "turn on/off"
            if words.count > 2 {
                if words[1] == "on" {
                    let objName = words.dropFirst(2).joined(separator: " ")
                    let obj = find(objName, in: world)
                    return .turnOn(obj)
                } else if words[1] == "off" {
                    let objName = words.dropFirst(2).joined(separator: " ")
                    let obj = find(objName, in: world)
                    return .turnOff(obj)
                }
            } else if words.count == 2 {
                if words[1] == "on" {
                    return .turnOn(nil)
                } else if words[1] == "off" {
                    return .turnOff(nil)
                }
            }
            return .custom(words)

        case "turn-on", "activate", "switch-on":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .turnOn(obj)
            }
            return .turnOn(nil)

        case "turn-off", "deactivate", "switch-off":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .turnOff(obj)
            }
            return .turnOff(nil)

            // MARK: Flip/Switch
        case "flip", "switch", "toggle":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .flip(obj)
            }
            return .flip(nil)

            // MARK: Wear
        case "wear", "don":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .wear(obj)
            }
            return .wear(nil)

            // MARK: Unwear
        case "unwear", "remove", "doff", "take-off":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .unwear(obj)
            }
            return .unwear(nil)

            // MARK: Lock/Unlock
        case "lock":
            return if words.count > 1 {
                parseCommandWithTool(
                    Array(words.dropFirst()),
                    commandType: "lock",
                    in: world
                )
            } else {
                .lock(nil)
            }

        case "unlock":
            return if words.count > 1 {
                parseCommandWithTool(
                    Array(words.dropFirst()),
                    commandType: "unlock",
                    in: world
                )
            } else {
                .unlock(nil)
            }

            // MARK: Give
        case "give":
            return parseGiveCommand(words, in: world)

            // MARK: Throw
        case "throw":
            return parseThrowCommand(words, in: world)

            // MARK: Tell
        case "tell":
            return parseTellCommand(words, in: world)

            // MARK: More object
        case "burn", "light":
            return if words.count > 1 {
                parseCommandWithTool(
                    Array(words.dropFirst()),
                    commandType: "burn",
                    in: world
                )
            } else {
                .burn(nil)
            }

        case "climb":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .climb(obj)
            }
            return .climb(nil)

        case "drink", "sip", "quaff":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .drink(obj)
            }
            return .drink(nil)

        case "eat", "consume", "devour":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .eat(obj)
            }
            return .eat(nil)

        case "empty":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .empty(obj)
            }
            return .empty(nil)

        case "fill":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .fill(obj)
            }
            return .fill(nil)

        case "pull":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .pull(obj)
            }
            return .pull(nil)

        case "push":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .push(obj)
            }
            return .push(nil)

        case "rub":
            return if words.count > 1 {
                parseCommandWithTool(
                    Array(words.dropFirst()),
                    commandType: "rub",
                    in: world
                )
            } else {
                .rub(nil)
            }

        case "search":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .search(obj)
            }
            return .search(nil)

        case "smell":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .smell(obj)
            }
            return .smell(nil)

        case "think-about", "ponder", "contemplate":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .thinkAbout(obj)
            }
            return .thinkAbout(nil)

        case "wake":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .wake(obj)
            }
            return .wake(nil)

        case "wave":
            if words.count > 1 {
                let objName = words.dropFirst().joined(separator: " ")
                let obj = find(objName, in: world)
                return .wave(obj)
            }
            return .wave(nil)

        case "wave-hands":
            return .waveHands

        default:
            return .custom(words)
        }
    }
}

// MARK: - Command parsing helpers

extension CommandParser {
    /// Generic helper for commands that include a "with" clause for a tool
    private func parseCommandWithTool(
        _ words: [String],
        commandType: String,
        in world: GameWorld
    ) -> Command {
        if words.isEmpty {
            // Handle empty input
            return switch commandType {
            case "attack": .attack(nil)
            case "burn": .burn(nil)
            case "examine": .examine(nil)
            case "lock": .lock(nil)
            case "open": .open(nil)
            case "read": .read(nil)
            case "rub": .rub(nil)
            case "unlock": .unlock(nil)
            default: .custom([])
            }
        }

        // Check for "with" preposition
        if let withIndex = words.firstIndex(of: "with"), withIndex < words.count - 1 {
            let objName = words[0..<withIndex].joined(separator: " ")
            let toolName = words[(withIndex + 1)...].joined(separator: " ")

            let obj = find(objName, in: world)
            let tool = find(toolName, in: world)

            return switch commandType {
            case "attack": .attack(obj, with: tool)
            case "burn": .burn(obj, with: tool)
            case "examine": .examine(obj, with: tool)
            case "lock": .lock(obj, with: tool)
            case "open": .open(obj, with: tool)
            case "read": .read(obj, with: tool)
            case "rub": .rub(obj, with: tool)
            case "unlock": .unlock(obj, with: tool)
            default: .custom(words)
            }
        }

        // No "with" clause found
        let objName = words.joined(separator: " ")
        let obj = find(objName, in: world)

        return switch commandType {
        case "attack": .attack(obj)
        case "burn": .burn(obj)
        case "examine": .examine(obj)
        case "lock": .lock(obj)
        case "open": .open(obj)
        case "read": .read(obj)
        case "rub": .rub(obj)
        case "unlock": .unlock(obj)
        default: .custom(words)
        }
    }

    /// Parses an attack command, checking for "with" clause
    //    private func parseAttackCommand(
    //        words: [String],
    //        in world: GameWorld
    //    ) -> Command {
    //        parseCommandWithTool(words, commandType: "attack", in: world)
    //    }
    //
    //    /// Parses a burn command, checking for "with" clause
    //    private func parseBurnCommand(
    //        words: [String],
    //        in world: GameWorld
    //    ) -> Command {
    //        parseCommandWithTool(words, commandType: "burn", in: world)
    //    }
    //
    //    /// Parses an examine command, checking for "with" clause
    //    private func parseExamineCommand(
    //        words: [String],
    //        in world: GameWorld
    //    ) -> Command {
    //        parseCommandWithTool(words, commandType: "examine", in: world)
    //    }
    //
    //    /// Parses a lock command, checking for "with" clause
    //    //    private func parseLockCommand(
    //    //        words: [String],
    //    //        in world: GameWorld
    //    //    ) -> Command {
    //    //        parseCommandWithTool(words, commandType: "lock", in: world)
    //    //    }
    //
    //    /// Parses an open command, checking for "with" clause
    //    //    private func parseOpenCommand(
    //    //        words: [String],
    //    //        in world: GameWorld
    //    //    ) -> Command {
    //    //        parseCommandWithTool(words, commandType: "open", in: world)
    //    //    }
    //
    //    /// Parses a read command, checking for "with" clause
    //    private func parseReadCommand(
    //        words: [String],
    //        in world: GameWorld
    //    ) -> Command {
    //        parseCommandWithTool(words, commandType: "read", in: world)
    //    }
    //
    //    /// Parses a rub command, checking for "with" clause
    //    private func parseRubCommand(
    //        words: [String],
    //        in world: GameWorld
    //    ) -> Command {
    //        parseCommandWithTool(words, commandType: "rub", in: world)
    //    }
    //
    //    /// Parses an unlock command, checking for "with" clause
    //    private func parseUnlockCommand(
    //        words: [String],
    //        in world: GameWorld
    //    ) -> Command {
    //        parseCommandWithTool(words, commandType: "unlock", in: world)
    //    }

    /// Parses a give command, checking for "to" structure.
    private func parseGiveCommand(
        _ words: [String],
        in world: GameWorld
    ) -> Command {
        if words.count >= 4 {
            // Check for "to" preposition
            if let toIndex = words.firstIndex(of: "to"), toIndex > 1 {
                let itemName = words[1..<toIndex].joined(separator: " ")
                let recipientName = words[(toIndex + 1)...].joined(separator: " ")

                let item = find(itemName, in: world)
                let recipient = find(recipientName, in: world)

                return .give(item, to: recipient)
            }
        }
        return .give(nil, to: nil)
    }

    /// Parses a put command with natural language support
    private func parsePutCommand(
        _ words: [String],
        in world: GameWorld
    ) -> Command {
        // Early return for just "put" with no other words
        if words.count == 1 {
            return .custom(words)
        }

        // Special case for "put down" meaning "drop"
        if words.count >= 3 && words[1] == "down" {
            let objectPhrase = words.dropFirst(2).joined(separator: " ")
            let object = find(objectPhrase, in: world)
            return .drop(object)
        }

        // Special case for "put on X" - this should be a wear command
        if words.count >= 3 && words[1] == "on" {
            let objName = words.dropFirst(2).joined(separator: " ")
            if let obj = find(objName, in: world) {
                return .wear(obj)
            }
            return .wear(nil)
        }

        // Special case for "put X on" - this should also be a wear command
        if words.count >= 3 && words[words.count - 1] == "on" {
            let objName = words.dropFirst(1).dropLast().joined(separator: " ")
            if let obj = find(objName, in: world) {
                return .wear(obj)
            }
            return .wear(nil)
        }

        // Helper closure to extract preposition position and type
        func findPrepositionInfo() -> (index: Int, type: String)? {
            for (index, word) in words.enumerated().dropFirst() {
                if ["in", "into", "inside"].contains(word) {
                    return (index, "in")
                } else if ["on", "onto", "atop"].contains(word) {
                    return (index, "on")
                }
            }
            return nil
        }

        // Find first preposition
        if let (prepositionIndex, prepositionType) = findPrepositionInfo(), prepositionIndex > 0 {
            let objectPhrase = words[1..<prepositionIndex].joined(separator: " ")
            let containerPhrase = words[(prepositionIndex + 1)...].joined(separator: " ")

            let object = find(objectPhrase, in: world)
            let container = find(containerPhrase, in: world)

            if prepositionType == "in" {
                return .putIn(object, container: container)
            } else if prepositionType == "on" {
                return .putOn(object, surface: container)
            }
        }

        // Handle the case where just an object is specified, like "put object"
        if words.count >= 2 {
            // We store it as custom since we don't know what to do with it yet
            return .custom(words)
        }

        return .custom(words)
    }

    private func parseSingleWordCommand(_ command: String) -> Command {
        switch command {
        case "look", "l": .look
        case "inventory", "i", "inv": .inventory
        case "wait", "z": .wait
        case "again", "g", "repeat": .again
        case "brief": .brief
        case "help", "?", "info": .help
        case "quit", "q", "exit": .quit
        case "restart": .restart
        case "restore", "load": .restore
        case "save": .save
        case "script": .script
        case "superbrief": .superbrief
        case "undo": .undo
        case "unscript": .unscript
        case "verbose": .verbose
        case "version": .version
        case "dance": .dance
        case "jump": .jump
        case "sing": .sing
        case "swim": .swim
        case "pronouns": .pronouns
        case "yes": .yes
        case "no": .no
        case "examine", "x": .examine(nil)
        case "take", "get": .take(nil)
        case "drop": .drop(nil)
        case "open": .open(nil)
        case "close", "shut": .close(nil)
        case "read", "peruse": .read(nil)
        case "flip", "switch", "toggle": .flip(nil)
        case "wear", "don": .wear(nil)
        case "unwear", "remove", "doff": .unwear(nil)
        case "go": .move(nil)
        default:
            if let direction = Direction(command) {
                .move(direction)
            } else {
                .custom([command])
            }
        }
    }

    /// Parses a tell command, checking for "about" structure.
    private func parseTellCommand(
        _ words: [String],
        in world: GameWorld
    ) -> Command {
        if words.count >= 4 {
            // Check for "about" preposition
            if let aboutIndex = words.firstIndex(of: "about"), aboutIndex > 1 {
                let personName = words[1..<aboutIndex].joined(separator: " ")
                let topic = words[(aboutIndex + 1)...].joined(separator: " ")

                let person = find(personName, in: world)

                return .tell(person, about: topic)
            }
        }
        return .tell(nil, about: nil)
    }

    /// Parses a throw command, checking for "at" structure.
    private func parseThrowCommand(
        _ words: [String],
        in world: GameWorld
    ) -> Command {
        if words.count >= 4 {
            // Check for "at" preposition
            if let atIndex = words.firstIndex(of: "at"), atIndex > 1 {
                let itemName = words[1..<atIndex].joined(separator: " ")
                let targetName = words[(atIndex + 1)...].joined(separator: " ")

                let item = find(itemName, in: world)
                let target = find(targetName, in: world)

                return .throwAt(item, target: target)
            }
        }
        return .throwAt(nil, target: nil)
    }
}

// MARK: - Helper methods

extension CommandParser {
    /// Finds a game object by name in the player's location or inventory, with support for
    /// natural language patterns like "the golden key".
    ///
    /// - Parameter description: The description of the object to find.
    ///
    /// - Returns: The game object if found, or `nil` otherwise.
    private func find(
        _ description: String,
        in world: GameWorld
    ) -> GameObject? {
        // Clean the description by removing articles
        let cleanDescription = removeArticles(from: description)

        // If the cleaned description is empty, return nil
        if cleanDescription.isEmpty {
            return nil
        }

        // If "it" is used, return the last mentioned object
        if cleanDescription.lowercased() == "it" {
            return world.lastMentionedObject
        }

        // Get objects in scope (inventory + visible in room)
        let objectsInScope = getObjectsInScope(in: world)

        // Try exact match first (checking both primary name and synonyms)
        for obj in objectsInScope {
            if obj.matchesName(cleanDescription) {
                return obj
            }
        }

        // Try partial match if contains all words in sequence
        for obj in objectsInScope {
            let objNameLower = obj.name.lowercased()
            if objNameLower.contains(cleanDescription.lowercased()) {
                return obj
            }

            // Also check synonyms for partial matches
            for synonym in obj.synonyms {
                if synonym.lowercased().contains(cleanDescription.lowercased()) {
                    return obj
                }
            }
        }

        // Try matching if all words in cleanDescription appear in the object name
        let descriptionWords = cleanDescription.lowercased().components(
            separatedBy: .whitespacesAndNewlines)

        outer: for obj in objectsInScope {
            let objName = obj.name.lowercased()

            // First check primary name
            var allWordsFound = true
            for word in descriptionWords {
                if !objName.contains(word) {
                    allWordsFound = false
                    break
                }
            }

            if allWordsFound {
                return obj
            }

            // Then check each synonym
            for synonym in obj.synonyms {
                let synonymLower = synonym.lowercased()

                allWordsFound = true
                for word in descriptionWords {
                    if !synonymLower.contains(word) {
                        allWordsFound = false
                        break
                    }
                }

                if allWordsFound {
                    return obj
                }
            }
        }

        // As a fallback, try finding if any object name or synonym contains the first word of the description
        if let firstWord = descriptionWords.first, !firstWord.isEmpty {
            for obj in objectsInScope {
                if obj.name.lowercased().contains(firstWord) {
                    return obj
                }

                // Check synonyms too
                for synonym in obj.synonyms {
                    if synonym.lowercased().contains(firstWord) {
                        return obj
                    }
                }
            }
        }

        return nil
    }

    /// Get all objects that are visible to the player
    private func getObjectsInScope(in world: GameWorld) -> [GameObject] {
        var objectsInScope: [GameObject] = []
        let player = world.player
        let currentRoom = player.currentRoom

        // Add objects in player's inventory
        objectsInScope.append(contentsOf: player.inventory)

        // Add objects in the current room
        if let room = currentRoom {
            // Add objects directly in the room
            for obj in room.contents where obj !== player {
                objectsInScope.append(obj)

                // Add objects in visible containers
                if obj.hasFlags(.isContainer, .isOpen) || obj.hasFlag(.isTransparent) {
                    objectsInScope.append(contentsOf: obj.contents)
                }
            }

            // Add global objects accessible in this room
            for globalObj in world.globalObjects
            where world.isGlobalObjectAccessible(globalObj, in: room) {
                objectsInScope.append(globalObj)
            }
        }

        return objectsInScope
    }

    /// Removes articles like "the", "a", "an" from a phrase
    private func removeArticles(from phrase: String) -> String {
        let words = phrase.components(separatedBy: .whitespacesAndNewlines)
        let articlesToRemove = ["the", "a", "an"]

        let filteredWords = words.filter { !articlesToRemove.contains($0.lowercased()) }
        return filteredWords.joined(separator: " ")
    }
}
