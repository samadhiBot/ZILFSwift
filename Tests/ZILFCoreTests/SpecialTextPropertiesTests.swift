//
//  SpecialTextPropertiesTests.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 7/10/25.
//

import Testing
@testable import ZILFCore

struct SpecialTextPropertiesTests {
    @Test func testBasicSpecialTextProperties() {
        let obj = GameObject(name: "test object", description: "Default description")

        // Test default description
        #expect(obj.getCurrentDescription() == "Default description")

        // Test setting a special text property
        obj.setSpecialText("Special description", forKey: .description)
        #expect(obj.getCurrentDescription() == "Special description")

        // Test setting description for a specific visit count
        obj.setDescription("Visit 2 description", forVisitCount: 2)
        #expect(obj.getCurrentDescription(visitCount: 2) == "Visit 2 description")

        // Test initial description
        obj.setSpecialText("First time seeing this", forKey: .initialDescription)
        #expect(obj.getCurrentDescription(visitCount: 1) == "First time seeing this")

        // Test dark description
        obj.setSpecialText("It's very dark", forKey: .darkDescription)
        #expect(obj.getCurrentDescription(isLit: false) == "It's very dark")
    }

    @Test func testVisitCountIncrementing() {
        let obj = GameObject(name: "visit counter", description: "Base description")

        // Set descriptions for different visit counts
        obj.setSpecialText("First visit", forKey: .initialDescription)
        obj.setDescription("Second visit", forVisitCount: 2)
        obj.setDescription("Third visit", forVisitCount: 3)

        // First get description and increment
        #expect(obj.getDescriptionAndIncreaseVisits() == "First visit")

        // Second visit
        #expect(obj.getDescriptionAndIncreaseVisits() == "Second visit")

        // Third visit
        #expect(obj.getDescriptionAndIncreaseVisits() == "Third visit")

        // Fourth visit should fall back to normal description
        #expect(obj.getDescriptionAndIncreaseVisits() == "Base description")
    }

    @Test func testContainerDescriptions() {
        let box = GameObject(name: "box", description: "A simple box.")
        box.setFlag("container")
        box.setFlag("openable")

        // Test closed container description
        box.clearFlag("open")
        #expect(box.getContentsDescription() == "It's closed.")

        // Test custom closed text
        box.setSpecialText("The box is firmly shut.", forKey: .closedText)
        #expect(box.getContentsDescription() == "The box is firmly shut.")

        // Test empty container
        box.setFlag("open")
        #expect(box.getContentsDescription() == "It's empty.")

        // Add some contents
        let coin = GameObject(name: "gold coin", description: "A shiny coin.", location: box)
        let key = GameObject(name: "brass key", description: "A small key.", location: box)

        // Test with contents
        #expect(box.getContentsDescription().contains("Inside you see:"))
        #expect(box.getContentsDescription().contains("gold coin"))
        #expect(box.getContentsDescription().contains("brass key"))

        // Test custom inside text
        box.setSpecialText("The box contains:", forKey: .insideText)
        #expect(box.getContentsDescription().contains("The box contains:"))
        #expect(!box.getContentsDescription().contains("Inside you see:"))
    }

    @Test func testRoomDescriptions() {
        let room = Room(name: "Test Room", description: "A standard room.")
        room.setSpecialText("You see a room with fancy decorations.", forKey: .description)
        room.setSpecialText("Just a room.", forKey: .briefDescription)

        let player = Player(startingRoom: room)
        let world = GameWorld(player: player)
        world.registerRoom(room)

        // Make the room naturally lit
        room.makeNaturallyLit()

        // Test basic description
        #expect(room.getRoomDescription(in: world).contains("You see a room with fancy decorations"))

        // Test brief mode
        world.setBriefMode()
        room.setState(1, forKey: "visitCount") // Second visit
        #expect(room.getRoomDescription(in: world) == "Just a room.")

        // Test verbose mode
        world.setVerboseMode()
        #expect(room.getRoomDescription(in: world).contains("You see a room with fancy decorations"))

        // Test full room description with exits
        let northRoom = Room(name: "North Room", description: "Room to the north")
        room.setExit(direction: .north, room: northRoom)

        let fullDesc = room.getFullRoomDescription(in: world)
        #expect(fullDesc.contains("You see a room with fancy decorations"))
        #expect(fullDesc.contains("Exits: north"))
    }

    @Test func testDarkRoomDescription() {
        let darkRoom = Room(name: "Dark Room", description: "A well-furnished room.")
        darkRoom.makeDark() // Explicitly not naturally lit
        darkRoom.setSpecialText("You can't see anything in the pitch darkness.", forKey: .darkDescription)

        let player = Player(startingRoom: darkRoom)
        let world = GameWorld(player: player)
        world.registerRoom(darkRoom)

        // Without a light source, should be dark
        #expect(darkRoom.getRoomDescription(in: world) == "You can't see anything in the pitch darkness.")

        // With a light source, should see normal description
        let lantern = GameObject(name: "lantern", description: "A brass lantern")
        lantern.makeLightSource(initiallyLit: true)
        darkRoom.contents.append(lantern)

        #expect(darkRoom.getRoomDescription(in: world).contains("A well-furnished room"))
    }

    @Test func testBriefMode() {
        let world = GameWorld(player: Player(startingRoom: Room(name: "Test", description: "Test")))

        // Default should be verbose
        #expect(!world.useBriefDescriptions)

        // Test toggling
        #expect(world.toggleBriefMode() == true)
        #expect(world.useBriefDescriptions)

        // Test direct setting
        world.setVerboseMode()
        #expect(!world.useBriefDescriptions)

        world.setBriefMode()
        #expect(world.useBriefDescriptions)
    }
}
