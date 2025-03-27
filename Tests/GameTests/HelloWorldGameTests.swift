import CustomDump
import Testing
import ZILFTestSupport

@testable import HelloWorldGame
@testable import ZILFCore

struct HelloWorldGameTests {
    let harness: GameTestHarness<HelloWorldGame>
    var engine: GameEngine { harness.engine }
    var world: GameWorld { engine.world }
    var player: Player { world.player }

    init() throws {
        let game = HelloWorldGame { _ in }
        harness = try GameTestHarness(for: game)
        try harness.initialize()
    }

    @Test func testGameCreation() throws {
        // Verify world properties
        #expect(player.currentRoom?.name == "Entrance")
        #expect(world.rooms.count == 6)
        print("🎾", world.rooms)

        // Find rooms
        let entrance = try world.find(room: "entrance")
        let mainCavern = try world.find(room: "mainCavern")
        let treasureRoom = try world.find(room: "treasureRoom")
        let secretRoom = try world.find(room: "secretChamber")
        let vaultRoom = try world.find(room: "ancientVault")
        let ledge = try world.find(room: "unstableLedge")

        // Verify standard room connections
        #expect(entrance.find(exit: .north) === mainCavern)
        #expect(mainCavern.find(exit: .south) === entrance)
        #expect(mainCavern.find(exit: .east) === treasureRoom)
        #expect(treasureRoom.find(exit: .west) === mainCavern)
        #expect(ledge.find(exit: .north) === treasureRoom)

        // Verify special exits exist (not testing condition)
        #expect(treasureRoom.find(specialExit: .down) != nil)
        #expect(secretRoom.find(specialExit: .north) != nil)
        #expect(vaultRoom.find(specialExit: .down) != nil)
        #expect(ledge.find(specialExit: .down) != nil)

        // Verify the one-way exit destination
        #expect(vaultRoom.find(specialExit: .down)?.destination === mainCavern)

        // Verify objects
        let lantern = try world.find("lantern")
        let coin = try world.find("goldCoin")
        let chest = try world.find("treasureChest")
        let amulet = try world.find("goldenAmulet")
        let ancientKey = try world.find("ancientKey")

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

    @Test func testWelcomeMessage() throws {
        expectNoDifference(harness.flush(), """
            ====================================
            Welcome to Hello World Adventure!
            A tiny demonstration game using ZILF
            ====================================
            
            Hello World Game v1.0
            
            Type 'help' for a list of commands.
            
            You are standing at the entrance to a small cave. Sunlight streams in from outside.
            
            You can see:
              lantern
              magnifying glass
            
            Exits: north
            """)
    }

    @Test func testGameCommands() throws {
        // clear welcome text
        harness.flush()

        // Test initial look command
        try engine.executeCommand(.look)
        expectNoDifference(harness.flush(), """
            You are standing at the entrance to a small cave. Sunlight streams in from outside.
            
            You can see:
              lantern
              magnifying glass
            
            Exits: north
            """)

        // Test taking the lantern
        let lantern = try world.find("lantern" )
        try engine.executeCommand(.take(lantern))
        expectNoDifference(harness.flush(), "Taken.")
        #expect(player.inventory.contains(lantern))

        // Test examining the lantern after taking it
        try engine.executeCommand(.examine(lantern))
        expectNoDifference(harness.flush(), "A brass lantern that provides warm light.")

        // Test moving to the main cavern
        try engine.executeCommand(.move(.north))
        #expect(player.currentRoom?.name == "Main Cavern")
        expectNoDifference(harness.flush(), """
            This spacious cavern has smooth walls that glisten with moisture. A strange glow \
            emanates from deeper in the cave.

            You can see:
              gold coin
              dagger

            Exits: south, east
            """)

        // Test taking the coin
        let coin = try world.find("goldCoin")
        try engine.executeCommand(.take(coin))
        #expect(player.inventory.contains { $0.name == "gold coin" })
        expectNoDifference(harness.flush(), "Taken.")

        // Test inventory
        try engine.executeCommand(.inventory)
        expectNoDifference(harness.flush(), """
            You are carrying:
              lantern
              gold coin
            """)

        // Test moving to the treasure room
        try engine.executeCommand(.move(.east))
        #expect(player.currentRoom?.name == "Treasure Room")
        expectNoDifference(harness.flush(), """
            You feel a sense of awe as you enter this ancient chamber.

            This small chamber is filled with a soft, magical light. The walls are adorned with \
            ancient markings.

            You can see:
              treasure chest
              locked box

            Exits: south, west
            """)

        // Test examining the chest
        let chest = try world.find("treasureChest" )
        try engine.executeCommand(.examine(chest))
        expectNoDifference(harness.flush(), "An ornate wooden chest with intricate carvings.")

        // Test trying to take the chest (which shouldn't be take-able)
        try engine.executeCommand(.take(chest))
        #expect(!player.inventory.contains(chest))
        expectNoDifference(harness.flush(), "You can't take that.")

        // Test going back to the main cavern
        try engine.executeCommand(.move(.west))
        #expect(player.currentRoom?.name == "Main Cavern")
        expectNoDifference(harness.flush(), """
            This spacious cavern has smooth walls that glisten with moisture. A strange glow \
            emanates from deeper in the cave.

            You can see:
              dagger

            Exits: south, east
            """)

        // Test dropping the coin
        try engine.executeCommand(.drop(coin))
        #expect(!player.inventory.contains(coin))
        #expect(player.currentRoom?.contents.contains(coin) ?? false)
        expectNoDifference(harness.flush(), "Dropped.")
    }

    @Test func testParser() throws {
        let parser = engine.parser

        // Test direction commands
        if case let .move(direction) = parser.parse("north", in: world) {
            #expect(direction == .north)
        } else {
            throw TestFailure("Expected move command")
        }

        if case let .move(direction) = parser.parse("n", in: world) {
            #expect(direction == .north)
        } else {
            throw TestFailure("Expected move command")
        }

        // Test look command
        guard case .look = parser.parse("look", in: world) else {
            throw TestFailure("Expected look command")
        }

        // Test examine command
        let lantern = try world.find("lantern")
        if case let .examine(obj, _) = parser.parse("examine lantern", in: world) {
            #expect(obj === lantern)
        } else {
            throw TestFailure("Expected examine command")
        }

        // Test take command
        if case let .take(obj) = parser.parse("take lantern", in: world) {
            #expect(obj === lantern)
        } else {
            throw TestFailure("Expected take command")
        }

        // Test inventory command
        guard case .inventory = parser.parse("inventory", in: world) else {
            throw TestFailure("Expected inventory command")
        }

        // Test quit command
        guard case .quit = parser.parse("quit", in: world) else {
            throw TestFailure("Expected quit command")
        }
    }

    @Test func testUnstableLedge() throws {
        // Skip the welcome
        harness.flush()

        // Navigate to the Treasure Room first
        try engine.executeCommand(.move(.north)) // Move to Main Cavern
        #expect(player.currentRoom?.name == "Main Cavern")
        expectNoDifference(harness.flush(), """
            This spacious cavern has smooth walls that glisten with moisture. A strange glow \
            emanates from deeper in the cave.

            You can see:
              gold coin
              dagger

            Exits: south, east
            """)

        try engine.executeCommand(.move(.east)) // Move to Treasure Room
        #expect(player.currentRoom?.name == "Treasure Room")
        expectNoDifference(harness.flush(), """
            You feel a sense of awe as you enter this ancient chamber.
            
            This small chamber is filled with a soft, magical light. The walls are adorned with \
            ancient markings.

            You can see:
              treasure chest
              locked box

            Exits: south, west
            """)

        // Move to the Unstable Ledge
        try engine.executeCommand(.move(.south))
        #expect(player.currentRoom?.name == "Unstable Ledge")
        expectNoDifference(harness.flush(), """
            You stand at the edge of a crumbling ledge above a bottomless pit. The ground feels \
            very unstable.

            Exits: north
            """)

        // Test examining the room (using look instead of examine with a string)
        try engine.executeCommand(.look)
        expectNoDifference(harness.flush(), """
            You stand at the edge of a crumbling ledge above a bottomless pit. The ground feels \
            very unstable.

            Exits: north
            """)

        // Test moving back to safety
        try engine.executeCommand(.move(.north))
        #expect(player.currentRoom?.name == "Treasure Room")
        expectNoDifference(harness.flush(), """
            You feel a sense of awe as you enter this ancient chamber.
            
            This small chamber is filled with a soft, magical light. The walls are adorned with \
            ancient markings.

            You can see:
              treasure chest
              locked box

            Exits: south, west
            """)

        // Return to the Unstable Ledge to test the deadly exit
        try engine.executeCommand(.move(.south))
        expectNoDifference(harness.flush(), """
            You stand at the edge of a crumbling ledge above a bottomless pit. The ground feels \
            very unstable.

            Exits: north
            """)

        // Test falling into the pit (deadly exit)
        try engine.executeCommand(.move(.down))
        expectNoDifference(harness.flush(), """
            You step forward and the ledge gives way beneath you. You fall into darkness, \
            tumbling endlessly into the abyss...

            *** GAME OVER ***
            
            Would you like to RESTART or QUIT?
            """)

        #expect(engine.state == .defeat("""
            You step forward and the ledge gives way beneath you. You fall into darkness, \
            tumbling endlessly into the abyss...
            """))
    }

    @Test func testVictoryCondition() throws {
        // Skip the welcome
        harness.flush()

        // Force the player to the Main Cavern to start fresh
        player.moveTo(try world.find(room: "mainCavern"))

        // Refresh the display
        try engine.executeCommand(.look)
        expectNoDifference(harness.flush(), """
            This spacious cavern has smooth walls that glisten with moisture. \
            A strange glow emanates from deeper in the cave.

            You can see:
              gold coin
              dagger

            Exits: south, east
            """)


        // Get the amulet directly
        let amulet = try world.find("goldenAmulet")
        amulet.moveTo(player)

        // Check inventory has the amulet
        try engine.executeCommand(.inventory)
        expectNoDifference(harness.flush(), """
            You are carrying:
              golden amulet
            """)

        // Try moving west (this should trigger victory)
        try engine.executeCommand(.move(.west))
        expectNoDifference(harness.flush(), """
            As you move west with the golden amulet in your possession, it begins to glow \
            brightly. The cave wall shimmers and dissolves, revealing a hidden passage. \
            You step through and find yourself in a magical realm beyond the cave. \
            Congratulations, you've completed the adventure!

            *** VICTORY ***
            
            Would you like to RESTART or QUIT?
            """)

        #expect(engine.state == .victory("""
            As you move west with the golden amulet in your possession, it begins to glow \
            brightly. The cave wall shimmers and dissolves, revealing a hidden passage. \
            You step through and find yourself in a magical realm beyond the cave. \
            Congratulations, you've completed the adventure!
            """))
    }

//    @Test func testSecretChamber() throws {
//        let world = HelloWorldGame.create()
//        let outputHandler = CaptureConsole()
//        let engine = GameEngine(world: world, outputManager: outputHandler)
//
//        // Move to Main Cavern
//        try engine.executeCommand(.move(.north))
//        expectNoDifference(harness.flush(), """
//            This spacious cavern has smooth walls that glisten with moisture. A strange glow \
//            emanates from deeper in the cave.
//            
//            You can see:
//              gold coin
//              dagger
//            
//            Exits: south, east
//            """)
//
//        // Get the dagger from the main cavern
//        let dagger = try world.find("dagger")
//        try engine.executeCommand(.take(dagger))
//        expectNoDifference(harness.flush(), """
//            Taken.
//            """)
//
//        // Move to Treasure Room
//        try engine.executeCommand(.move(.east))
//        expectNoDifference(harness.flush(), """
//            You feel a sense of awe as you enter this ancient chamber.
//            This small chamber is filled with a soft, magical light. The walls are adorned with \
//            ancient markings.
//            
//            You can see:
//              treasure chest
//              locked box
//            
//            Exits: south, west
//            """)
//
//        // First examine the room to discover the hidden exit
//        let treasureRoom = try world.find(room: "Treasure Room")
//        try engine.executeCommand(.examine(treasureRoom))
//        expectNoDifference(harness.flush(), """
//            ?
//            """)
//
//        // After examining, we can't check the output because it's cleared by the call
//        // So let's move on to the next steps
//
//        // Break open the locked box using the dagger
//        let lockedBox = try world.find("box")
//        try engine.executeCommand(.attack(lockedBox, with: dagger))
//        let _ = harness.flush() // The output is capture by the handler already
//
//        // Now we should be able to go down to the secret chamber
//        // We might need to move around to trigger the hidden exit
//        try engine.executeCommand(.look)
//        let _ = harness.flush()
//
//        // Attempt to go down to the secret chamber
//        try engine.executeCommand(.move(.down))
//
//        // If we didn't make it to the Secret Chamber, force the move
//        if player.currentRoom?.name != "Secret Chamber" {
////            player.moveTo(try world.find(room: "Secret Chamber"))
//        }
//        #expect(player.currentRoom?.name == "Secret Chamber")
//        let _ = harness.flush()
//
//        // Test examining the secret chamber
//        try engine.executeCommand(.look)
//        let lookOutput = harness.flush()
//        #expect(lookOutput.contains("symbols") || lookOutput.contains("chamber"))
//
//        // Test leaving the secret chamber (north exit is locked, needs the ancient key)
//        let ancientKey = try world.find("key")
//        ancientKey.moveTo(player)
//
//        // This should take us to the Ancient Vault or back to Main Cavern via a chute
//        try engine.executeCommand(.move(.north))
//        let _ = harness.flush()
//
//        // Should enter the Ancient Vault with the key, or some other room via a special exit
//        let endingRoom = player.currentRoom?.name ?? ""
//        #expect(endingRoom == "Ancient Vault" || endingRoom == "Main Cavern" || endingRoom.contains("Vault"))
//    }
}
