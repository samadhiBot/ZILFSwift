//
//  HelloWorldGameTests.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/26/25.
//

import Testing
@testable import ZILFSwift
@testable import ZILFCore

struct HelloWorldGameTests {
    @Test func testGameCreation() {
        let world = HelloWorldGame.create()

        // Verify world properties
        #expect(world.player.currentRoom?.name == "Entrance")
        #expect(world.rooms.count == 3)

        // Find rooms
        let entrance = world.rooms.first { $0.name == "Entrance" }
        let mainCavern = world.rooms.first { $0.name == "Main Cavern" }
        let treasureRoom = world.rooms.first { $0.name == "Treasure Room" }

        #expect(entrance != nil)
        #expect(mainCavern != nil)
        #expect(treasureRoom != nil)

        // Verify room connections
        #expect(entrance?.getExit(direction: .north) === mainCavern)
        #expect(mainCavern?.getExit(direction: .south) === entrance)
        #expect(mainCavern?.getExit(direction: .east) === treasureRoom)
        #expect(treasureRoom?.getExit(direction: .west) === mainCavern)

        // Verify objects
        let lantern = world.objects.first { $0.name == "lantern" }
        let coin = world.objects.first { $0.name == "gold coin" }
        let chest = world.objects.first { $0.name == "treasure chest" }

        #expect(lantern != nil)
        #expect(coin != nil)
        #expect(chest != nil)

        // Verify object locations
        #expect(lantern?.location === entrance)
        #expect(coin?.location === mainCavern)
        #expect(chest?.location === treasureRoom)

        // Verify object properties
        #expect(lantern!.hasFlag("takeable"))
        #expect(coin!.hasFlag("takeable"))
        #expect(!chest!.hasFlag("takeable"))
    }

    @Test func testGameCommands() {
        let world = HelloWorldGame.create()
        let outputHandler = TestOutputHandler()
        let engine = GameEngine(world: world, outputHandler: outputHandler)

        // Test initial look command
        engine.executeCommand(.look)
        #expect(outputHandler.output.contains("Entrance"))
        #expect(outputHandler.output.contains("lantern"))
        outputHandler.clear()

        // Test taking the lantern
        engine.executeCommand(.take(world.objects.first { $0.name == "lantern" }!))
        #expect(outputHandler.output.contains("Taken"))
        #expect(world.player.contents.contains { $0.name == "lantern" })
        outputHandler.clear()

        // Test examining the lantern after taking it
        engine.executeCommand(.examine(world.objects.first { $0.name == "lantern" }!))
        #expect(outputHandler.output.contains("brass lantern"))
        outputHandler.clear()

        // Test moving to the main cavern
        engine.executeCommand(.move(.north))
        #expect(world.player.currentRoom?.name == "Main Cavern")
        #expect(outputHandler.output.contains("Main Cavern"))
        #expect(outputHandler.output.contains("gold coin"))
        outputHandler.clear()

        // Test taking the coin
        engine.executeCommand(.take(world.objects.first { $0.name == "gold coin" }!))
        #expect(outputHandler.output.contains("Taken"))
        #expect(world.player.contents.contains { $0.name == "gold coin" })
        outputHandler.clear()

        // Test inventory
        engine.executeCommand(.inventory)
        #expect(outputHandler.output.contains("lantern"))
        #expect(outputHandler.output.contains("gold coin"))
        outputHandler.clear()

        // Test moving to the treasure room
        engine.executeCommand(.move(.east))
        #expect(world.player.currentRoom?.name == "Treasure Room")
        #expect(outputHandler.output.contains("Treasure Room"))
        #expect(outputHandler.output.contains("treasure chest"))
        outputHandler.clear()

        // Test examining the chest
        engine.executeCommand(.examine(world.objects.first { $0.name == "treasure chest" }!))
        #expect(outputHandler.output.contains("ornate wooden chest"))
        outputHandler.clear()

        // Test trying to take the chest (which shouldn't be takeable)
        engine.executeCommand(.take(world.objects.first { $0.name == "treasure chest" }!))
        #expect(outputHandler.output.contains("You can't take that"))
        #expect(!world.player.contents.contains { $0.name == "treasure chest" })
        outputHandler.clear()

        // Test going back to the main cavern
        engine.executeCommand(.move(.west))
        #expect(world.player.currentRoom?.name == "Main Cavern")
        outputHandler.clear()

        // Test dropping the coin
        engine.executeCommand(.drop(world.objects.first { $0.name == "gold coin" }!))
        #expect(outputHandler.output.contains("Dropped"))
        #expect(!world.player.contents.contains { $0.name == "gold coin" })
        #expect(world.player.currentRoom?.contents.contains { $0.name == "gold coin" } ?? false)
        outputHandler.clear()
    }

    @Test func testParser() throws {
        let world = HelloWorldGame.create()
        let parser = CommandParser(world: world)

        // Test direction commands
        if case let .move(direction) = parser.parse("north") {
            #expect(direction == .north)
        } else {
            throw TestFailure("Expected move command")
        }

        if case let .move(direction) = parser.parse("n") {
            #expect(direction == .north)
        } else {
            throw TestFailure("Expected move command")
        }

        // Test look command
        if case .look = parser.parse("look") {
            // Success
        } else {
            throw TestFailure("Expected look command")
        }

        // Test examine command
        let lantern = world.objects.first { $0.name == "lantern" }!
        if case let .examine(obj) = parser.parse("examine lantern") {
            #expect(obj === lantern)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test take command
        if case let .take(obj) = parser.parse("take lantern") {
            #expect(obj === lantern)
        } else {
            throw TestFailure("Expected take command")
        }

        // Test inventory command
        if case .inventory = parser.parse("inventory") {
            // Success
        } else {
            throw TestFailure("Expected inventory command")
        }

        // Test quit command
        if case .quit = parser.parse("quit") {
            // Success
        } else {
            throw TestFailure("Expected quit command")
        }
    }
}

class TestOutputHandler: OutputHandler {
    var output = ""

    func output(_ text: String) {
        output(text, terminator: "\n")
    }

    func output(_ text: String, terminator: String) {
        output += text + terminator
    }

    func clear() {
        output = ""
    }
}
