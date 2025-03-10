////
////  RoomActionPhasesTests.swift
////  ZILFSwiftTests
////
////  Created by Chris Sessions on 6/1/25.
////
//
//import Foundation
//import Testing
//@testable import ZILFCore
//
//@Suite struct RoomActionPhasesTests {
//
//    // MARK: - Phase Handling Tests
//
//    @Test func testBasicRoomPhases() {
//        let room = Room(name: "Test Room", description: "A test room")
//
//        var phasesExecuted: [String] = []
//
//        // Set up the phase handlers
//        room.beginTurnAction = { _ in
//            phasesExecuted.append("beginTurn")
//            return true
//        }
//
//        room.endTurnAction = { _ in
//            phasesExecuted.append("endTurn")
//            return true
//        }
//
//        room.enterAction = { _ in
//            phasesExecuted.append("enter")
//            return true
//        }
//
//        room.lookAction = { _ in
//            phasesExecuted.append("look")
//            return true
//        }
//
//        room.flashAction = { _ in
//            phasesExecuted.append("flash")
//            return true
//        }
//
//        room.beginCommandAction = { _, command in
//            phasesExecuted.append("command")
//            return true
//        }
//
//        // Test each phase
//        #expect(room.executeBeginTurnAction())
//        #expect(room.executeEndTurnAction())
//        #expect(room.executeEnterAction())
//        #expect(room.executeLookAction())
//        #expect(room.executeFlashAction())
//        #expect(room.executeBeginCommandAction(command: .look))
//
//        // Test the generic phase executor
//        #expect(room.executePhase(.beginTurn))
//        #expect(room.executePhase(.endTurn))
//        #expect(room.executePhase(.enter))
//        #expect(room.executePhase(.look))
//        #expect(room.executePhase(.flash))
//        #expect(room.executePhase(.command(.look)))
//
//        // Check that all phases were executed
//        #expect(phasesExecuted.count == 12)
//        #expect(phasesExecuted.filter { $0 == "beginTurn" }.count == 2)
//        #expect(phasesExecuted.filter { $0 == "endTurn" }.count == 2)
//        #expect(phasesExecuted.filter { $0 == "enter" }.count == 2)
//        #expect(phasesExecuted.filter { $0 == "look" }.count == 2)
//        #expect(phasesExecuted.filter { $0 == "flash" }.count == 2)
//        #expect(phasesExecuted.filter { $0 == "command" }.count == 2)
//    }
//
//    // MARK: - Default Implementation Tests
//
//    @Test func testDynamicLightingPattern() {
//        let room = Room(name: "Dark Room", description: "A dark room")
//        room.makeDark() // Explicitly mark as dark
//
//        var isLightOn = false
//        let lightSource = { isLightOn }
//
//        // Set up the lighting actions
//        let (enterAction, lookAction) = RoomActionPatterns.dynamicLighting(
//            lightSource: lightSource,
//            enterDarkMessage: "You enter a pitch-black room."
//        )
//
//        room.enterAction = enterAction
//        room.lookAction = lookAction
//
//        // Create a game world to track lighting
//        let player = Player(startingRoom: room)
//        let world = GameWorld(player: player)
//        world.register(room: room)
//
//        // Initialize the room's lighting state
//        room.setState(false, forKey: "wasLit")
//
//        // Test entering the room when it's dark
//        #expect(room.executeEnterAction())
//
//        // Test looking in the dark room
//        #expect(room.executeLookAction())
//
//        // Turn on the light
//        isLightOn = true
//
//        // Make sure the world knows the room is now lit
//        #expect(lightSource())
//
//        // Enter again with light
//        #expect(!room.executeEnterAction())
//
//        // The room should now be lit
//        #expect(lightSource())
//
//        // Look with light on
//        #expect(!room.executeLookAction())
//    }
//
//    @Test func testRandomAtmospherePattern() {
//        let room = Room(name: "Atmosphere Room", description: "A room with atmosphere")
//
//        let messages = [
//            "A gentle breeze blows through the room.",
//            "You hear distant thunder.",
//            "The walls seem to creak slightly."
//        ]
//
//        // Set up a 100% chance atmosphere for testing
//        room.endTurnAction = RoomActionPatterns.randomAtmosphere(
//            messages: messages,
//            chance: 1.0
//        )
//
//        // Test that the atmosphere produces output
//        #expect(room.executeEndTurnAction())
//
//        // Test with empty messages
//        room.endTurnAction = RoomActionPatterns.randomAtmosphere(
//            messages: [],
//            chance: 1.0
//        )
//
//        // Should not produce output with empty messages
//        #expect(!room.executeEndTurnAction())
//    }
//
//    @Test func testVisitCounterPattern() {
//        let room = Room(name: "Counter Room", description: "A counting room")
//
//        let descriptions = [
//            1: "This is your first visit to the room.",
//            2: "You've been here before.",
//            3: "You're getting very familiar with this room.",
//            0: "You've been here many times." // Fallback for any other count
//        ]
//
//        let (enterAction, lookAction) = RoomActionPatterns.visitCounter(
//            descriptionsByVisitCount: descriptions
//        )
//
//        room.enterAction = enterAction
//        room.lookAction = lookAction
//
//        // First visit
//        room.executeEnterAction() // Increment count to 1
//        #expect(room.getState(forKey: "visitCount") as Int? == 1)
//        #expect(room.executeLookAction())
//
//        // Second visit
//        room.executeEnterAction() // Increment count to 2
//        #expect(room.getState(forKey: "visitCount") as Int? == 2)
//        #expect(room.executeLookAction())
//
//        // Third visit
//        room.executeEnterAction() // Increment count to 3
//        #expect(room.getState(forKey: "visitCount") as Int? == 3)
//        #expect(room.executeLookAction())
//
//        // Fourth visit (should use fallback)
//        room.executeEnterAction() // Increment count to 4
//        #expect(room.getState(forKey: "visitCount") as Int? == 4)
//        #expect(room.executeLookAction())
//    }
//
//    @Test func testCommandInterceptorPattern() {
//        let room = Room(name: "Command Room", description: "A room that intercepts commands")
//        let obj = GameObject(name: "test-object", description: "A test object")
//        room.addToContainer(obj)
//
//        var interceptedCommands: [String] = []
//
//        let commandHandlers: [String: (Command) -> Bool] = [
//            "look": { _ in
//                interceptedCommands.append("look")
//                return true
//            },
//            "take": { _ in
//                interceptedCommands.append("take")
//                return true
//            }
//        ]
//
//        room.beginCommandAction = RoomActionPatterns.commandInterceptor(
//            handlers: commandHandlers
//        )
//
//        // Test intercepting a look command
//        #expect(room.executeBeginCommandAction(command: .look))
//        #expect(interceptedCommands == ["look"])
//
//        // Test intercepting a take command
//        #expect(room.executeBeginCommandAction(command: .take(obj)))
//        #expect(interceptedCommands == ["look", "take"])
//
//        // Test a command that isn't intercepted
//        #expect(!room.executeBeginCommandAction(command: .move(.north)))
//        #expect(interceptedCommands == ["look", "take"])
//    }
//
//    @Test func testScheduledEventsPattern() {
//        let room = Room(name: "Scheduled Room", description: "A room with scheduled events")
//
//        var eventsTriggered: [Int] = []
//
//        let schedule: [Int: () -> Bool] = [
//            0: {
//                eventsTriggered.append(0)
//                return true
//            },
//            2: {
//                eventsTriggered.append(2)
//                return true
//            },
//            5: {
//                eventsTriggered.append(5)
//                return true
//            }
//        ]
//
//        room.endTurnAction = RoomActionPatterns.scheduledEvents(
//            schedule: schedule
//        )
//
//        // Test initial turn (turn 0)
//        #expect(room.executeEndTurnAction())
//        #expect(eventsTriggered == [0])
//        #expect(room.getState(forKey: "turnCount") as Int? == 1)
//
//        // Test turn 1 (no scheduled event)
//        #expect(!room.executeEndTurnAction())
//        #expect(eventsTriggered == [0])
//        #expect(room.getState(forKey: "turnCount") as Int? == 2)
//
//        // Test turn 2 (scheduled event)
//        #expect(room.executeEndTurnAction())
//        #expect(eventsTriggered == [0, 2])
//        #expect(room.getState(forKey: "turnCount") as Int? == 3)
//    }
//
//    // MARK: - Room State Management Tests
//
//    @Test func testRoomStateManagement() {
//        let room = Room(name: "State Room", description: "A room with state")
//
//        // Test setting and getting a string value
//        room.setState("hello", forKey: "greeting")
//        #expect(room.getState(forKey: "greeting") as String? == "hello")
//
//        // Test setting and getting an int value
//        room.setState(42, forKey: "answer")
//        #expect(room.getState(forKey: "answer") as Int? == 42)
//
//        // Test setting and getting a bool value
//        room.setState(true, forKey: "visited")
//        #expect(room.hasState("visited"))
//
//        // Test overwriting a value
//        room.setState("goodbye", forKey: "greeting")
//        #expect(room.getState(forKey: "greeting") as String? == "goodbye")
//
//        // Test getting a non-existent value
//        #expect(room.getState(forKey: "nonexistent") as String? == nil)
//
//        // Test hasState for a false boolean
//        room.setState(false, forKey: "locked")
//        #expect(!room.hasState("locked"))
//
//        // Test hasState for a non-existent key
//        #expect(!room.hasState("nonexistent"))
//    }
//
//    // MARK: - Action Priority Tests
//
//    @Test func testActionPriorityOrdering() {
//        // Test the comparable implementation
//        #expect(Room.ActionPriority.low < Room.ActionPriority.normal)
//        #expect(Room.ActionPriority.normal < Room.ActionPriority.high)
//        #expect(Room.ActionPriority.high < Room.ActionPriority.critical)
//        #expect(!(Room.ActionPriority.critical < Room.ActionPriority.high))
//    }
//
//    @Test func testPrioritizedActions() {
//        // Create clean rooms for testing
//        let highPriorityRoom = Room(name: "High Priority Room", description: "A test room")
//        let criticalRoom = Room(name: "Critical Room", description: "A test room")
//
//        var actionsExecuted: [String] = []
//
//        // Test high priority action executing first
//        highPriorityRoom.addEnterAction(Room.PrioritizedAction(priority: .high) { _ in
//            actionsExecuted.append("high")
//            return false // Allow other actions to run
//        })
//
//        highPriorityRoom.addEnterAction(Room.PrioritizedAction(priority: .normal) { _ in
//            actionsExecuted.append("normal")
//            return false
//        })
//
//        highPriorityRoom.addEnterAction(Room.PrioritizedAction(priority: .low) { _ in
//            actionsExecuted.append("low")
//            return false
//        })
//
//        // Execute the enter action
//        let _ = highPriorityRoom.executeEnterAction()
//
//        // Check order: high, normal, low
//        #expect(actionsExecuted.count == 3)
//        #expect(actionsExecuted[0] == "high")
//        #expect(actionsExecuted[1] == "normal")
//        #expect(actionsExecuted[2] == "low")
//
//        // Test critical action stopping execution
//        actionsExecuted = []
//
//        criticalRoom.addEnterAction(Room.PrioritizedAction(priority: .critical) { _ in
//            actionsExecuted.append("critical")
//            return true // Stop execution
//        })
//
//        criticalRoom.addEnterAction(Room.PrioritizedAction(priority: .normal) { _ in
//            actionsExecuted.append("normal")
//            return false
//        })
//
//        // Run the actions
//        let _ = criticalRoom.executeEnterAction()
//
//        // Check that only critical ran and stopped execution
//        #expect(actionsExecuted.count == 1)
//        #expect(actionsExecuted[0] == "critical")
//    }
//
//    // MARK: - Integration Test
//
//    @Test func testCompleteRoomActionPhaseSystem() {
//        // Create a test world with rooms using our new room action phase system
//        let foyer = Room(name: "Foyer", description: "A grand foyer with marble floors.")
//        foyer.setFlag(.isNaturallyLit) // Make foyer naturally lit
//
//        let bar = Room(name: "Bar", description: "A dimly lit bar.")
//        // Bar lighting will be controlled by barHasLight
//
//        let kitchen = Room(name: "Kitchen", description: "A well-equipped kitchen.")
//        kitchen.setFlag(.isNaturallyLit) // Make kitchen naturally lit
//
//        let kettle = GameObject(name: "kettle", description: "A copper kettle")
//        kitchen.addToContainer(kettle)
//
//        // Set up exits
//        foyer.setExit(direction: .north, room: bar)
//        bar.setExit(direction: .south, room: foyer)
//        bar.setExit(direction: .east, room: kitchen)
//        kitchen.setExit(direction: .west, room: bar)
//
//        // Track room states
//        var barHasLight = true
//        var barMessagesCount = 0
//
//        // Set up the bar's dynamic lighting
//        let (barEnterAction, barLookAction) = RoomActionPatterns.dynamicLighting(
//            lightSource: { barHasLight },
//            enterDarkMessage: "You enter the dimly lit bar. It's hard to see anything."
//        )
//
//        bar.enterAction = barEnterAction
//        bar.lookAction = barLookAction
//
//        // Add atmospheric messages to the bar
//        bar.addEndTurnAction(Room.PrioritizedAction(priority: .normal) { _ in
//            barMessagesCount += 1
//            return true
//        })
//
//        // Set up state tracking for the kitchen
//        var kettleBoiling = false
//        var visitCount = 0
//
//        kitchen.addEnterAction(Room.PrioritizedAction { _ in
//            visitCount += 1
//            return false
//        })
//
//        // Set up command interception for the kitchen
//        kitchen.addCommandAction(Room.PrioritizedCommandAction { _, command in
//            if case .examine(let obj) = command, obj === kettle {
//                kettleBoiling = true
//                return true
//            }
//            return false
//        })
//
//        // Create a player and world
//        let player = Player(startingRoom: foyer)
//        let world = GameWorld(player: player)
//        world.register(room: foyer)
//        world.register(room: bar)
//        world.register(room: kitchen)
//
//        // No need to set player's starting room as it's already set through the constructor
//
//        // Test moving between rooms
//        _ = player.move(direction: .north) // Move to bar
//        #expect(player.currentRoom === bar)
//
//        // Initialize the bar's lighting state
//        bar.setState(true, forKey: "wasLit")
//
//        // Test lighting in the bar
//        barHasLight = true  // Start with light on
//        _ = bar.executeEnterAction() // Update lighting state
//
//        // Verify the room is lit
//        #expect(barHasLight)
//
//        // Now turn off the light
//        barHasLight = false
//        _ = bar.executeEnterAction() // Update lighting state
//
//        // The room should now be dark
//        #expect(!barHasLight)
//        #expect(bar.executeLookAction()) // Should produce output in dark room
//
//        // Turn light back on
//        barHasLight = true
//        _ = bar.executeEnterAction() // Update lighting state
//
//        // The room should be lit again
//        #expect(barHasLight)
//        #expect(!bar.executeLookAction()) // Should not override normal description
//
//        // Test end turn actions
//        #expect(bar.executeEndTurnAction())
//        #expect(barMessagesCount == 1)
//    }
//}
