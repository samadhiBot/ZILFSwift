import CustomDump
import Testing
import ZILFTestSupport

@testable import HelloWorldGame
@testable import ZILFCore

@Suite
@MainActor
struct HelloWorldGameTests {
    @Test func testGameCreation() throws {
        let world = HelloWorldGame.create()

        // Verify world properties
        #expect(world.player.currentRoom?.name == "Entrance")
        #expect(world.rooms.count == 6)

        // Find rooms
        let entrance = try world.find(room: "Entrance")
        let mainCavern = try world.find(room: "Main Cavern")
        let treasureRoom = try world.find(room: "Treasure Room")
        let secretRoom = try world.find(room: "Secret Chamber")
        let vaultRoom = try world.find(room: "Ancient Vault")
        let pitRoom = try world.find(room: "Unstable Ledge")

        // Verify standard room connections
        #expect(entrance.find(exit: .north) === mainCavern)
        #expect(mainCavern.find(exit: .south) === entrance)
        #expect(mainCavern.find(exit: .east) === treasureRoom)
        #expect(treasureRoom.find(exit: .west) === mainCavern)

        // Verify special exits exist (not testing condition)
        #expect(treasureRoom.find(specialExit: .down) != nil)
        #expect(secretRoom.find(specialExit: .north) != nil)
        #expect(vaultRoom.find(specialExit: .down) != nil)

        // Verify the one-way exit destination
        #expect(vaultRoom.find(specialExit: .down)?.destination === mainCavern)

        // Verify objects
        let lantern = try world.find(object: "lantern")
        let coin = try world.find(object: "gold coin")
        let chest = try world.find(object: "treasure chest")
        let amulet = try world.find(object: "golden amulet")
        let ancientKey = try world.find(object: "ancient key")

        // Verify object locations
        #expect(lantern.location === entrance)
        #expect(coin.location === mainCavern)
        #expect(chest.location === treasureRoom)
        #expect(amulet.location === chest)
        #expect(ancientKey.location === secretRoom)

        // Verify object properties
        #expect(lantern.hasFlag(.isTakable))
        #expect(coin.hasFlag(.isTakable))
        #expect(!chest.hasFlag(.isTakable))
        #expect(amulet.hasFlag(.isTakable))
        #expect(ancientKey.hasFlag(.isTakable))

        // Verify chest is not open
        #expect(!chest.hasFlag(.isOpen))

        // Verify light sources
        #expect(lantern.hasFlag(.isLightSource))
        #expect(!lantern.hasFlag(.isOn))  // Initially not lit
        #expect(amulet.hasFlag(.isLightSource))
        #expect(amulet.hasFlag(.isOn))  // Initially lit
    }

    @Test func testGameCommands() throws {
        let world = HelloWorldGame.create()
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputManager: outputHandler)

        // Test initial look command
        try engine.executeCommand(.look)
        expectNoDifference(outputHandler.flush(), """
            You are standing at the entrance to a small cave. Sunlight streams in from outside.
            
            You can see:
              lantern
              magnifying glass
            
            Exits: north
            Location: Entrance | Score: 0 | Moves: 1
            """)

        // Test taking the lantern
        let lantern = try world.find(object: "lantern" )
        try engine.executeCommand(.take(lantern))
        expectNoDifference(outputHandler.flush(), """
            Taken.
            Location: Entrance | Score: 0 | Moves: 2
            """)
        #expect(world.player.inventory.contains(lantern))

        // Test examining the lantern after taking it
        try engine.executeCommand(.examine(lantern))
        expectNoDifference(outputHandler.flush(), """
            A brass lantern that provides warm light.
            Location: Entrance | Score: 0 | Moves: 3
            """)

        // Test moving to the main cavern
        try engine.executeCommand(.move(.north))
        print("Output after move north: \(outputHandler.output)")
        #expect(world.player.currentRoom?.name == "Main Cavern")
        expectNoDifference(outputHandler.flush(), """
            This spacious cavern has smooth walls that glisten with moisture. A strange glow \
            emanates from deeper in the cave.
            
            You can see:
              gold coin
              dagger
            
            Exits: south, east
            Location: Main Cavern | Score: 0 | Moves: 4
            """)

        // Test taking the coin
        let coin = try world.find(object: "gold coin" )
        try engine.executeCommand(.take(coin))
        #expect(world.player.inventory.contains { $0.name == "gold coin" })
        expectNoDifference(outputHandler.flush(), """
            Taken.
            Location: Main Cavern | Score: 0 | Moves: 5
            """)

        // Test inventory
        try engine.executeCommand(.inventory)
        expectNoDifference(outputHandler.flush(), """
            You are carrying:
              lantern
              gold coin
            Location: Main Cavern | Score: 0 | Moves: 6
            """)

        // Test moving to the treasure room
        try engine.executeCommand(.move(.east))
        #expect(world.player.currentRoom?.name == "Treasure Room")
        expectNoDifference(outputHandler.flush(), """
            This small chamber is filled with a soft, magical light. The walls are adorned with \
            ancient markings.
            
            You can see:
              treasure chest
              locked box
            
            Exits: south, west
            Location: Treasure Room | Score: 0 | Moves: 7
            """)

        // Test examining the chest
        let chest = try world.find(object: "treasure chest" )
        try engine.executeCommand(.examine(chest))
        expectNoDifference(outputHandler.flush(), """
            An ornate wooden chest with intricate carvings.
            Location: Treasure Room | Score: 0 | Moves: 8
            """)

        // Test trying to take the chest (which shouldn't be take-able)
        try engine.executeCommand(.take(chest))
        #expect(!world.player.inventory.contains(chest))
        expectNoDifference(outputHandler.flush(), """
            You can't take that.
            Location: Treasure Room | Score: 0 | Moves: 9
            """)

        // Test going back to the main cavern
        try engine.executeCommand(.move(.west))
        #expect(world.player.currentRoom?.name == "Main Cavern")
        expectNoDifference(outputHandler.flush(), """
            This spacious cavern has smooth walls that glisten with moisture. A strange glow \
            emanates from deeper in the cave.
            
            You can see:
              dagger
            
            Exits: south, east
            Location: Main Cavern | Score: 0 | Moves: 10
            """)

        // Test dropping the coin
        try engine.executeCommand(.drop(coin))
        #expect(!world.player.inventory.contains(coin))
        #expect(world.player.currentRoom?.contents.contains(coin) ?? false)
        expectNoDifference(outputHandler.flush(), """
            Dropped.
            Location: Main Cavern | Score: 0 | Moves: 11
            """)
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
        guard case .look = parser.parse("look") else {
            throw TestFailure("Expected look command")
        }

        // Test examine command
        let lantern = try world.find(object: "lantern" )
        if case let .examine(obj, _) = parser.parse("examine lantern") {
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
        guard case .inventory = parser.parse("inventory") else {
            throw TestFailure("Expected inventory command")
        }

        // Test quit command
        guard case .quit = parser.parse("quit") else {
            throw TestFailure("Expected quit command")
        }
    }
}
