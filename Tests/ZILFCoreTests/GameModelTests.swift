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

        #expect(room1.getExit(direction: .north) == room2)
        #expect(room2.getExit(direction: .south) == room1)
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

        #expect(!obj.hasFlag("takeable"))
        obj.setFlag("takeable")
        #expect(obj.hasFlag("takeable"))
        obj.clearFlag("takeable")
        #expect(!obj.hasFlag("takeable"))
    }

    @Test func testItReference() throws {
        let room = Room(name: "Room", description: "A test room")
        let obj1 = GameObject(name: "red ball", description: "A red ball", location: room)
        obj1.setFlag("takeable")
        let obj2 = GameObject(name: "blue book", description: "A blue book", location: room)
        obj2.setFlag("takeable")

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)

        world.lastMentionedObject = obj1

        let parser = CommandParser(world: world)

        // Test examining "it"
        if case let .examine(obj) = parser.parse("examine it") {
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
        if case let .examine(obj) = parser.parse("examine it") {
            #expect(obj === obj2)
        } else {
            throw TestFailure("Expected examine command for 'it'")
        }

        // Test when "it" refers to nothing
        world.lastMentionedObject = nil
        if case let .unknown(message) = parser.parse("examine it") {
            #expect(message.contains("I don't know what 'it' refers to"))
        } else {
            throw TestFailure("Expected unknown command for 'it' with no reference")
        }
    }

    @Test func testContainers() {
        let room = Room(name: "Room", description: "A test room")
        let box = GameObject(name: "wooden box", description: "A simple wooden box.", location: room)
        box.setFlag("container")
        box.setFlag("openable")

        let coin = GameObject(name: "gold coin", description: "A shiny gold coin.", location: box)
        coin.setFlag("takeable")

        // Test initial state
        #expect(box.isContainer())
        #expect(box.isOpenable())
        #expect(!box.isOpen())

        // Test opening
        let openResult = box.open()
        #expect(openResult)
        #expect(box.isOpen())

        // Test closing
        let closeResult = box.close()
        #expect(closeResult)
        #expect(!box.isOpen())

        // Test visibility of contents
        #expect(!box.canSeeInside())
        box.open()
        #expect(box.canSeeInside())

        // Test with transparent container
        let glass = GameObject(name: "glass jar", description: "A transparent glass jar.", location: room)
        glass.setFlag("container")
        glass.setFlag("openable")
        glass.setFlag("transparent")

        let marble = GameObject(name: "marble", description: "A small glass marble.", location: glass)

        #expect(glass.canSeeInside()) // Should be visible even when closed
    }

    @Test func testTakingFromContainer() throws {
        let room = Room(name: "Room", description: "A test room")
        let box = GameObject(name: "wooden box", description: "A simple wooden box.", location: room)
        box.setFlag("container")
        box.setFlag("openable")
        box.setFlag("open")  // Start with open box

        let coin = GameObject(name: "gold coin", description: "A shiny gold coin.", location: box)
        coin.setFlag("takeable")

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
        box.clearFlag("open")

        if case let .unknown(message) = parser.parse("take coin") {
            #expect(message.contains("I don't see"))
        } else {
            throw TestFailure("Expected unknown command for coin in closed box")
        }
    }
}
