//
//  SpecialExitsTests.swift
//  ZILFSwiftTests
//
//  Created by Chris Sessions on 6/25/25.
//

import Foundation
import Testing
@testable import ZILFCore

@Suite struct SpecialExitsTests {

    @Test func testBasicSpecialExits() {
        // Create test rooms
        let room1 = Room(name: "Room 1", description: "Test room 1")
        let room2 = Room(name: "Room 2", description: "Test room 2")
        room1.makeNaturallyLit()
        room2.makeNaturallyLit()

        // Create a player and world
        let player = Player(startingRoom: room1)
        let world = GameWorld(player: player)
        world.register(room: room1)
        world.register(room: room2)

        // Create a special exit
        let specialExit = SpecialExit(
            destination: room2,
            world: world,
            condition: { _ in true },  // Always available
            successMessage: "You successfully used the special exit!",
            failureMessage: "You can't use this exit now."
        )

        // Add the special exit to room1
        room1.setSpecialExit(direction: .north, specialExit: specialExit, world: world)

        // Test that the exit exists
        #expect(room1.getSpecialExit(direction: .north) != nil)

        // Test that the exit condition passes
        #expect(room1.getSpecialExit(direction: .north)?.checkCondition() == true)

        // Test player movement through the special exit
        #expect(player.move(direction: .north))
        #expect(player.currentRoom === room2)
    }

    @Test func testHiddenExit() {
        // Create test rooms
        let room1 = Room(name: "Room 1", description: "Test room 1")
        let room2 = Room(name: "Room 2", description: "Test room 2")
        room1.makeNaturallyLit()
        room2.makeNaturallyLit()

        // Create a player and world
        let player = Player(startingRoom: room1)
        let world = GameWorld(player: player)
        world.register(room: room1)
        world.register(room: room2)

        // Create a variable to control exit visibility
        var exitRevealed = false

        // Create a hidden exit
        room1.setHiddenExit(
            direction: .east,
            destination: room2,
            world: world,
            condition: { _ in exitRevealed },
            revealMessage: "You discovered a hidden passage to the east!"
        )

        // Test that the exit exists but isn't available yet
        #expect(room1.getSpecialExit(direction: .east) != nil)
        #expect(!room1.isSpecialExitAvailable(direction: .east))

        // Test that we can't use the exit
        #expect(!player.move(direction: .east))
        #expect(player.currentRoom === room1)

        // Reveal the exit
        exitRevealed = true

        // Now the exit should be available
        #expect(room1.isSpecialExitAvailable(direction: .east))

        // Test player movement through the now-available exit
        #expect(player.move(direction: .east))
        #expect(player.currentRoom === room2)
    }

    @Test func testLockedExit() {
        // Create test rooms
        let room1 = Room(name: "Room 1", description: "Test room 1")
        let room2 = Room(name: "Room 2", description: "Test room 2")
        room1.makeNaturallyLit()
        room2.makeNaturallyLit()

        // Create a player and world
        let player = Player(startingRoom: room1)
        let world = GameWorld(player: player)
        world.register(room: room1)
        world.register(room: room2)

        // Create a key
        let key = GameObject(name: "brass key", description: "A shiny brass key")
        key.setFlag(.isTakable)
        world.register(key)

        // Create a locked exit
        room1.setLockedExit(
            direction: .west,
            destination: room2,
            world: world,
            key: key,
            lockedMessage: "The door is locked. You need a key.",
            unlockedMessage: "You unlock the door with the brass key."
        )

        // Test that the exit exists but isn't available yet (no key)
        #expect(room1.getSpecialExit(direction: .west) != nil)
        #expect(!room1.isSpecialExitAvailable(direction: .west))

        // Test that we can't use the exit without the key
        #expect(!player.move(direction: .west))
        #expect(player.currentRoom === room1)

        // Give key to player
        key.moveTo(player)

        // Now the exit should be available
        #expect(room1.isSpecialExitAvailable(direction: .west))

        // Test player movement through the now-unlocked exit
        #expect(player.move(direction: .west))
        #expect(player.currentRoom === room2)
    }

    @Test func testOneWayExit() {
        // Create test rooms
        let room1 = Room(name: "Room 1", description: "Test room 1")
        let room2 = Room(name: "Room 2", description: "Test room 2")
        room1.makeNaturallyLit()
        room2.makeNaturallyLit()

        // Create a player and world
        let player = Player(startingRoom: room1)
        let world = GameWorld(player: player)
        world.register(room: room1)
        world.register(room: room2)

        // Create a one-way exit from room1 to room2
        room1.setOneWayExit(
            direction: .down,
            destination: room2,
            world: world,
            message: "You slide down a chute!"
        )

        // Test that the exit exists and is available
        #expect(room1.getSpecialExit(direction: .down) != nil)
        #expect(room1.isSpecialExitAvailable(direction: .down))

        // Test player movement from room1 to room2
        #expect(player.move(direction: .down))
        #expect(player.currentRoom === room2)

        // Verify that there's no return path
        #expect(room2.getExit(direction: .up) == nil)
        #expect(room2.getSpecialExit(direction: .up) == nil)
        #expect(!player.move(direction: .up))
        #expect(player.currentRoom === room2)
    }

    @Test func testScriptedExit() {
        // Create test rooms
        let room1 = Room(name: "Room 1", description: "Test room 1")
        let room2 = Room(name: "Room 2", description: "Test room 2")
        room1.makeNaturallyLit()
        room2.makeNaturallyLit()

        // Create a player and world
        let player = Player(startingRoom: room1)
        let world = GameWorld(player: player)
        world.register(room: room1)
        world.register(room: room2)

        // Create a variable to track script execution
        var scriptExecuted = false

        // Create a scripted exit
        room1.setScriptedExit(
            direction: .south,
            destination: room2,
            world: world,
            script: { _ in
                scriptExecuted = true
            }
        )

        // Test that the exit exists and is available
        #expect(room1.getSpecialExit(direction: .south) != nil)
        #expect(room1.isSpecialExitAvailable(direction: .south))

        // Test player movement through the exit
        #expect(!scriptExecuted)
        #expect(player.move(direction: .south))
        #expect(scriptExecuted)
        #expect(player.currentRoom === room2)
    }

    @Test func testConditionalExit() {
        // Create test rooms
        let room1 = Room(name: "Room 1", description: "Test room 1")
        let room2 = Room(name: "Room 2", description: "Test room 2")
        room1.makeNaturallyLit()
        room2.makeNaturallyLit()

        // Create a player and world
        let player = Player(startingRoom: room1)
        let world = GameWorld(player: player)
        world.register(room: room1)
        world.register(room: room2)

        // Create a variable to control the condition
        var isConditionMet = false

        // Create a conditional exit
        room1.setConditionalExit(
            direction: .north,
            destination: room2,
            world: world,
            condition: { _ in isConditionMet },
            failureMessage: "You can't go that way yet."
        )

        // Test that the exit exists but isn't available yet
        #expect(room1.getSpecialExit(direction: .north) != nil)
        #expect(!room1.isSpecialExitAvailable(direction: .north))

        // Test that we can't use the exit
        #expect(!player.move(direction: .north))
        #expect(player.currentRoom === room1)

        // Meet the condition
        isConditionMet = true

        // Now the exit should be available
        #expect(room1.isSpecialExitAvailable(direction: .north))

        // Test player movement through the now-available exit
        #expect(player.move(direction: .north))
        #expect(player.currentRoom === room2)
    }
}
