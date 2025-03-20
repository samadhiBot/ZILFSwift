import Foundation
import Testing
import ZILFCore
import ZILFTestSupport

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

struct ToyGameTests {
    let harness: GameTestHarness<ToyGame>

    init() {
        let game = ToyGame { _ in }
        harness = GameTestHarness(game: game)
        harness.initialize()
    }

    @Test func testInitialRoomDescription() throws {
        #expect(harness.flush() == """
            Welcome to the Toy Game!

            Version 0.1

            Type 'help' for a list of commands.

            A cozy kitchen with modern appliances.

            You can see:
              apple

            Exits: south
            Location: Kitchen | Score: 0 | Moves: 1
            """)
    }

    @Test func testMoveBetweenRooms() throws {
        // Move to living room
        let moveOutput = harness.execute("south")
        #expect(moveOutput.first == """
            A comfortable living room with a fireplace.
            
            Exits: north
            """)

        // Move back to kitchen
        let moveBackOutput = harness.execute("north")
        #expect(moveBackOutput.first == """
            A cozy kitchen with modern appliances.

            You can see:
              apple

            Exits: south
            """)
    }

    @Test func testTakeAndDropObject() throws {
        // Take the apple
        let takeOutput = harness.execute("take apple")
        #expect(takeOutput.first == "Taken.")

        // Check inventory
        let invOutput = harness.execute("inventory")
        #expect(invOutput[0...1] == [
            "You are carrying:",
            "  apple"
        ])

        // Drop the apple
        let dropOutput = harness.execute("drop apple")
        #expect(dropOutput.first == "Dropped.")

        // Verify apple is no longer in inventory
        let invOutput2 = harness.execute("inventory")
        #expect(invOutput2.first == "You're not carrying anything.")
    }
}
