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

        let outputHandler = OutputCapture()
        let engine = GameEngine(world: world, outputHandler: outputHandler.handler)

        // Test look command
        try engine.executeCommand(.look)
        #expect(outputHandler.output.contains("The starting room"))
        #expect(outputHandler.output.contains("Exits: north"))
        #expect(outputHandler.output.contains("gold coin"))
        outputHandler.clear()

        // Test move command
        try engine.executeCommand(.move(.north))
        #expect(player.currentRoom === northRoom)
        #expect(outputHandler.output.contains("Room to the north"))
        outputHandler.clear()

        // Test invalid move
        try engine.executeCommand(.move(.east))
        #expect(player.currentRoom === northRoom)
        #expect(outputHandler.output.contains("You can't go that way"))
        outputHandler.clear()

        // Test examine
        // Go back to the start room where the coin is
        player.move(direction: .south)
        try engine.executeCommand(.examine(coin, with: nil))
        #expect(outputHandler.output.contains("A shiny gold coin"))
        outputHandler.clear()

        // Test take
        try engine.executeCommand(.take(coin))
        #expect(outputHandler.output.contains("Taken"))
        #expect(player.inventory.contains { $0 === coin })
        outputHandler.clear()

        // Test inventory
        try engine.executeCommand(.inventory)
        #expect(outputHandler.output.contains("You are carrying"))
        #expect(outputHandler.output.contains("gold coin"))
        outputHandler.clear()

        // Test drop
        try engine.executeCommand(.drop(coin))
        #expect(outputHandler.output.contains("Dropped"))
        #expect(startRoom.contents.contains { $0 === coin })
        #expect(!player.inventory.contains { $0 === coin })
        outputHandler.clear()
    }

    // Helper to set up a test world
    func setupTestWorld() throws -> (GameWorld, Player, Room, Room, GameObject) {
        let startRoom = Room(name: "Start Room", description: "The starting room")
        startRoom.setFlag(.isNaturallyLit) // Make the start room naturally lit for testing

        let northRoom = Room(name: "North Room", description: "Room to the north")
        northRoom.setFlag(.isNaturallyLit) // Make the north room naturally lit for testing

        startRoom.setExit(direction: .north, room: northRoom)
        northRoom.setExit(direction: .south, room: startRoom)

        let player = Player(startingRoom: startRoom)
        let world = GameWorld(player: player)
        world.register(room: startRoom)
        world.register(room: northRoom)

        // Add a takeable object
        let coin = GameObject(name: "gold coin", description: "A shiny gold coin", location: startRoom)
        coin.setFlag(.isTakable)
        world.register(coin)

        return (world, player, startRoom, northRoom, coin)
    }
}
