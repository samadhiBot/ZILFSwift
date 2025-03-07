import Testing
@testable import ZILFCore
import ZILFTestSupport

struct ExtendedCommandsTests {
    @Test func testExtendedCommandCreation() {
        // Test creating wear commands
        let obj = GameObject(name: "hat", description: "A fancy hat")
        let wearCommand = Command.wear(obj)

        if case let .customCommand(verb, objects, _) = wearCommand {
            #expect(verb == "wear")
            #expect(objects.count == 1)
            #expect(objects[0] === obj)
        } else {
            #expect(false, "Expected a customCommand for wear")
        }

        // Test creating unwear commands
        let unwearCommand = Command.unwear(obj)

        if case let .customCommand(verb, objects, _) = unwearCommand {
            #expect(verb == "unwear")
            #expect(objects.count == 1)
            #expect(objects[0] === obj)
        } else {
            #expect(false, "Expected a customCommand for unwear")
        }
    }

    @Test func testExtendedVerbParsing() {
        // Create test objects and world
        let room = Room(name: "Test Room", description: "A test room")
        room.makeNaturallyLit() // Make the room naturally lit

        let hat = GameObject(name: "hat", description: "A fancy hat", location: room)
        hat.setFlag(String.takeBit)
        hat.setFlag(String.wearBit)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.registerRoom(room)
        world.registerObject(hat)

        // First move the hat to the player's inventory
        hat.moveTo(player)

        let parser = CommandParser(world: world)

        // Test parsing a wear command
        let command = parser.parse("wear hat")

        if case let .customCommand(verb, objects, _) = command {
            #expect(verb == "wear")
            #expect(objects.count == 1)
            #expect(objects[0] === hat)
        } else {
            #expect(false, "Expected a customCommand for 'wear hat'")
        }
    }

    @Test func testExtendedVerbExecution() {
        // Create test objects and world
        let room = Room(name: "Test Room", description: "A test room")
        room.makeNaturallyLit() // Make the room naturally lit

        let hat = GameObject(name: "hat", description: "A fancy hat", location: room)
        hat.setFlag(String.takeBit)
        hat.setFlag(String.wearBit)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.registerRoom(room)
        world.registerObject(hat)

        // Create engine with output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // First take the hat
        engine.executeCommand(Command.take(hat))
        outputHandler.clear()

        // Execute wear command
        engine.executeCommand(Command.wear(hat))

        // Verify hat is now worn
        #expect(hat.hasFlag(String.wornBit), "Hat should be worn after wear command")
        #expect(outputHandler.output.contains("You put on"), "Output should indicate hat was worn")

        outputHandler.clear()

        // Execute unwear command
        engine.executeCommand(Command.unwear(hat))

        // Verify hat is no longer worn
        #expect(!hat.hasFlag(String.wornBit), "Hat should not be worn after unwear command")
        #expect(outputHandler.output.contains("You take off"), "Output should indicate hat was taken off")
    }
}
