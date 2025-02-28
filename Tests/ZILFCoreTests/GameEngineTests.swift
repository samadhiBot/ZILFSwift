//
//  GameEngineTests.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Testing
import Foundation
@testable import ZILFCore

struct GameEngineTests {
    @Test func executeCommand() throws {
        let (world, player, startRoom, northRoom, coin) = try setupTestWorld()

        let outputHandler = TestOutputHandler()
        let engine = GameEngine(world: world, outputHandler: outputHandler)

        // Test look command
        engine.executeCommand(.look)
        #expect(outputHandler.output.contains("Start Room"))
        #expect(outputHandler.output.contains("The starting room"))
        #expect(outputHandler.output.contains("Exits: north"))
        #expect(outputHandler.output.contains("gold coin"))
        outputHandler.clear()

        // Test move command
        engine.executeCommand(.move(.north))
        #expect(player.currentRoom === northRoom)
        #expect(outputHandler.output.contains("North Room"))
        outputHandler.clear()

        // Test invalid move
        engine.executeCommand(.move(.east))
        #expect(player.currentRoom === northRoom)
        #expect(outputHandler.output.contains("You can't go that way"))
        outputHandler.clear()

        // Test examine
        // Go back to the start room where the coin is
        player.move(direction: .south)
        engine.executeCommand(.examine(coin))
        #expect(outputHandler.output.contains("A shiny gold coin"))
        outputHandler.clear()

        // Test take
        engine.executeCommand(.take(coin))
        #expect(outputHandler.output.contains("Taken"))
        #expect(player.contents.contains { $0 === coin })
        outputHandler.clear()

        // Test inventory
        engine.executeCommand(.inventory)
        #expect(outputHandler.output.contains("You are carrying"))
        #expect(outputHandler.output.contains("gold coin"))
        outputHandler.clear()

        // Test drop
        engine.executeCommand(.drop(coin))
        #expect(outputHandler.output.contains("Dropped"))
        #expect(startRoom.contents.contains { $0 === coin })
        #expect(!player.contents.contains { $0 === coin })
        outputHandler.clear()
    }

    // Helper to set up a test world
    func setupTestWorld() throws -> (GameWorld, Player, Room, Room, GameObject) {
        let startRoom = Room(name: "Start Room", description: "The starting room")
        let northRoom = Room(name: "North Room", description: "Room to the north")

        startRoom.setExit(direction: .north, room: northRoom)
        northRoom.setExit(direction: .south, room: startRoom)

        let player = Player(startingRoom: startRoom)
        let world = GameWorld(player: player)

        // Add a takeable object
        let coin = GameObject(name: "gold coin", description: "A shiny gold coin", location: startRoom)
        coin.setFlag("takeable")
        world.registerObject(coin)

        return (world, player, startRoom, northRoom, coin)
    }
}
