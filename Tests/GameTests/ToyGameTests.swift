import Foundation
import Testing
import ZILFCore
import ZILFTestSupport

struct ToyGameTests {
    let harness: GameTestHarness<ToyGame>

    init() {
        let game = ToyGame { _ in /* Output is handled by harness */ }
        harness = GameTestHarness(game: game)
        harness.initialize()
    }

    @Test
    func testInitialRoomDescription() throws {
        let outputs = harness.outputCapture.capturedOutput

        // Check for welcome message
        #expect(outputs.contains(where: { $0.contains("Welcome to the Toy Game") }))

        // Check for initial room description
        #expect(outputs.contains(where: { $0.contains("A cozy kitchen") }))
    }

    @Test
    func testMoveBetweenRooms() throws {
        // Move to living room
        let moveOutput = harness.execute("south")
        #expect(moveOutput.contains(where: { $0.contains("Living Room") }))
        #expect(moveOutput.contains(where: { $0.contains("fireplace") }))

        // Move back to kitchen
        let moveBackOutput = harness.execute("north")
        #expect(moveBackOutput.contains(where: { $0.contains("Kitchen") }))
        #expect(moveBackOutput.contains(where: { $0.contains("appliances") }))
    }

    @Test
    func testTakeAndDropObject() throws {
        // Take the apple
        let takeOutput = harness.execute("take apple")
        #expect(takeOutput.contains("Taken."))

        // Check inventory
        let invOutput = harness.execute("inventory")
        #expect(invOutput.contains(where: { $0.contains("apple") }))

        // Drop the apple
        let dropOutput = harness.execute("drop apple")
        #expect(dropOutput.contains("Dropped."))

        // Verify apple is no longer in inventory
        let invOutput2 = harness.execute("inventory")
        #expect(invOutput2.contains("You're not carrying anything."))
    }
}

// Updated ToyGame to match the new ZilfGame protocol
struct ToyGame: ZilfGame {
    let output: (String) -> Void
    let versionInfo: String = "Version 0.1"
    let welcomeText: String = "Welcome to the Toy Game!"

    init(output: @escaping (String) -> Void) {
        self.output = output
    }

    func createWorld() -> GameWorld {
        // Create rooms
        let kitchen = Room(
            name: "Kitchen",
            description: "A cozy kitchen with modern appliances.",
            flags: .isNaturallyLit
        )
        let livingRoom = Room(
            name: "Living Room",
            description: "A comfortable living room with a fireplace.",
            flags: .isNaturallyLit
        )

        // Create player and world
        let player = Player(startingRoom: kitchen)
        let gameWorld = GameWorld(player: player)

        // Connect rooms
        kitchen.exits[.south] = livingRoom
        livingRoom.exits[.north] = kitchen

        // Register rooms
        gameWorld.register(room: kitchen)
        gameWorld.register(room: livingRoom)

        // Add objects
        let apple = GameObject(
            name: "apple",
            description: "A shiny red apple.",
            location: kitchen,
            flags: .isTakable
        )
        gameWorld.register(apple)

        return gameWorld
    }
}
