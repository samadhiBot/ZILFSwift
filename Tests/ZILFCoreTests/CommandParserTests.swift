//
//  CommandParserTests.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

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

        // Add a takeable object
        let coin = GameObject(name: "gold coin", description: "A shiny gold coin", location: startRoom)
        coin.setFlag("takeable")
        world.registerObject(coin)

        let parser = CommandParser(world: world)

        return (world, parser, startRoom, northRoom, coin)
    }
}
