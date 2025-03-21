import Testing
import ZILFTestSupport

struct ToyGameTests {
    let harness: GameTestHarness<ToyGame>

    init() {
        let game = ToyGame { _ in }
        harness = GameTestHarness(for: game)
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

