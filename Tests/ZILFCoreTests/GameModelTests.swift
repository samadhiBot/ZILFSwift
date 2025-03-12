//
//  GameModelTests.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Testing
@testable import ZILFCore

struct GameModelTests {
    @Test func roomCreation() {
        let room = Room(name: "Test Room", description: "A test room")

        #expect(room.name == "Test Room")
        #expect(room.description == "A test room")
        #expect(room.contents.isEmpty)
        #expect(room.exits.isEmpty)
    }

    @Test func roomExits() {
        let room1 = Room(name: "Room 1", description: "First room")
        let room2 = Room(name: "Room 2", description: "Second room")

        room1.setExit(direction: .north, room: room2)
        room2.setExit(direction: .south, room: room1)

        #expect(room1.getExit(direction: .north) === room2)
        #expect(room2.getExit(direction: .south) === room1)
        #expect(room1.getExit(direction: .east) == nil)
    }

    @Test func objectLocation() {
        let room = Room(name: "Room", description: "A room")
        let obj = GameObject(name: "Object", description: "A test object", location: room)

        #expect(obj.location === room)
        #expect(room.contents.contains { $0 === obj })
        #expect(obj.isIn(room))
    }

    @Test func playerMovement() {
        let startRoom = Room(name: "Start", description: "Starting room")
        let northRoom = Room(name: "North", description: "Northern room")
        startRoom.setExit(direction: .north, room: northRoom)
        northRoom.setExit(direction: .south, room: startRoom)

        let player = Player(startingRoom: startRoom)

        #expect(player.currentRoom === startRoom)
        #expect(player.move(direction: .north))
        #expect(player.currentRoom === northRoom)
        #expect(player.move(direction: .south))
        #expect(player.currentRoom === startRoom)
        #expect(!player.move(direction: .east))
    }

    @Test func objectFlags() {
        let obj = GameObject(name: "Object", description: "Test object")

        #expect(!obj.hasFlag(.isTakable))
        obj.setFlag(.isTakable)
        #expect(obj.hasFlag(.isTakable))
        obj.clearFlag(.isTakable)
        #expect(!obj.hasFlag(.isTakable))
    }

    @Test func testItReference() throws {
        let room = Room(name: "Room", description: "A test room")
        let obj1 = GameObject(name: "red ball", description: "A red ball", location: room)
        obj1.setFlag(.isTakable)
        let obj2 = GameObject(name: "blue book", description: "A blue book", location: room)
        obj2.setFlag(.isTakable)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)

        world.lastMentionedObject = obj1

        let parser = CommandParser(world: world)

        // Test examining "it"
        if case let .examine(obj, _) = parser.parse("examine it") {
            #expect(obj === obj1)
        } else {
            throw TestFailure("Expected examine command for 'it'")
        }

        // Test taking "it"
        if case let .take(obj) = parser.parse("take it") {
            #expect(obj === obj1)
        } else {
            throw TestFailure("Expected take command for 'it'")
        }

        // Change the referenced object
        world.lastMentionedObject = obj2

        // Test examining "it" again
        if case let .examine(obj, _) = parser.parse("examine it") {
            #expect(obj === obj2)
        } else {
            throw TestFailure("Expected examine command for 'it'")
        }

        // Test when "it" refers to nothing
        world.lastMentionedObject = nil
        // When "it" refers to nothing, findObject returns nil, so we get a nil object in the command
        if case let .examine(obj, _) = parser.parse("examine it") {
            #expect(obj == nil)
        } else {
            throw TestFailure("Expected examine command with nil object when 'it' has no reference")
        }
    }

    @Test func testContainers() {
        let room = Room(name: "Room", description: "A test room")
        let box = GameObject(name: "wooden box", description: "A simple wooden box.", location: room)
        box.setFlag(.isContainer)
        box.setFlag(.isOpenable)

        let coin = GameObject(name: "gold coin", description: "A shiny gold coin.", location: box)
        coin.setFlag(.isTakable)

        // Test initial state
        #expect(box.hasFlags(.isContainer, .isOpenable))
        #expect(!box.hasFlag(.isOpen))

        // Test opening
        box.setFlag(.isOpen)
        #expect(box.hasFlag(.isOpen))

        // Test closing
        box.clearFlag(.isOpen)
        #expect(!box.hasFlag(.isOpen))

        // Test visibility of contents - being open and being transparent are separate properties
        #expect(!box.hasFlag(.isTransparent)) // The box is not inherently transparent

        // Create a transparent container (like glass)
        let glass = GameObject(name: "glass jar", description: "A transparent glass jar.", location: room)
        glass.setFlag(.isContainer)
        glass.setFlag(.isOpenable)
        glass.setFlag(.isTransparent) // Explicitly set as transparent

        let marble = GameObject(name: "marble", description: "A small glass marble.", location: glass)

        #expect(glass.hasFlag(.isTransparent)) // Should be visible even when closed
    }

    @Test func testTakingFromContainer() throws {
        let room = Room(name: "Room", description: "A test room")
        let box = GameObject(name: "wooden box", description: "A simple wooden box.", location: room)
        box.setFlag(.isContainer)
        box.setFlag(.isOpenable)
        box.setFlag(.isOpen)  // Start with open box

        let coin = GameObject(name: "gold coin", description: "A shiny gold coin.", location: box)
        coin.setFlag(.isTakable)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)

        let parser = CommandParser(world: world)

        // Test finding the coin in the box
        if case let .take(obj) = parser.parse("take coin") {
            #expect(obj === coin)
        } else {
            throw TestFailure("Expected take command for coin in box")
        }

        // Test with a closed box
        box.clearFlag(.isOpen)

        // When the box is closed and not transparent, the object is not in scope
        // so findObject will return nil, resulting in take(nil)
        if case let .take(obj) = parser.parse("take coin") {
            #expect(obj == nil)
        } else {
            throw TestFailure("Expected take command with nil object for coin in closed box")
        }
    }
}
