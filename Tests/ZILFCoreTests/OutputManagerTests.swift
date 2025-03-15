import Foundation
import Testing
import ZILFCore

@Suite
@MainActor
struct OutputManagerTests {
    @Test
    func testMockOutputManager() {
        // Create a mock output manager with predefined inputs
        let inputs = ["look", "take sword", "inventory", "quit"]
        let outputManager = MockOutputManager(inputResponses: inputs)

        // Test output capture
        outputManager.output("Welcome to the test!")
        outputManager.output("This is a test message.")

        #expect(outputManager.capturedOutput.count == 2)
        #expect(outputManager.capturedOutput[0] == "Welcome to the test!")
        #expect(outputManager.capturedOutput[1] == "This is a test message.")

        // Test input responses
        #expect(outputManager.getInput() == "look")
        #expect(outputManager.getInput() == "take sword")
        #expect(outputManager.getInput() == "inventory")
        #expect(outputManager.getInput() == "quit")

        // Test status line capture
        outputManager.updateStatusLine(location: "Test Room", score: 10, moves: 5)
        #expect(outputManager.capturedOutput.count == 3)
        #expect(outputManager.capturedOutput[2].contains("Test Room"))
        #expect(outputManager.capturedOutput[2].contains("Score: 10"))
        #expect(outputManager.capturedOutput[2].contains("Moves: 5"))

        // Test clearing output
        outputManager.clearCapturedOutput()
        #expect(outputManager.capturedOutput.isEmpty)
    }

    @Test
    func testStandardOutputManager() {
        let outputManager = StandardOutputManager()

        // Test output capture
        outputManager.output("Testing standard output manager")

        #expect(outputManager.capturedOutput.count == 1)
        #expect(outputManager.capturedOutput[0] == "Testing standard output manager")

        // Status line should be a no-op but still captured
        outputManager.updateStatusLine(location: "Test Room", score: 10, moves: 5)

        // Test clearing output
        outputManager.clearCapturedOutput()
        #expect(outputManager.capturedOutput.isEmpty)
    }

    @Test
    @MainActor
    func testGameEngineWithMockOutput() {
        // Create a mock output manager with predefined inputs for testing
        let inputs = ["look", "quit"]
        let outputManager = MockOutputManager(inputResponses: inputs)

        // Create a room
        let startRoom = Room(name: "Start Room", description: "This is the starting room.")
        // Make the room naturally lit so it's visible
        startRoom.setFlag(.isNaturallyLit)

        // Create a player starting in that room
        let player = Player(startingRoom: startRoom)

        // Create the game world with the player
        let world = GameWorld(player: player)

        // Register the room with the world
        world.register(room: startRoom)

        // Create the game engine with mock output
        let engine = GameEngine(
            world: world,
            outputManager: outputManager
        )

        // Start game and process the predefined inputs
        try! engine.start()

        // Verify that output contains expected messages
        let output = outputManager.capturedOutput

        #expect(output.contains(where: { $0.contains("Welcome to the Text Adventure") }))
        #expect(output.contains(where: { $0.contains("This is the starting room") }))
        #expect(output.contains(where: { $0.contains("Thanks for playing") }))
    }
}
