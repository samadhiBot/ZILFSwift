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
    @Test func testPlayerDeath() {
        // Setup a basic test world
        let room = Room(name: "Test Room", description: "A test room")
        room.makeNaturallyLit()

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.registerRoom(room)

        // Create a room with a deadly exit
        let deadlyRoom = Room(name: "Deadly Room", description: "A dangerous room")
        deadlyRoom.makeNaturallyLit()

        // Connect rooms
        room.setExit(direction: .north, room: deadlyRoom)
        deadlyRoom.setExit(direction: .south, room: room)

        world.registerRoom(deadlyRoom)

        // Setup output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Verify game is not over at start
        let isGameOver: Bool? = engine.getState(forKey: "isGameOver")
        #expect(isGameOver == nil || isGameOver == false)

        // Trigger player death
        engine.playerDied(message: "You have died!")

        // Verify game over state
        let isGameOverAfter: Bool? = engine.getState(forKey: "isGameOver")
        #expect(isGameOverAfter == true)

        // Check output
        #expect(outputHandler.output.contains("GAME OVER"))
        #expect(outputHandler.output.contains("You have died!"))
        #expect(outputHandler.output.contains("RESTART or QUIT"))
    }

    @Test func testPlayerVictory() {
        // Setup a basic test world
        let room = Room(name: "Test Room", description: "A test room")
        room.makeNaturallyLit()

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.registerRoom(room)

        // Setup output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Verify game is not over at start
        let isGameOver: Bool? = engine.getState(forKey: "isGameOver")
        #expect(isGameOver == nil || isGameOver == false)

        // Trigger player victory
        engine.playerWon(message: "Congratulations! You've won the game!")

        // Verify game over state
        let isGameOverAfter: Bool? = engine.getState(forKey: "isGameOver")
        #expect(isGameOverAfter == true)

        // Check output
        #expect(outputHandler.output.contains("VICTORY"))
        #expect(outputHandler.output.contains("Congratulations!"))
        #expect(outputHandler.output.contains("RESTART or QUIT"))
    }

    @Test func testDeadlyExit() {
        // Setup a basic test world
        let room = Room(name: "Test Room", description: "A test room")
        room.makeNaturallyLit()

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.registerRoom(room)

        // Create a room with a deadly exit
        let deadlyRoom = Room(name: "Deadly Room", description: "A dangerous room")
        deadlyRoom.makeNaturallyLit()

        // Connect rooms
        room.setExit(direction: .north, room: deadlyRoom)

        // Add a deadly exit
        deadlyRoom.setDeadlyExit(
            direction: .east,
            deathMessage: "You fell into a pit of spikes!",
            world: world
        )

        world.registerRoom(deadlyRoom)

        // Setup output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Move to deadly room
        engine.executeCommand(.move(.north))
        outputHandler.clear()

        // Try deadly exit
        engine.executeCommand(.move(.east))

        // Check result
        #expect(outputHandler.output.contains("You fell into a pit of spikes!"))
        #expect(outputHandler.output.contains("GAME OVER"))
    }

    @Test func testVictoryExit() {
        // Setup a basic test world
        let room = Room(name: "Start Room", description: "Starting room")
        room.makeNaturallyLit()

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.registerRoom(room)

        // Add a victory condition
        let amulet = GameObject(name: "golden amulet", description: "A magical amulet")
        amulet.setFlag("takeable")
        amulet.location = player
        player.contents.append(amulet)

        world.registerObject(amulet)

        // Add a victory exit that requires the amulet
        room.setVictoryExit(
            direction: .north,
            victoryMessage: "You've won the game!",
            world: world,
            condition: { _ in
                return player.contents.contains { $0.name == "golden amulet" }
            }
        )

        // Setup output capture
        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Try victory exit
        engine.executeCommand(.move(.north))

        // Check result
        #expect(outputHandler.output.contains("You've won the game!"))
        #expect(outputHandler.output.contains("VICTORY"))
    }
}
