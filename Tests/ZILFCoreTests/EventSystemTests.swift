//
//  EventSystemTests.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/26/25.
//

import Testing
@testable import ZILFCore

struct EventSystemTests {
    @Test func testSchedulingEvents() {
        let eventManager = EventManager()
        var eventFired = false

        let event = eventManager.scheduleEvent(name: "test-event", turns: 3) {
            eventFired = true
            return true
        }

        #expect(event.isActive)
        #expect(!eventManager.isEventRunningThisTurn(named: "test-event"))

        // First turn
        eventManager.processEvents()
        #expect(!eventFired)

        // Second turn
        eventManager.processEvents()
        #expect(!eventFired)

        // Third turn - event should fire
        let produced = eventManager.processEvents()
        #expect(eventFired)
        #expect(produced) // Should return true because event returned true
    }

    @Test func testRecurringEvents() {
        let eventManager = EventManager()
        var fireCount = 0

        eventManager.scheduleEvent(name: "recurring", turns: -1) {
            fireCount += 1
            return true
        }

        #expect(eventManager.isEventRunningThisTurn(named: "recurring"))

        // Process 5 turns
        for _ in 1...5 {
            eventManager.processEvents()
        }

        #expect(fireCount == 5)
        #expect(eventManager.isEventRunningThisTurn(named: "recurring"))
    }

    @Test func testDequeuingEvents() {
        let eventManager = EventManager()
        var eventFired = false

        eventManager.scheduleEvent(name: "to-cancel", turns: 3) {
            eventFired = true
            return true
        }

        // Cancel after first turn
        eventManager.processEvents()
        let dequeued = eventManager.dequeueEvent(named: "to-cancel")
        #expect(dequeued)

        // Run remaining turns
        eventManager.processEvents()
        eventManager.processEvents()

        #expect(!eventFired) // Event should have been cancelled
    }

    @Test func testGameWorldEvents() {
        let startRoom = Room(name: "Start", description: "Starting room")
        let player = Player(startingRoom: startRoom)
        let world = GameWorld(player: player)

        var event1Fired = false
        var event2Count = 0

        world.queueEvent(name: "one-time", turns: 2) {
            event1Fired = true
            return true
        }

        world.queueEvent(name: "recurring", turns: -1) {
            event2Count += 1
            return false // Testing events that don't produce output
        }

        #expect(world.isEventRunning(named: "recurring"))
        #expect(!world.isEventRunning(named: "one-time"))

        world.eventManager.processEvents() // Turn 1
        #expect(!event1Fired)
        #expect(event2Count == 1)

        world.eventManager.processEvents() // Turn 2
        #expect(event1Fired)
        #expect(event2Count == 2)

        world.dequeueEvent(named: "recurring")
        world.eventManager.processEvents() // Turn 3
        #expect(event2Count == 2) // Should not have incremented
    }

    @Test func testRoomActionPhases() {
        let startRoom = Room(name: "Start", description: "Starting room")
        let northRoom = Room(name: "North", description: "Northern room")

        startRoom.setExit(direction: .north, room: northRoom)
        northRoom.setExit(direction: .south, room: startRoom)

        var enterCalled = false
        var endTurnCalled = false

        northRoom.enterAction = { room in
            enterCalled = true
        }

        northRoom.endTurnAction = { room in
            endTurnCalled = true
        }

        let player = Player(startingRoom: startRoom)

        // Test enter action
        player.move(direction: .north)
        #expect(enterCalled)

        // Create world and manually call the end turn action (simulating what GameEngine does)
        let world = GameWorld(player: player)

        // Manually trigger the end turn action first
        if let room = world.player.currentRoom, let action = room.endTurnAction {
            action(room)
        }

        // Then process events
        world.eventManager.processEvents()

        #expect(endTurnCalled)
    }
}
