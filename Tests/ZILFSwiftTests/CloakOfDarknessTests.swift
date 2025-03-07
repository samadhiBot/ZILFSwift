//
//  CloakOfDarknessTests.swift
//  ZILFSwift
//
//  Created on 3/1/25.
//

import Testing
@testable import ZILFCore
@testable import CloakOfDarkness
import ZILFTestSupport

@Suite struct CloakOfDarknessTests {
    @Test func testGameCreation() throws {
        // Create the game world
        let world = CloakOfDarkness.create()

        // Verify world properties
        #expect(world.player.currentRoom?.name == "Foyer of the Opera House")
        #expect(world.rooms.count == 6)  // Foyer, Bar, Cloakroom, Hallway, Study, Closet

        // Find rooms
        let foyer = try world.findRoom(named: "Foyer of the Opera House")
        let bar = try world.findRoom(named: "Foyer Bar")
        let cloakroom = try world.findRoom(named: "Cloakroom")

        // Verify room connections
        #expect(foyer.getExit(direction: .south) === bar)
        #expect(foyer.getExit(direction: .west) === cloakroom)
        #expect(bar.getExit(direction: .north) === foyer)
        #expect(cloakroom.getExit(direction: .east) === foyer)

        // Verify objects
        let cloak = try world.findObject(named: "cloak")
        let message = try world.findObject(named: "message")
        let hook = try world.findObject(named: "small brass hook")

        // Verify object locations
        #expect(cloak.location === world.player)
        #expect(message.location === bar)
        #expect(hook.location === cloakroom)

        // Verify object properties
        #expect(cloak.hasFlag(.takeBit))
        #expect(cloak.hasFlag(.wearBit))
        #expect(cloak.hasFlag(.wornBit))  // Initially worn
        #expect(hook.hasFlag(.containerBit))
        #expect(hook.hasFlag(.surfaceBit))
    }

    @Test func testWinGame() throws {
        let world = CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)
        let parser = CommandParser(world: world)

        // Get objects and rooms we'll need
        let foyer = try world.findRoom(named: "Foyer of the Opera House")
        let bar = try world.findRoom(named: "Foyer Bar")
        let cloakroom = try world.findRoom(named: "Cloakroom")
        let cloak = try world.findObject(named: "cloak")

        // 1. We start in the Foyer
        #expect(world.player.currentRoom === foyer)
        outputHandler.clear()

        // 2. Move to the cloakroom
        engine.executeCommand(parser.parse("west"))
        #expect(world.player.currentRoom === cloakroom)
        #expect(outputHandler.output.contains("small room"))
        outputHandler.clear()

        // 3. Check inventory
        engine.executeCommand(parser.parse("inventory"))
        #expect(outputHandler.output.contains("cloak"))
        outputHandler.clear()

        // DEBUG: Inspect what objects are in the cloakroom
        print("🔍 Objects in cloakroom:")
        for obj in cloakroom.contents {
            print("  - \(obj.name)")
        }

        // DEBUG: Inspect the room description to see how the hook is described
        engine.executeCommand(parser.parse("look"))
        print("🔍 Room description: \(outputHandler.output)")
        outputHandler.clear()

        // 4. Try using the exact name from the room description
        // First, look for "brass hook" instead of just "hook"
        engine.executeCommand(parser.parse("put cloak on brass hook"))
        print("🔍 Response: \(outputHandler.output)")
        #expect(!world.player.contents.contains(where: { $0 === cloak }))

        // If the above fails, try alternate syntax
        if world.player.contents.contains(where: { $0 === cloak }) {
            outputHandler.clear()
            engine.executeCommand(parser.parse("drop cloak"))
            print("🔍 Drop response: \(outputHandler.output)")
            #expect(!world.player.contents.contains(where: { $0 === cloak }))
        }

        outputHandler.clear()

        // 5. Go back to the foyer
        engine.executeCommand(parser.parse("east"))
        #expect(world.player.currentRoom === foyer)
        outputHandler.clear()

        // 6. Go to the bar
        engine.executeCommand(parser.parse("south"))
        #expect(world.player.currentRoom === bar)

        // The bar should be lit now because we left the cloak in the cloakroom
        #expect(bar.hasFlag(.lit))
        outputHandler.clear()

        // 7. Examine the message
        engine.executeCommand(parser.parse("examine message"))

        // 8. Verify we won the game
        #expect(outputHandler.output.contains("You win"))
        #expect(!outputHandler.output.contains("You lose"))

        // The game should be over
        let isGameOver: Bool? = engine.isGameOver
        #expect(isGameOver == true)
        #expect(outputHandler.output.contains("You win"))
    }

    @Test func testLoseGame() throws {
        let world = CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Get objects and rooms we'll need
        let foyer = try world.findRoom(named: "Foyer of the Opera House")
        let bar = try world.findRoom(named: "Foyer Bar")

        // 1. Start in the Foyer
        #expect(world.player.currentRoom === foyer)
        outputHandler.clear()

        // 2. Go directly to the bar while still wearing cloak
        engine.executeCommand(.move(.south))
        #expect(world.player.currentRoom === bar)
        // The bar should be dark
        #expect(!bar.hasFlag(.lit))
        outputHandler.clear()

        // 3. Disturb the message by trying to take it
        let message = try world.findObject(named: "message")
        engine.executeCommand(.take(message))
        outputHandler.clear()

        // 4. Try to examine something else, disturbing the room more
        engine.executeCommand(.look)
        outputHandler.clear()

        // 5. Now go to the cloakroom and drop the cloak
        engine.executeCommand(.move(.north))
        engine.executeCommand(.move(.west))

        let cloak = try world.findObject(named: "cloak")
        engine.executeCommand(.drop(cloak))
        outputHandler.clear()

        // 6. Go back to the now-lit bar
        engine.executeCommand(.move(.east))
        engine.executeCommand(.move(.south))
        #expect(bar.hasFlag(.lit))
        outputHandler.clear()

        // 7. Examine the message
        engine.executeCommand(.examine(message))

        // 8. Verify we lost the game
        #expect(outputHandler.output.contains("You lose"))
        #expect(!outputHandler.output.contains("You win"))

        // The game should be over
        let isGameOver: Bool? = engine.isGameOver
        #expect(isGameOver == true)
        #expect(outputHandler.output.contains("You lose"))
    }

    @Test func testCloak() throws {
        let world = CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Get the cloak
        let cloak = try world.findObject(named: "cloak")

        // Examine the cloak
        engine.executeCommand(.examine(cloak))
        #expect(outputHandler.output.contains("dark"))
        outputHandler.clear()

        // Test that the cloak affects room lighting
        let bar = try world.findRoom(named: "Foyer Bar")

        // Bar should be dark while wearing cloak
        engine.executeCommand(.move(.south))
        #expect(!bar.hasFlag(.lit))

        // Try to do something in the dark
        engine.executeCommand(.look)
        #expect(outputHandler.output.contains("dark"))
        outputHandler.clear()

        // Go back to foyer and cloakroom
        engine.executeCommand(.move(.north))
        engine.executeCommand(.move(.west))

        // Remove cloak
        engine.executeCommand(.drop(cloak))
        #expect(!world.player.contents.contains { $0.name == "cloak" })
        outputHandler.clear()

        // Return to bar - should now be lit
        engine.executeCommand(.move(.east))
        engine.executeCommand(.move(.south))
        #expect(bar.hasFlag(.lit))
        outputHandler.clear()

        // Now we can see clearly
        engine.executeCommand(.look)
        #expect(outputHandler.output.contains("empty"))
        #expect(outputHandler.output.contains("message"))
        #expect(!outputHandler.output.contains("dark"))
    }

    @Test func testBlockedPath() throws {
        let world = CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Get objects and rooms we'll need
        let cloakroom = try world.findRoom(named: "Cloakroom")
        let cloak = try world.findObject(named: "cloak")

        // Move to the cloakroom
        engine.executeCommand(.move(.west))
        #expect(world.player.currentRoom === cloakroom)
        outputHandler.clear()

        // Try to go west while wearing the cloak
        engine.executeCommand(.move(.west))
        #expect(outputHandler.output.contains("cannot"))
        #expect(world.player.currentRoom === cloakroom)  // Should still be in cloakroom
        outputHandler.clear()

        // Now drop the cloak
        engine.executeCommand(.drop(cloak))
        outputHandler.clear()

        // Now we can go west
        engine.executeCommand(.move(.west))
        #expect(world.player.currentRoom?.name == "Hallway to Study")
        #expect(outputHandler.output.contains("cramped"))
    }
}
