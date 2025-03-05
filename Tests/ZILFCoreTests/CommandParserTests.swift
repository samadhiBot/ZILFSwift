import Testing

@testable import ZILFCore

struct CommandParserTests {
    @Test func lookCommand() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        let command = parser.parse("look")
        if case .look = command {
            // Success
        } else {
            throw TestFailure("Expected look command")
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
    }

    @Test func testTakeOffCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a wearable item for testing
        let hat = GameObject(name: "hat", description: "A fancy hat")
        hat.setFlag(.wearBit)
        hat.setFlag(.wornBit) // Mark as currently worn
        world.player.contents.append(hat)
        hat.location = world.player

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

        // Test with more complex phrasing (currently fails)
        if case let .customCommand(verb, objects, _) = parser.parse("take the hat off") {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            // Note: This will fail with current implementation
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
        world.player.contents.removeAll()
        if case let .unknown(message) = parser.parse("take off hat") {
            #expect(message.contains("don't have"))
        } else {
            throw TestFailure("Expected error about not having the item")
        }
    }

    @Test func testWearCommand() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a wearable item
        let coat = GameObject(name: "coat", description: "A warm coat")
        coat.setFlag(.wearBit)
        world.player.contents.append(coat)
        coat.location = world.player

        // Test "wear coat" command
        if case let .customCommand(verb, objects, _) = parser.parse("wear coat") {
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
    }

    @Test func testTakeOffCommandPrecedence() throws {
        let (world, parser, _, _, _) = try setupTestWorld()

        // Create a wearable item for testing
        let hat = GameObject(name: "hat", description: "A fancy hat")
        hat.setFlag(.wearBit)
        hat.setFlag(.wornBit)  // Mark as currently worn
        world.player.contents.append(hat)
        hat.location = world.player

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
        ball.location = world.player.currentRoom

        // Verify regular take still works
        if case let .take(obj) = parser.parse("take ball") {
            #expect(obj === ball)
        } else {
            throw TestFailure("'take ball' was incorrectly interpreted: expected take command")
        }
    }

    @Test func dropCommands() throws {
        let (world, parser, _, _, coin) = try setupTestWorld()

        // First take the coin so we can drop it
        world.player.contents.append(coin)
        coin.location = world.player

        // Test drop object
        if case let .drop(obj) = parser.parse("drop coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected drop command")
        }

        // Remove coin from inventory to test error case
        world.player.contents.removeAll()
        coin.location = world.player.currentRoom

        // Test drop non-carried object
        if case let .unknown(message) = parser.parse("drop coin") {
            #expect(message.contains("You're not carrying"))
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

    @Test func unknownCommand() throws {
        let (_, parser, _, _, _) = try setupTestWorld()

        if case let .unknown(message) = parser.parse("dance") {
            #expect(message.contains("I don't understand"))
        } else {
            throw TestFailure("Expected unknown command")
        }
    }

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
        let coin = GameObject(name: "gold coin", description: "A shiny gold coin", location: startRoom)
        coin.setFlag("takeable")
        world.registerObject(coin)

        let parser = CommandParser(world: world)

        return (world, parser, startRoom, northRoom, coin)
    }
}
