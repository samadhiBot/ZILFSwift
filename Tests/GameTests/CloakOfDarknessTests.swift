import Testing
@testable import ZILFCore
@testable import CloakOfDarkness
import ZILFTestSupport

@Suite struct CloakOfDarknessTests {
    @Test func testGameCreation() throws {
        // Create the game world
        let world = try CloakOfDarkness.create()

        // Verify world properties
        #expect(world.player.currentRoom?.name == "Foyer of the Opera House")
        #expect(world.rooms.count == 6)  // Foyer, Bar, Cloakroom, Hallway, Study, Closet

        // Find rooms
        let foyer = try world.find(room: "Foyer of the Opera House")
        let bar = try world.find(room: "Foyer Bar")
        let cloakroom = try world.find(room: "Cloakroom")

        // Verify room connections
        #expect(foyer.getExit(.south) === bar)
        #expect(foyer.getExit(.west) === cloakroom)
        #expect(bar.getExit(.north) === foyer)
        #expect(cloakroom.getExit(.east) === foyer)

        // Verify objects
        let cloak = try world.find(object: "cloak")
        let message = try world.find(object: "message")
        print("🎾", world.objects)
        let hook = try world.find(object: "small brass hook")

        // Verify object locations
        #expect(cloak.location === world.player)
        #expect(message.location === bar)
        #expect(hook.location === cloakroom)

        // Verify object properties
        #expect(cloak.hasFlag(.isTakable))
        #expect(cloak.hasFlag(.isWearable))
        #expect(cloak.hasFlag(.isBeingWorn))  // Initially worn
        #expect(hook.hasFlag(.isContainer))
        #expect(hook.hasFlag(.isSurface))
    }

    @Test func testWinGame() throws {
        let world = try CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)
        let parser = CommandParser(world: world)

        // Get objects and rooms we'll need
        let foyer = try world.find(room: "Foyer of the Opera House")
        let bar = try world.find(room: "Foyer Bar")
        let cloakroom = try world.find(room: "Cloakroom")
        let cloak = try world.find(object: "cloak")

        // 1. We start in the Foyer
        #expect(world.player.currentRoom === foyer)
        outputHandler.clear()

        // 2. Move to the cloakroom
        try engine.executeCommand(parser.parse("west"))
        #expect(world.player.currentRoom === cloakroom)
        #expect(outputHandler.output.contains("small room"))
        outputHandler.clear()

        // 3. Check inventory
        try engine.executeCommand(parser.parse("inventory"))
        #expect(outputHandler.output.contains("cloak"))
        outputHandler.clear()

        // DEBUG: Inspect what objects are in the cloakroom
        print("🔍 Objects in cloakroom:")
        for obj in cloakroom.contents {
            print("  - \(obj.name)")
        }

        // DEBUG: Inspect the room description to see how the hook is described
        try engine.executeCommand(parser.parse("look"))
        print("🔍 Room description: \(outputHandler.output)")
        outputHandler.clear()

        // 4. Try using the exact name from the room description
        // First, look for "brass hook" instead of just "hook"
        try engine.executeCommand(parser.parse("put cloak on brass hook"))
        print("🔍 Response: \(outputHandler.output)")
        #expect(!world.player.inventory.contains(where: { $0 === cloak }))

        // If the above fails, try alternate syntax
        if world.player.inventory.contains(where: { $0 === cloak }) {
            outputHandler.clear()
            try engine.executeCommand(parser.parse("drop cloak"))
            print("🔍 Drop response: \(outputHandler.output)")
            #expect(!world.player.inventory.contains(where: { $0 === cloak }))
        }

        outputHandler.clear()

        // 5. Go back to the foyer
        try engine.executeCommand(parser.parse("east"))
        #expect(world.player.currentRoom === foyer)
        outputHandler.clear()

        // 6. Go to the bar
        try engine.executeCommand(parser.parse("south"))
        #expect(world.player.currentRoom === bar)

        // The bar should be lit now because we left the cloak in the cloakroom
        #expect(bar.hasFlag(.isOn))
        outputHandler.clear()

        // 7. Examine the message
        try engine.executeCommand(parser.parse("examine message"))

        // 8. Verify we won the game
        #expect(outputHandler.output.contains("You win"))
        #expect(!outputHandler.output.contains("You lose"))

        // The game should be over
        let isGameOver: Bool? = engine.isGameOver
        #expect(isGameOver == true)
        #expect(outputHandler.output.contains("You win"))
    }

    @Test func testLoseGame() throws {
        let world = try CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Get objects and rooms we'll need
        let foyer = try world.find(room: "Foyer of the Opera House")
        let bar = try world.find(room: "Foyer Bar")

        // 1. Start in the Foyer
        #expect(world.player.currentRoom === foyer)
        outputHandler.clear()

        // 2. Go directly to the bar while still wearing cloak
        try engine.executeCommand(.move(.south))
        #expect(world.player.currentRoom === bar)
        // The bar should be dark
        #expect(!bar.hasFlag(.isOn))
        outputHandler.clear()

        // 3. Disturb the message by trying to take it
        let message = try world.find(object: "message")
        try engine.executeCommand(.take(message))
        outputHandler.clear()

        // 4. Try to examine something else, disturbing the room more
        try engine.executeCommand(.look)
        outputHandler.clear()

        // 5. Now go to the cloakroom and drop the cloak
        try engine.executeCommand(.move(.north))
        try engine.executeCommand(.move(.west))

        let cloak = try world.find(object: "cloak")
        try engine.executeCommand(.drop(cloak))
        outputHandler.clear()

        // 6. Go back to the now-lit bar
        try engine.executeCommand(.move(.east))
        try engine.executeCommand(.move(.south))
        #expect(bar.hasFlag(.isOn))
        outputHandler.clear()

        // 7. Examine the message
        try engine.executeCommand(.examine(message, with: nil))

        // 8. Verify we lost the game
        #expect(outputHandler.output.contains("You lose"))
        #expect(!outputHandler.output.contains("You win"))

        // The game should be over
        let isGameOver: Bool? = engine.isGameOver
        #expect(isGameOver == true)
        #expect(outputHandler.output.contains("You lose"))
    }

    @Test func testCloak() throws {
        let world = try CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Get the cloak
        let cloak = try world.find(object: "cloak")

        // Examine the cloak
        try engine.executeCommand(.examine(cloak, with: nil))
        #expect(outputHandler.output.contains("dark"))
        outputHandler.clear()

        // Test that the cloak affects room lighting
        let bar = try world.find(room: "Foyer Bar")

        // Bar should be dark while wearing cloak
        try engine.executeCommand(.move(.south))
        #expect(!bar.hasFlag(.isOn))

        // Try to do something in the dark
        try engine.executeCommand(.look)
        #expect(outputHandler.output.contains("dark"))
        outputHandler.clear()

        // Go back to foyer and cloakroom
        try engine.executeCommand(.move(.north))
        try engine.executeCommand(.move(.west))

        // Remove cloak
        try engine.executeCommand(.drop(cloak))
        #expect(!world.player.inventory.contains { $0.name == "cloak" })
        outputHandler.clear()

        // Return to bar - should now be lit
        try engine.executeCommand(.move(.east))
        try engine.executeCommand(.move(.south))
        #expect(bar.hasFlag(.isOn))
        outputHandler.clear()

        // Now we can see clearly
        try engine.executeCommand(.look)
        #expect(outputHandler.output.contains("empty"))
        #expect(outputHandler.output.contains("message"))
        #expect(!outputHandler.output.contains("dark"))
    }

    @Test func testBlockedPath() throws {
        let world = try CloakOfDarkness.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Get objects and rooms we'll need
        let cloakroom = try world.find(room: "Cloakroom")
        let cloak = try world.find(object: "cloak")

        // Move to the cloakroom
        try engine.executeCommand(.move(.west))
        #expect(world.player.currentRoom === cloakroom)
        outputHandler.clear()

        // Try to go west while wearing the cloak
        try engine.executeCommand(.move(.west))
        #expect(outputHandler.output.contains("cannot"))
        #expect(world.player.currentRoom === cloakroom)  // Should still be in cloakroom
        outputHandler.clear()

        // Now drop the cloak
        try engine.executeCommand(.drop(cloak))
        outputHandler.clear()

        // Now we can go west
        try engine.executeCommand(.move(.west))
        #expect(world.player.currentRoom?.name == "Hallway to Study")
        #expect(outputHandler.output.contains("cramped"))
    }
}
