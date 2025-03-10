import Testing

@testable import ZILFCore

struct CommandParserTests {
    // MARK: - Core Command Tests

    @Test func closeCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a closeable object
        let box = GameObject(
            name: "box",
            description: "A wooden box",
            location: world.player.currentRoom,
            flags: [.isContainer, .isOpen]
        ) // Start opened

        // Test basic close command
        if case let .close(obj) = parser.parse("close box") {
            #expect(obj === box)
        } else {
            throw TestFailure("Expected close command")
        }

        // Test with article
        if case let .close(obj) = parser.parse("close the box") {
            #expect(obj === box)
        } else {
            throw TestFailure("Expected close command")
        }

        // Test no object specified
        if case let .unknown(message) = parser.parse("close") {
            #expect(message == "Close what?")
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test non-existent object
        if case let .unknown(message) = parser.parse("close unicorn") {
            #expect(message.contains("I don't see"))
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func directionCommands() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        // Test full direction names
        if case let .move(direction) = parser.parse("north") {
            #expect(direction == .north)
        } else {
            throw TestFailure("Expected move command")
        }

        // Test abbreviated directions
        if case let .move(direction) = parser.parse("s") {
            #expect(direction == .south)
        } else {
            throw TestFailure("Expected move command")
        }

        if case let .move(direction) = parser.parse("e") {
            #expect(direction == .east)
        } else {
            throw TestFailure("Expected move command")
        }

        if case let .move(direction) = parser.parse("w") {
            #expect(direction == .west)
        } else {
            throw TestFailure("Expected move command")
        }

        if case let .move(direction) = parser.parse("u") {
            #expect(direction == .up)
        } else {
            throw TestFailure("Expected move command")
        }

        if case let .move(direction) = parser.parse("d") {
            #expect(direction == .down)
        } else {
            throw TestFailure("Expected move command")
        }

        // Test 'go' command
        if case let .move(direction) = parser.parse("go east") {
            #expect(direction == .east)
        } else {
            throw TestFailure("Expected move command")
        }

        // Test invalid direction
        if case let .unknown(message) = parser.parse("go nowhere") {
            #expect(message.contains("Go where?"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test go with no direction
        if case let .unknown(message) = parser.parse("go") {
            #expect(message.contains("Go where?"))
        } else {
            throw TestFailure("Expected unknown command for 'go' with no direction")
        }
    }

    @Test func dropCommands() throws {
        let (world, parser, _, _, coin) = try setupTestWorld()

        // First take the coin so we can drop it
        coin.moveTo(world.player)

        // Test drop object
        if case let .drop(obj) = parser.parse("drop coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected drop command")
        }

        // Test drop with full name
        if case let .drop(obj) = parser.parse("drop gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected drop command")
        }

        // Test drop with article
        if case let .drop(obj) = parser.parse("drop the gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected drop command")
        }

        // Remove coin from inventory to test error case
        world.player.removeAll()
        coin.moveTo(world.player.currentRoom)

        // Test drop non-carried object
        if case let .unknown(message) = parser.parse("drop coin") {
            #expect(message.contains("You're not carrying"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test dropping with no object specified
        if case let .unknown(message) = parser.parse("drop") {
            #expect(message == "Drop what?")
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func examineCommands() throws {
        let (_, parser, _, _, coin) = try setupTestWorld()

        // Test examine with object
        if case let .examine(obj, _) = parser.parse("examine gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test examine with abbreviated syntax
        if case let .examine(obj, _) = parser.parse("x coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test look at syntax
        if case let .examine(obj, _) = parser.parse("look at gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test with article
        if case let .examine(obj, _) = parser.parse("examine the gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test with non-existent object
        if case let .unknown(message) = parser.parse("examine unicorn") {
            #expect(message.contains("I don't see"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test examine with no object
        if case let .unknown(message) = parser.parse("examine") {
            #expect(message == "Examine what?")
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test x with no object
        if case let .unknown(message) = parser.parse("x") {
            #expect(message == "Examine what?")
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func flipCommands() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a device
        let lamp = GameObject(
            name: "lamp",
            description: "A brass lamp",
            location: world.player.currentRoom,
            flags: .isDevice
        )

        // Test flip command
        if case let .flip(parsedLamp) = parser.parse("flip lamp") {
            #expect(parsedLamp === lamp)
        } else {
            throw TestFailure("Expected flip command")
        }

        // Test switch command
        if case let .flip(parsedLamp) = parser.parse("switch lamp") {
            #expect(parsedLamp === lamp)
        } else {
            throw TestFailure("Expected flip command")
        }

        // Test toggle command
        if case let .flip(parsedLamp) = parser.parse("toggle lamp") {
            #expect(parsedLamp === lamp)
        } else {
            throw TestFailure("Expected flip command")
        }

        // Test with non-device item
        let book = GameObject(
            name: "book",
            description: "A heavy book",
            location: world.player.currentRoom
        )

        if case let .unknown(message) = parser.parse("flip book") {
            #expect(message.contains("You can't flip"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test with no object
        if case let .unknown(message) = parser.parse("flip") {
            #expect(message == "Flip what?")
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func inventoryCommand() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        if case .inventory = parser.parse("inventory") {
            // Success
        } else {
            throw TestFailure("Expected inventory command")
        }

        if case .inventory = parser.parse("i") {
            // Success
        } else {
            throw TestFailure("Expected inventory command")
        }

        // Test take inventory variant
        if case .inventory = parser.parse("take inventory") {
            // Success
        } else {
            throw TestFailure("Expected inventory command for 'take inventory'")
        }
    }

    @Test func itReferences() throws {
        let (world, parser, _, _, coin) = try setupTestWorld()

        // First set the last mentioned object
        world.lastMentionedObject = coin

        // Test examine it
        if case let .examine(obj, _) = parser.parse("examine it") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected examine command with 'it' reference")
        }

        // Test take it
        if case let .take(obj) = parser.parse("take it") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected take command with 'it' reference")
        }

        // Test with no last mentioned object
        world.lastMentionedObject = nil
        if case let .unknown(message) = parser.parse("examine it") {
            #expect(message.contains("I don't know what 'it' refers to"))
        } else {
            throw TestFailure("Expected unknown command for 'it' with no reference")
        }
    }

    @Test func lookCommand() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        let command = parser.parse("look")
        if case .look = command {
            // Success
        } else {
            throw TestFailure("Expected look command")
        }

        // Test 'l' abbreviation
        let lCommand = parser.parse("l")
        if case .look = lCommand {
            // Success
        } else {
            throw TestFailure("Expected look command for 'l'")
        }
    }

    @Test func metaAgainCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .again = parser.parse("again") else {
            throw TestFailure("Failed to parse `again`")
        }
        guard case .again = parser.parse("g") else {
            throw TestFailure("Failed to parse `again` from `g`")
        }
    }

    @Test func metaBriefCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .brief = parser.parse("brief") else {
            throw TestFailure("Failed to parse `brief`")
        }
    }

    @Test func metaRestartCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .restart = parser.parse("restart") else {
            throw TestFailure("Failed to parse `restart`")
        }
    }

    @Test func metaRestoreCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .restore = parser.parse("restore") else {
            throw TestFailure("Failed to parse `restore`")
        }
    }

    @Test func metaSaveCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .save = parser.parse("save") else {
            throw TestFailure("Failed to parse `save`")
        }
    }

    @Test func metaSuperbriefCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .superbrief = parser.parse("superbrief") else {
            throw TestFailure("Failed to parse `superbrief`")
        }
    }

    @Test func metaUndoCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .undo = parser.parse("undo") else {
            throw TestFailure("Failed to parse `undo`")
        }
    }

    @Test func metaVerboseCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .verbose = parser.parse("verbose") else {
            throw TestFailure("Failed to parse `verbose`")
        }
    }

    @Test func metaVersionCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .version = parser.parse("version") else {
            throw TestFailure("Failed to parse `version`")
        }
    }

    @Test func metaWaitCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        guard case .wait = parser.parse("wait") else {
            throw TestFailure("Failed to parse `wait`")
        }
        guard case .wait = parser.parse("z") else {
            throw TestFailure("Failed to parse `wait` from `z`")
        }
    }

    @Test func openCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create an openable object
        let box = GameObject(
            name: "box",
            description: "A wooden box",
            location: world.player.currentRoom,
            flags: .isContainer
        )

        // Test basic open command
        if case let .open(obj, _) = parser.parse("open box") {
            #expect(obj === box)
        } else {
            throw TestFailure("Expected open command")
        }

        // Test with article
        if case let .open(obj, _) = parser.parse("open the box") {
            #expect(obj === box)
        } else {
            throw TestFailure("Expected open command")
        }

        // Test no object specified
        if case let .unknown(message) = parser.parse("open") {
            #expect(message == "Open what?")
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test non-existent object
        if case let .unknown(message) = parser.parse("open unicorn") {
            #expect(message.contains("I don't see"))
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func putCommands() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create items for testing
        let apple = GameObject(
            name: "apple",
            description: "A red apple",
            location: world.player,
            flags: .isTakable
        )

        let box = GameObject(
            name: "box",
            description: "A wooden box",
            location: world.player.currentRoom,
            flags: .isContainer
        )

        let table = GameObject(
            name: "table",
            description: "A wooden table",
            location: world.player.currentRoom
        )

        // Test "put X in Y"
        if case let .putIn(parsedApple, container: parsedBox) = parser.parse("put apple in box") {
            #expect(parsedApple === apple)
            #expect(parsedBox === box)
        } else {
            throw TestFailure("Expected put-in command")
        }

        // Test "put X on Y"
        if case let .putOn(parsedApple, surface: parsedTable) = parser.parse("put apple on table") {
            #expect(parsedApple === apple)
            #expect(parsedTable === table)
        } else {
            throw TestFailure("Expected put-on command")
        }

        // Test "put X" (incomplete)
        if case let .unknown(message) = parser.parse("put apple") {
            #expect(message.contains("Put what where?"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test "put" (incomplete)
        if case let .unknown(message) = parser.parse("put") {
            #expect(message.contains("Put what where?"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test put with non-existent object
        if case let .unknown(message) = parser.parse("put unicorn in box") {
            #expect(message.contains("I don't see"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        if case let .unknown(message) = parser.parse("put apple in unicorn") {
            #expect(message.contains("I don't see"))
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func quitCommand() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        if case .quit = parser.parse("quit") {
            // Success
        } else {
            throw TestFailure("Expected quit command")
        }

        if case .quit = parser.parse("q") {
            // Success
        } else {
            throw TestFailure("Expected quit command")
        }
    }

    @Test func readCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a readable object
        let book = GameObject(
            name: "book",
            description: "A dusty book",
            location: world.player.currentRoom,
            flags: .isReadable
        )

        // Test read command
        if case let .read(parsedBook, with: _) = parser.parse("read book") {
            #expect(parsedBook === book)
        } else {
            throw TestFailure("Expected read command")
        }

        // Test peruse command
        if case let .read(parsedBook, with: _) = parser.parse("peruse book") {
            #expect(parsedBook === book)
        } else {
            throw TestFailure("Expected read command")
        }

        // Test with non-readable item
        let rock = GameObject(
            name: "rock",
            description: "A gray rock",
            location: world.player.currentRoom
        )

        if case let .unknown(message) = parser.parse("read rock") {
            #expect(message.contains("nothing to read"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test with no object
        if case let .unknown(message) = parser.parse("read") {
            #expect(message == "Read what?")
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func removeCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a wearable item
        let hat = GameObject(
            name: "hat",
            description: "A fancy hat",
            location: world.player,
            flags: [.isWearable, .isBeingWorn]  // Mark as currently worn
        )

        // Test "remove hat" command
        if case let .unwear(parsedHat) = parser.parse("remove hat") {
            #expect(parsedHat === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test "doff hat" command
        if case let .unwear(parsedHat) = parser.parse("doff hat") {
            #expect(parsedHat === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test with article
        if case let .unwear(parsedHat) = parser.parse("remove the hat") {
            #expect(parsedHat === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test when not wearing the item
        hat.clearFlag(.isBeingWorn)
        if case let .unknown(message) = parser.parse("remove hat") {
            #expect(message.contains("not wearing"))
        } else {
            throw TestFailure("Expected error about not wearing the item")
        }

        // Test when item not in inventory
        world.player.removeAll()
        if case let .unknown(message) = parser.parse("remove hat") {
            #expect(message.contains("don't have"))
        } else {
            throw TestFailure("Expected error about not having the item")
        }

        // Test with no object specified
        if case let .unknown(message) = parser.parse("remove") {
            #expect(message == "Remove what?")
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func takeCommands() throws {
        let (_, parser, _, _, coin) = try setupTestWorld()

        // Test take object
        if case let .take(obj) = parser.parse("take gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected take command")
        }

        // Test take with article
        if case let .take(obj) = parser.parse("take the gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected take command")
        }

        // Test get synonym
        if case let .take(obj) = parser.parse("get coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected take command")
        }

        // Test with no object specified
        if case let .unknown(message) = parser.parse("take") {
            #expect(message == "Take what?")
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test with non-existent object
        if case let .unknown(message) = parser.parse("take unicorn") {
            #expect(message.contains("I don't see"))
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func takeOffCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a wearable item for testing
        let hat = GameObject(
            name: "hat",
            description: "A fancy hat",
            location: world.player,
            flags: [.isWearable, .isBeingWorn]  // Mark as currently worn
        )

        // Test basic "take off hat" command
        if case let .unwear(parsedHat) = parser.parse("take off hat") {
            #expect(parsedHat === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test with article "take off the hat"
        if case let .unwear(parsedHat) = parser.parse("take off the hat") {
            #expect(parsedHat === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test with alternative phrasing "take the hat off"
        if case let .unwear(parsedHat) = parser.parse("take the hat off") {
            #expect(parsedHat === hat)
        } else {
            throw TestFailure("Expected unwear command for 'take the hat off'")
        }

        // Test when not wearing the item
        hat.clearFlag(.isBeingWorn)
        if case let .unknown(message) = parser.parse("take off hat") {
            #expect(message.contains("not wearing"))
        } else {
            throw TestFailure("Expected error about not wearing the item")
        }

        // Test when item not in inventory
        world.player.removeAll()
        if case let .unknown(message) = parser.parse("take off hat") {
            #expect(message.contains("don't have"))
        } else {
            throw TestFailure("Expected error about not having the item")
        }
    }

    @Test func takeOffCommandPrecedence() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a wearable item for testing
        let hat = GameObject(
            name: "hat",
            description: "A fancy hat",
            location: world.player,
            flags: [.isWearable, .isBeingWorn]  // Mark as currently worn
        )

        // This test specifically verifies that "take off hat" doesn't get
        // interpreted as a regular take command
        if case let .unwear(parsedHat) = parser.parse("take off hat") {
            #expect(parsedHat === hat)
        } else {
            throw TestFailure("'take off hat' was incorrectly interpreted: expected unwear command")
        }

        // Test with more natural phrasing
        if case let .unwear(parsedHat) = parser.parse("take the hat off") {
            #expect(parsedHat === hat)
        } else {
            throw TestFailure(
                "'take the hat off' was incorrectly interpreted: expected unwear command")
        }

        // Add a takeable object to the room to test precedence
        let ball = GameObject(
            name: "ball",
            description: "A round ball",
            location: world.player.currentRoom,
            flags: .isTakable
        )

        // Verify regular take still works
        if case let .take(obj) = parser.parse("take ball") {
            #expect(obj === ball)
        } else {
            throw TestFailure("'take ball' was incorrectly interpreted: expected take command")
        }
    }

    @Test func turnCommands() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a device
        let lamp = GameObject(
            name: "lamp",
            description: "A brass lamp",
            location: world.player.currentRoom,
            flags: .isDevice
        )

        // Test turn on command
        if case let .turnOn(parsedLamp) = parser.parse("turn on lamp") {
            #expect(parsedLamp === lamp)
        } else {
            throw TestFailure("Expected turn_on command")
        }

        // Test turn off command
        if case let .turnOff(parsedLamp) = parser.parse("turn off lamp") {
            #expect(parsedLamp === lamp)
        } else {
            throw TestFailure("Expected turn_off command")
        }

        // Test with article
        if case let .turnOn(parsedLamp) = parser.parse("turn on the lamp") {
            #expect(parsedLamp === lamp)
        } else {
            throw TestFailure("Expected turn_on command")
        }

        // Test with non-device item
        _ = GameObject(
            name: "book",
            description: "A heavy book",
            location: world.player.currentRoom
        )

        if case let .unknown(message) = parser.parse("turn on book") {
            #expect(message.contains("You can't turn on"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test with no object
        if case let .unknown(message) = parser.parse("turn on") {
            #expect(message.contains("Turn what on or off?"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test with just "turn"
        if case let .unknown(message) = parser.parse("turn") {
            #expect(message.contains("Turn what on or off?"))
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    @Test func unknownCommand() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        if case let .unknown(message) = parser.parse("dance") {
            #expect(message.contains("I don't understand"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test empty input
        if case let .unknown(message) = parser.parse("") {
            #expect(message == "No command given")
        } else {
            throw TestFailure("Expected unknown command for empty input")
        }
    }

    @Test func wearCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a wearable item
        let coat = GameObject(
            name: "coat",
            description: "A warm coat",
            location: world.player,
            flags: .isWearable
        )

        // Test "wear coat" command
        if case let .wear(parsedCoat) = parser.parse("wear coat") {
            #expect(parsedCoat === coat)
        } else {
            throw TestFailure("Expected wear command")
        }

        // Test "don coat" synonym
        if case let .wear(parsedCoat) = parser.parse("don coat") {
            #expect(parsedCoat === coat)
        } else {
            throw TestFailure("Expected wear command")
        }

        // Test "put on coat" command
        if case let .wear(parsedCoat) = parser.parse("put on coat") {
            #expect(parsedCoat === coat)
        } else {
            throw TestFailure("Expected wear command")
        }

        // Test "put coat on" command
        if case let .wear(parsedCoat) = parser.parse("put coat on") {
            #expect(parsedCoat === coat)
        } else {
            throw TestFailure("Expected wear command")
        }

        // Test with non-wearable item
        let rock = GameObject(
            name: "rock",
            description: "A gray rock",
            location: world.player
        )

        if case let .unknown(message) = parser.parse("wear rock") {
            #expect(message.contains("can't wear"))
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test with no object specified
        if case let .unknown(message) = parser.parse("wear") {
            #expect(message == "Wear what?")
        } else {
            throw TestFailure("Expected unknown command")
        }

        // Test with item not in inventory
        let scarf = GameObject(
            name: "scarf",
            description: "A woolen scarf",
            location: world.player.currentRoom,
            flags: .isWearable
        )

        if case let .unknown(message) = parser.parse("wear scarf") {
            #expect(message.contains("don't have"))
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

    // MARK: - Helper Functions

    // Helper to set up a test world
    func setupTestWorld() throws -> (GameWorld, CommandParser, Room, Room, GameObject) {
        let startRoom = Room(name: "Start Room", description: "The starting room")
        let northRoom = Room(name: "North Room", description: "Room to the north")

        startRoom.setExit(direction: .north, room: northRoom)
        northRoom.setExit(direction: .south, room: startRoom)

        let player = Player(startingRoom: startRoom)
        let world = GameWorld(player: player)

        // Register rooms with the world
        world.register(room: startRoom)
        world.register(room: northRoom)

        // Add a takeable object
        let coin = GameObject(
            name: "gold coin",
            description: "A shiny gold coin",
            location: startRoom,
            flags: .isTakable
        )
        world.register(coin)

        let parser = CommandParser(world: world)

        return (world, parser, startRoom, northRoom, coin)
    }
}
