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

    // MARK: - Helper Functions

    /// Helper function to get an object by name from the world
    func getObject(named name: String, from world: GameWorld) -> GameObject? {
        return world.objects.first { $0.name == name }
    }

    /// Helper function to get a room by name from the world
    func getRoom(named name: String, from world: GameWorld) -> Room? {
        return world.rooms.first { $0.name == name }
    }

    // MARK: - Tests

    @Test func testGameCreation() {
        // Create the game world
        let world = CloakOfDarkness.create()

        // Verify world properties
        #expect(world.player.currentRoom?.name == "Foyer of the Opera House")
        #expect(world.rooms.count == 6)  // Foyer, Bar, Cloakroom, Hallway, Study, Closet

        // Find rooms
        let foyer = getRoom(named: "Foyer of the Opera House", from: world)
        let bar = getRoom(named: "Foyer Bar", from: world)
        let cloakroom = getRoom(named: "Cloakroom", from: world)

        #expect(foyer != nil)
        #expect(bar != nil)
        #expect(cloakroom != nil)

        // Verify room connections
        #expect(foyer?.getExit(direction: .south) === bar)
        #expect(foyer?.getExit(direction: .west) === cloakroom)
        #expect(bar?.getExit(direction: .north) === foyer)
        #expect(cloakroom?.getExit(direction: .east) === foyer)

        // Verify objects
        let cloak = getObject(named: "cloak", from: world)
        let message = getObject(named: "message", from: world)
        let hook = getObject(named: "small brass hook", from: world)

        #expect(cloak != nil)
        #expect(message != nil)
        #expect(hook != nil)

        // Verify object locations
        #expect(cloak?.location === world.player)
        #expect(message?.location === bar)
        #expect(hook?.location === cloakroom)

        // Verify object properties
        #expect(cloak!.hasFlag(.takeBit))
        #expect(cloak!.hasFlag(.wearBit))
        #expect(cloak!.hasFlag(.wornBit))  // Initially worn
        #expect(hook!.hasFlag(.contBit))
        #expect(hook!.hasFlag(.surfaceBit))
    }

    @Test func testWinGame() throws {
        let world = CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Debug: Print initial inventory
        print("DEBUG: Initial inventory:")
        engine.executeCommand(.inventory)
        print("DEBUG: Inventory output: \(outputHandler.output)")
        outputHandler.clear()

        // Get objects and rooms we'll need
        let foyer = getRoom(named: "Foyer of the Opera House", from: world)!
        let bar = getRoom(named: "Foyer Bar", from: world)!
        let cloakroom = getRoom(named: "Cloakroom", from: world)!
        let cloak = getObject(named: "cloak", from: world)!
        let hook = getObject(named: "small brass hook", from: world)!

        // 1. We start in the Foyer
        #expect(world.player.currentRoom === foyer)
        outputHandler.clear()

        // 2. Move to the cloakroom
        print("DEBUG: Moving to cloakroom")
        engine.executeCommand(.move(.west))
        print("DEBUG: Cloakroom description: \(outputHandler.output)")
        #expect(world.player.currentRoom === cloakroom)
        #expect(outputHandler.output.contains("small room"))
        outputHandler.clear()

        // 3. Drop the cloak on the hook
        // First, check that we have the cloak
        print("DEBUG: Checking inventory before dropping cloak")
        engine.executeCommand(.inventory)
        print("DEBUG: Inventory output: \(outputHandler.output)")
        #expect(outputHandler.output.contains("cloak"))
        outputHandler.clear()

        // Use custom command to put the cloak on the hook
        print("DEBUG: Dropping cloak")
        engine.executeCommand(.drop(cloak))
        print("DEBUG: Drop output: \(outputHandler.output)")
        #expect(!world.player.contents.contains { $0.name == "cloak" })
        outputHandler.clear()

        // 4. Go back to the foyer
        print("DEBUG: Moving back to foyer")
        engine.executeCommand(.move(.east))
        print("DEBUG: Foyer output: \(outputHandler.output)")
        #expect(world.player.currentRoom === foyer)
        outputHandler.clear()

        // 5. Go to the bar
        print("DEBUG: Moving to bar")
        engine.executeCommand(.move(.south))
        print("DEBUG: Bar output: \(outputHandler.output)")
        #expect(world.player.currentRoom === bar)
        // The bar should be lit now
        print("DEBUG: Bar lit? \(bar.hasFlag(.lit))")
        #expect(bar.hasFlag(.lit))
        outputHandler.clear()

        // 6. Examine the message
        print("DEBUG: Examining message")
        let message = getObject(named: "message", from: world)!
        engine.executeCommand(.examine(message))
        print("DEBUG: Message output: \(outputHandler.output)")

        // 7. Verify we won the game
        #expect(outputHandler.output.contains("You win"))
        #expect(!outputHandler.output.contains("You lose"))

        // The game should be over
        let isGameOver: Bool? = engine.isGameOver
        print("DEBUG: isGameOver? \(String(describing: isGameOver))")
        #expect(isGameOver == true)
        #expect(outputHandler.output.contains("You win"))
    }

    @Test func testLoseGame() throws {
        let world = CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Get objects and rooms we'll need
        let foyer = getRoom(named: "Foyer of the Opera House", from: world)!
        let bar = getRoom(named: "Foyer Bar", from: world)!

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
        let message = getObject(named: "message", from: world)!
        engine.executeCommand(.take(message))
        outputHandler.clear()

        // 4. Try to examine something else, disturbing the room more
        engine.executeCommand(.look)
        outputHandler.clear()

        // 5. Now go to the cloakroom and drop the cloak
        engine.executeCommand(.move(.north))
        engine.executeCommand(.move(.west))

        let cloak = getObject(named: "cloak", from: world)!
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
        let cloak = getObject(named: "cloak", from: world)!

        // Examine the cloak
        engine.executeCommand(.examine(cloak))
        #expect(outputHandler.output.contains("dark"))
        outputHandler.clear()

        // Test that the cloak affects room lighting
        let bar = getRoom(named: "Foyer Bar", from: world)!

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
        let cloakroom = getRoom(named: "Cloakroom", from: world)!
        let cloak = getObject(named: "cloak", from: world)!

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
