//
//  GlobalObjectTests.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 8/2/25.
//

import Foundation
import Testing
@testable import ZILFCore

@Suite struct GlobalObjectTests {

    @Test func testGlobalObjects() {
        // Setup a simple world with a few rooms
        let hall = Room(name: "Hall", description: "A large hall.")
        let kitchen = Room(name: "Kitchen", description: "A cozy kitchen.")

        hall.setExit(direction: .east, room: kitchen)
        kitchen.setExit(direction: .west, room: hall)

        let player = Player(startingRoom: hall)
        let world = GameWorld(player: player)

        // Register rooms
        world.register(room: hall)
        world.register(room: kitchen)

        // Set the world reference in rooms for local-global lookup
        hall.setState(world, forKey: "world")
        kitchen.setState(world, forKey: "world")

        // Create a global object - should be accessible from anywhere
        let sky = GameObject(name: "sky", description: "A clear blue sky.")
        world.registerGlobalObject(sky)

        // Create a local-global object - only accessible from specific rooms
        let rug = GameObject(name: "rug", description: "A tatty rug.")
        world.registerGlobalObject(rug, isLocalGlobal: true)

        // Make the rug accessible from the hall only
        hall.addLocalGlobal(rug)

        // Test global objects
        #expect(sky.isGlobalObject())
        #expect(sky.isGlobalObject(localGlobal: false))
        #expect(!sky.isGlobalObject(localGlobal: true))

        // Test local-global objects
        #expect(rug.isGlobalObject())
        #expect(!rug.isGlobalObject(localGlobal: false))
        #expect(rug.isGlobalObject(localGlobal: true))

        // Test accessibility
        #expect(world.isGlobalObjectAccessible(sky, in: hall))
        #expect(world.isGlobalObjectAccessible(sky, in: kitchen))

        #expect(world.isGlobalObjectAccessible(rug, in: hall))
        #expect(!world.isGlobalObjectAccessible(rug, in: kitchen))

        // Test getting accessible rooms for local-global objects
        let accessibleRooms = rug.getAccessibleRooms()
        #expect(accessibleRooms.count == 1)
        #expect(accessibleRooms[0] === hall)

        // Test adding and removing local-global objects from rooms
        kitchen.addLocalGlobal(rug)
        #expect(world.isGlobalObjectAccessible(rug, in: kitchen))

        kitchen.removeLocalGlobal(rug)
        #expect(!world.isGlobalObjectAccessible(rug, in: kitchen))
    }

    @Test func testGlobalObjectsInParser() {
        // Setup a simple world with a few rooms
        let hall = Room(name: "Hall", description: "A large hall.")
        let kitchen = Room(name: "Kitchen", description: "A cozy kitchen.")

        // Make both rooms naturally lit so we can see objects
        hall.setFlag(.isNaturallyLit)
        kitchen.setFlag(.isNaturallyLit)

        hall.setExit(direction: .east, room: kitchen)
        kitchen.setExit(direction: .west, room: hall)

        let player = Player(startingRoom: hall)
        let world = GameWorld(player: player)

        // Register rooms
        world.register(room: hall)
        world.register(room: kitchen)

        // Set the world reference in rooms for local-global lookup
        hall.setState(world, forKey: "world")
        kitchen.setState(world, forKey: "world")

        // Create a global object - should be accessible from anywhere
        let sky = GameObject(name: "sky", description: "A clear blue sky.")
        world.registerGlobalObject(sky)

        // Create a local-global object - only accessible from specific rooms
        let rug = GameObject(name: "rug", description: "A tatty rug.")
        world.registerGlobalObject(rug, isLocalGlobal: true)

        // Make the rug accessible from the hall only
        hall.addLocalGlobal(rug)

        // Create engine to test object interactions
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Test examining global objects
        engine.executeCommand(Command.examine(sky, with: nil))
        #expect(outputHandler.output.contains("A clear blue sky"))
        outputHandler.clear()

        // Test examining local-global objects
        engine.executeCommand(Command.examine(rug, with: nil))
        #expect(outputHandler.output.contains("A tatty rug"))
        outputHandler.clear()

        // Move player to kitchen where rug isn't accessible
        _ = player.move(direction: .east)

        // Should still be able to examine sky from kitchen
        engine.executeCommand(Command.examine(sky, with: nil))
        #expect(outputHandler.output.contains("A clear blue sky"))
        outputHandler.clear()

        // Shouldn't be able to examine rug from kitchen
        engine.executeCommand(Command.examine(rug, with: nil))
        #expect(outputHandler.output.contains("You don't see that here"))
    }

    @Test func testGlobalObjectInteractions() {
        // This test function is a duplicate and should be removed
    }
}
