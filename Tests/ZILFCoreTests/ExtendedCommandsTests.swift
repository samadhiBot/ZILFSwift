import Testing
@testable import ZILFCore
import ZILFTestSupport

struct ExtendedCommandsTests {
    @Test func testCommandCreation() {
        // Test creating basic commands
        let wearCommand = Command.wear
        #expect(wearCommand == .wear)

        let unwearCommand = Command.unwear
        #expect(unwearCommand == .unwear)
    }

    @Test func testVerbParsing() {
        // Create test objects and world
        let room = Room(name: "Test Room", description: "A test room")
        room.makeNaturallyLit() // Make the room naturally lit

        let hat = GameObject(name: "hat", description: "A fancy hat", location: room)
        hat.setFlag(.isTakable)
        hat.setFlag(.isWearable)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.register(room: room)
        world.register(hat)

        // First move the hat to the player's inventory
        hat.moveTo(player)

        let parser = CommandParser(world: world)

        // Test parsing a wear command
        let command = parser.parse("wear hat")
        #expect(command == .wear)
    }

    @Test func testVerbExecution() {
        // Create test objects and world
        let room = Room(name: "Test Room", description: "A test room")
        room.makeNaturallyLit() // Make the room naturally lit

        let hat = GameObject(name: "hat", description: "A fancy hat", location: room)
        hat.setFlag(.isTakable)
        hat.setFlag(.isWearable)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.register(room: room)
        world.register(hat)

        // Create engine with output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Move hat to inventory
        hat.moveTo(player)
        outputHandler.clear()

        // Set the hat as the last mentioned object so it's the context for the command
        world.lastMentionedObject = hat

        // Execute wear command
        engine.executeCommand(.wear)

        // Verify hat is now worn
        #expect(hat.hasFlag(.isBeingWorn), "Hat should be worn after wear command")
        #expect(outputHandler.output.contains("You put on"), "Output should indicate hat was worn")

        outputHandler.clear()

        // Execute unwear command
        engine.executeCommand(.unwear)

        // Verify hat is no longer worn
        #expect(!hat.hasFlag(.isBeingWorn), "Hat should not be worn after unwear command")
        #expect(outputHandler.output.contains("You take off"), "Output should indicate hat was taken off")
    }
}
