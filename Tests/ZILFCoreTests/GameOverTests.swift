//
//  GameOverTests.swift
//  ZILFSwift
//
//  Created on current date
//

import Testing
import Foundation
@testable import ZILFCore
import ZILFTestSupport

@Suite struct GameOverTests {
    @Test func testPlayerDeath() throws {
        // Setup a basic test world
        let room = Room(name: "Test Room", description: "A test room")
        room.setFlag(.isNaturallyLit)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.register(room: room)

        // Create a room with a deadly exit
        let deadlyRoom = Room(name: "Deadly Room", description: "A dangerous room")
        deadlyRoom.setFlag(.isNaturallyLit)

        // Connect rooms
        room.setExit(.north, to: deadlyRoom)
        deadlyRoom.setExit(.south, to: room)

        world.register(room: deadlyRoom)

        // Setup output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Verify game is not over at start
        let isGameOver: Bool? = engine.isGameOver
        #expect(isGameOver == nil || isGameOver == false)

        // Trigger player death
        engine.playerDied(message: "You have died!")

        // Verify game over state
        let isGameOverAfter: Bool? = engine.isGameOver
        #expect(isGameOverAfter == true)

        // Check output
        #expect(outputHandler.output.contains("GAME OVER"))
        #expect(outputHandler.output.contains("You have died!"))
        #expect(outputHandler.output.contains("RESTART or QUIT"))
    }

    @Test func testPlayerVictory() throws {
        // Setup a basic test world
        let room = Room(name: "Test Room", description: "A test room")
        room.setFlag(.isNaturallyLit)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.register(room: room)

        // Setup output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Verify game is not over at start
        let isGameOver: Bool? = engine.isGameOver
        #expect(isGameOver == nil || isGameOver == false)

        // Trigger player victory
        engine.playerWon(message: "Congratulations! You've won the game!")

        // Verify game over state
        let isGameOverAfter: Bool? = engine.isGameOver
        #expect(isGameOverAfter == true)

        // Check output
        #expect(outputHandler.output.contains("VICTORY"))
        #expect(outputHandler.output.contains("Congratulations!"))
        #expect(outputHandler.output.contains("RESTART or QUIT"))
    }

    @Test func testDeadlyExit() throws {
        // Setup a basic test world
        let room = Room(name: "Test Room", description: "A test room")
        room.setFlag(.isNaturallyLit)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.register(room: room)

        // Create a room with a deadly exit
        let deadlyRoom = Room(name: "Deadly Room", description: "A dangerous room")
        deadlyRoom.setFlag(.isNaturallyLit)

        // Connect rooms
        room.setExit(.north, to: deadlyRoom)

        // Add a deadly exit
        deadlyRoom.setDeadlyExit(
            direction: .east,
            deathMessage: "You fell into a pit of spikes!",
            world: world
        )

        world.register(room: deadlyRoom)

        // Setup output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Move to deadly room
        try engine.executeCommand(.move(.north))
        outputHandler.clear()

        // Try deadly exit
        try engine.executeCommand(.move(.east))

        // Check result
        #expect(outputHandler.output.contains("You fell into a pit of spikes!"))
        #expect(outputHandler.output.contains("GAME OVER"))
    }

    @Test func testVictoryExit() throws {
        // Setup a basic test world
        let room = Room(name: "Start Room", description: "Starting room")
        room.setFlag(.isNaturallyLit)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.register(room: room)

        // Add a victory condition
        let amulet = GameObject(name: "amulet", description: "A magical amulet.")
        amulet.setFlag(.isTakable)
        amulet.moveTo(player)

        world.register(amulet)

        // Add a victory exit that requires the amulet
        room.setVictoryExit(
            direction: .north,
            victoryMessage: "You've won the game!",
            world: world,
            condition: { _ in
                return player.inventory.contains { $0.name == "amulet" }
            }
        )

        // Setup output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Try victory exit
        try engine.executeCommand(.move(.north))

        // Check result
        #expect(outputHandler.output.contains("You've won the game!"))
        #expect(outputHandler.output.contains("VICTORY"))
    }
}
