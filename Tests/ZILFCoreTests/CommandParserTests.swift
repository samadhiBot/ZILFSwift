import Testing

@testable import ZILFCore

struct CommandParserTests {
    // MARK: - Core Command Tests

    @Test func closeCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a closeable object
        let box = GameObject(name: "box", description: "A wooden box")
        box.setFlag(.containerBit)
        box.setFlag(.openBit)  // Start opened
        world.player.currentRoom?.contents.append(box)
        box.moveTo(world.player.currentRoom)

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
        world.player.contents.append(coin)
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
        if case let .examine(obj) = parser.parse("examine gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test examine with abbreviated syntax
        if case let .examine(obj) = parser.parse("x coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test look at syntax
        if case let .examine(obj) = parser.parse("look at gold coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test with article
        if case let .examine(obj) = parser.parse("examine the gold coin") {
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
        let lamp = GameObject(name: "lamp", description: "A brass lamp")
        lamp.setFlag(.deviceBit)
        world.player.currentRoom?.contents.append(lamp)
        lamp.moveTo(world.player.currentRoom)

        // Test flip command
        if case let .customCommand(verb, objects, _) = parser.parse("flip lamp") {
            #expect(verb == "flip")
            #expect(objects.count == 1)
            #expect(objects[0] === lamp)
        } else {
            throw TestFailure("Expected flip command")
        }

        // Test switch command
        if case let .customCommand(verb, objects, _) = parser.parse("switch lamp") {
            #expect(verb == "flip")
            #expect(objects.count == 1)
            #expect(objects[0] === lamp)
        } else {
            throw TestFailure("Expected flip command")
        }

        // Test toggle command
        if case let .customCommand(verb, objects, _) = parser.parse("toggle lamp") {
            #expect(verb == "flip")
            #expect(objects.count == 1)
            #expect(objects[0] === lamp)
        } else {
            throw TestFailure("Expected flip command")
        }

        // Test with non-device item
        let book = GameObject(name: "book", description: "A heavy book")
        world.player.currentRoom?.contents.append(book)
        book.moveTo(world.player.currentRoom)

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
        if case let .examine(obj) = parser.parse("examine it") {
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

    @Test func metaCommandsSyntax() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        // Test various meta commands
        let metaCommands = [
            "again", "g", "wait", "z", "version", "save", "restore",
            "restart", "undo", "brief", "verbose", "superbrief",
        ]

        for command in metaCommands {
            if case let .customCommand(verb, objects, _) = parser.parse(command) {
                if command == "g" {
                    #expect(verb == "again")
                } else if command == "z" {
                    #expect(verb == "wait")
                } else {
                    #expect(verb == command)
                }
                #expect(objects.isEmpty)
            } else {
                throw TestFailure("Expected custom command for '\(command)'")
            }
        }
    }

    @Test func openCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create an openable object
        let box = GameObject(name: "box", description: "A wooden box")
        box.setFlag(.containerBit)
        world.player.currentRoom?.contents.append(box)
        box.moveTo(world.player.currentRoom)

        // Test basic open command
        if case let .open(obj) = parser.parse("open box") {
            #expect(obj === box)
        } else {
            throw TestFailure("Expected open command")
        }

        // Test with article
        if case let .open(obj) = parser.parse("open the box") {
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
        let apple = GameObject(name: "apple", description: "A red apple")
        world.player.contents.append(apple)
        apple.moveTo(world.player)

        let box = GameObject(name: "box", description: "A wooden box")
        box.setFlag(.containerBit)
        world.player.currentRoom?.contents.append(box)
        box.moveTo(world.player.currentRoom)

        let table = GameObject(name: "table", description: "A wooden table")
        world.player.currentRoom?.contents.append(table)
        table.moveTo(world.player.currentRoom)

        // Test "put X in Y"
        if case let .customCommand(verb, objects, _) = parser.parse("put apple in box") {
            #expect(verb == "put-in")
            #expect(objects.count == 2)
            #expect(objects[0] === apple)
            #expect(objects[1] === box)
        } else {
            throw TestFailure("Expected put-in command")
        }

        // Test "put X on Y"
        if case let .customCommand(verb, objects, _) = parser.parse("put apple on table") {
            #expect(verb == "put-on")
            #expect(objects.count == 2)
            #expect(objects[0] === apple)
            #expect(objects[1] === table)
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
        let book = GameObject(name: "book", description: "A dusty book")
        book.setFlag(.readBit)
        world.player.currentRoom?.contents.append(book)
        book.moveTo(world.player.currentRoom)

        // Test read command
        if case let .customCommand(verb, objects, _) = parser.parse("read book") {
            #expect(verb == "read")
            #expect(objects.count == 1)
            #expect(objects[0] === book)
        } else {
            throw TestFailure("Expected read command")
        }

        // Test peruse command
        if case let .customCommand(verb, objects, _) = parser.parse("peruse book") {
            #expect(verb == "read")
            #expect(objects.count == 1)
            #expect(objects[0] === book)
        } else {
            throw TestFailure("Expected read command")
        }

        // Test with non-readable item
        let rock = GameObject(name: "rock", description: "A gray rock")
        world.player.currentRoom?.contents.append(rock)
        rock.moveTo(world.player.currentRoom)

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
        let hat = GameObject(name: "hat", description: "A fancy hat")
        hat.setFlag(.wearBit)
        hat.setFlag(.wornBit)  // Mark as currently worn
        world.player.contents.append(hat)
        hat.moveTo(world.player)

        // Test "remove hat" command
        if case let .customCommand(verb, objects, _) = parser.parse("remove hat") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test "doff hat" command
        if case let .customCommand(verb, objects, _) = parser.parse("doff hat") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test with article
        if case let .customCommand(verb, objects, _) = parser.parse("remove the hat") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test when not wearing the item
        hat.clearFlag(.wornBit)
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
        let hat = GameObject(name: "hat", description: "A fancy hat")
        hat.setFlag(.wearBit)
        hat.setFlag(.wornBit)  // Mark as currently worn
        world.player.contents.append(hat)
        hat.moveTo(world.player)

        // Test basic "take off hat" command
        if case let .customCommand(verb, objects, _) = parser.parse("take off hat") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test with article "take off the hat"
        if case let .customCommand(verb, objects, _) = parser.parse("take off the hat") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            throw TestFailure("Expected unwear command")
        }

        // Test with alternative phrasing "take the hat off"
        if case let .customCommand(verb, objects, _) = parser.parse("take the hat off") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            throw TestFailure("Expected unwear command for 'take the hat off'")
        }

        // Test when not wearing the item
        hat.clearFlag(.wornBit)
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
        let hat = GameObject(name: "hat", description: "A fancy hat")
        hat.setFlag(.wearBit)
        hat.setFlag(.wornBit)  // Mark as currently worn
        world.player.contents.append(hat)
        hat.moveTo(world.player)

        // This test specifically verifies that "take off hat" doesn't get
        // interpreted as a regular take command
        if case let .customCommand(verb, objects, _) = parser.parse("take off hat") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            throw TestFailure("'take off hat' was incorrectly interpreted: expected unwear command")
        }

        // Test with more natural phrasing
        if case let .customCommand(verb, objects, _) = parser.parse("take the hat off") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            throw TestFailure(
                "'take the hat off' was incorrectly interpreted: expected unwear command")
        }

        // Add a takeable object to the room to test precedence
        let ball = GameObject(name: "ball", description: "A round ball")
        ball.setFlag(.takeBit)
        world.player.currentRoom?.contents.append(ball)
        ball.moveTo(world.player.currentRoom)

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
        let lamp = GameObject(name: "lamp", description: "A brass lamp")
        lamp.setFlag(.deviceBit)
        world.player.currentRoom?.contents.append(lamp)
        lamp.moveTo(world.player.currentRoom)

        // Test turn on command
        if case let .customCommand(verb, objects, _) = parser.parse("turn on lamp") {
            #expect(verb == "turn_on")
            #expect(objects.count == 1)
            #expect(objects[0] === lamp)
        } else {
            throw TestFailure("Expected turn_on command")
        }

        // Test turn off command
        if case let .customCommand(verb, objects, _) = parser.parse("turn off lamp") {
            #expect(verb == "turn_off")
            #expect(objects.count == 1)
            #expect(objects[0] === lamp)
        } else {
            throw TestFailure("Expected turn_off command")
        }

        // Test with article
        if case let .customCommand(verb, objects, _) = parser.parse("turn on the lamp") {
            #expect(verb == "turn_on")
            #expect(objects.count == 1)
            #expect(objects[0] === lamp)
        } else {
            throw TestFailure("Expected turn_on command")
        }

        // Test with non-device item
        let book = GameObject(name: "book", description: "A heavy book")
        world.player.currentRoom?.contents.append(book)
        book.moveTo(world.player.currentRoom)

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
        let coat = GameObject(name: "coat", description: "A warm coat")
        coat.setFlag(.wearBit)
        world.player.contents.append(coat)
        coat.moveTo(world.player)

        // Test "wear coat" command
        if case let .customCommand(verb, objects, _) = parser.parse("wear coat") {
            #expect(verb == "wear")
            #expect(objects.count == 1)
            #expect(objects[0] === coat)
        } else {
            throw TestFailure("Expected wear command")
        }

        // Test "don coat" synonym
        if case let .customCommand(verb, objects, _) = parser.parse("don coat") {
            #expect(verb == "wear")
            #expect(objects.count == 1)
            #expect(objects[0] === coat)
        } else {
            throw TestFailure("Expected wear command")
        }

        // Test "put on coat" command
        if case let .customCommand(verb, objects, _) = parser.parse("put on coat") {
            #expect(verb == "wear")
            #expect(objects.count == 1)
            #expect(objects[0] === coat)
        } else {
            throw TestFailure("Expected wear command")
        }

        // Test "put coat on" command
        if case let .customCommand(verb, objects, _) = parser.parse("put coat on") {
            #expect(verb == "wear")
            #expect(objects.count == 1)
            #expect(objects[0] === coat)
        } else {
            throw TestFailure("Expected wear command")
        }

        // Test with non-wearable item
        let rock = GameObject(name: "rock", description: "A gray rock")
        world.player.contents.append(rock)
        rock.moveTo(world.player)

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
        let scarf = GameObject(name: "scarf", description: "A woolen scarf")
        scarf.setFlag(.wearBit)
        world.player.currentRoom?.contents.append(scarf)
        scarf.moveTo(world.player.currentRoom)

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
        world.registerRoom(startRoom)
        world.registerRoom(northRoom)

        // Add a takeable object
        let coin = GameObject(
            name: "gold coin", description: "A shiny gold coin", location: startRoom)
        coin.setFlag(.takeBit)
        world.registerObject(coin)

        let parser = CommandParser(world: world)

        return (world, parser, startRoom, northRoom, coin)
    }
}
