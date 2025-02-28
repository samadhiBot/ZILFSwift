//
//  RoomActionPatterns.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 6/1/25.
//

import Foundation

/// A collection of common room action patterns that can be used with rooms
public enum RoomActionPatterns {

    // MARK: - Lighting Patterns

    /// Creates a room that gets its lighting from another source (like a switch or an object)
    /// - Parameters:
    ///   - lightSource: A closure that returns true if light is available
    ///   - enterDarkMessage: Optional message to display when entering a dark room
    ///   - enterLitMessage: Optional message to display when entering a lit room
    ///   - darkDescription: Optional description to use when the room is dark
    /// - Returns: Actions to attach to a room for dynamic lighting
    public static func dynamicLighting(
        lightSource: @escaping () -> Bool,
        enterDarkMessage: String? = "You enter a pitch-black room.",
        enterLitMessage: String? = nil,
        darkDescription: String = "It's pitch black here. You can't see anything."
    ) -> (enterAction: (Room) -> Bool, lookAction: (Room) -> Bool) {
        let enterAction: (Room) -> Bool = { room in
            // Get previous light state
            let wasLit: Bool = room.getState(forKey: "wasLit") ?? false

            // Update the room's lighting state based on the light source
            let isLit = lightSource()
            room.setState(isLit, forKey: "wasLit")

            // If we entered a dark room, show the message
            if !isLit && enterDarkMessage != nil {
                print(enterDarkMessage!)
                return true
            }

            // If we entered a lit room and it was previously dark, show the transition message
            if isLit && !wasLit && enterLitMessage != nil {
                print(enterLitMessage!)
                return true
            }

            return false
        }

        let lookAction: (Room) -> Bool = { room in
            // If the room is dark, we can't see
            if !lightSource() {
                print(darkDescription)
                return true
            }

            // Otherwise, let the standard look action handle it
            return false
        }

        return (enterAction, lookAction)
    }

    /// Creates a room that responds to changing light conditions
    /// - Parameters:
    ///   - world: The game world
    ///   - onLitChange: Closure called when the room becomes lit
    ///   - onDarkChange: Closure called when the room becomes dark
    /// - Returns: A begin turn action that responds to lighting changes
    public static func lightingChangeHandler(
        world: GameWorld,
        onLitChange: @escaping (Room) -> Bool = { _ in return false },
        onDarkChange: @escaping (Room) -> Bool = { _ in return false }
    ) -> (Room) -> Bool {
        let beginTurnAction: (Room) -> Bool = { room in
            var result = false

            // Initialize the room's lighting state if necessary
            if room.getState(forKey: "wasLit") == nil {
                room.setState(world.isRoomLit(room), forKey: "wasLit")
            }

            // Check if lighting changed
            if world.didRoomBecomeLit(room) {
                result = onLitChange(room)
            }

            if world.didRoomBecomeDark(room) {
                result = onDarkChange(room) || result
            }

            return result
        }

        return beginTurnAction
    }

    /// Creates actions for a room with a light switch
    /// - Parameters:
    ///   - switchName: The name of the light switch object
    ///   - initiallyOn: Whether the light is initially on
    ///   - onSound: Optional sound when turning on
    ///   - offSound: Optional sound when turning off
    /// - Returns: Command action for handling light switch commands and a lighting source closure
    public static func lightSwitch(
        switchName: String,
        initiallyOn: Bool = true,
        onSound: String = "Click! The lights turn on.",
        offSound: String = "Click! The lights turn off."
    ) -> (commandAction: (Room, Command) -> Bool, lightSource: () -> Bool) {
        // Store the switch state in a closure variable
        var isSwitchOn = initiallyOn

        // Return the command handler and a closure for checking the light status
        let commandAction: (Room, Command) -> Bool = { _, command in
            switch command {
            case .examine(let obj) where obj.name.lowercased().contains(switchName.lowercased()):
                // Describe the switch
                print("A standard light switch. It's currently \(isSwitchOn ? "on" : "off").")
                return true

            case .unknown(let text) where
                (text.lowercased().contains("turn on \(switchName.lowercased())") ||
                 text.lowercased().contains("switch on \(switchName.lowercased())") ||
                 text.lowercased().contains("flip \(switchName.lowercased()) on")):

                if isSwitchOn {
                    print("The \(switchName) is already on.")
                } else {
                    isSwitchOn = true
                    print(onSound)
                }
                return true

            case .unknown(let text) where
                (text.lowercased().contains("turn off \(switchName.lowercased())") ||
                 text.lowercased().contains("switch off \(switchName.lowercased())") ||
                 text.lowercased().contains("flip \(switchName.lowercased()) off")):

                if !isSwitchOn {
                    print("The \(switchName) is already off.")
                } else {
                    isSwitchOn = false
                    print(offSound)
                }
                return true

            default:
                return false
            }
        }

        // Return both the command action and a closure for checking light status
        return (commandAction, { isSwitchOn })
    }

    // MARK: - Atmospheric Patterns

    /// Creates a room that has random atmospheric messages
    /// - Parameters:
    ///   - messages: Array of possible messages
    ///   - chance: Chance (0.0-1.0) of a message appearing each turn
    /// - Returns: An end turn action that occasionally shows atmospheric messages
    public static func randomAtmosphere(
        messages: [String],
        chance: Double = 0.3
    ) -> (Room) -> Bool {
        return { _ in
            guard !messages.isEmpty, Double.random(in: 0...1) < chance else {
                return false
            }

            let randomIndex = Int.random(in: 0..<messages.count)
            print(messages[randomIndex])
            return true
        }
    }

    // MARK: - State Tracking Patterns

    /// Creates a room that counts visits and can have different descriptions based on visit count
    /// - Parameter descriptionsByVisitCount: Dictionary mapping visit counts to descriptions
    /// - Returns: Actions to track visits and show the appropriate description
    public static func visitCounter(
        descriptionsByVisitCount: [Int: String]
    ) -> (enterAction: (Room) -> Bool, lookAction: (Room) -> Bool) {
        let enterAction: (Room) -> Bool = { room in
            // Get current visit count or default to 0
            let currentCount: Int = room.getState(forKey: "visitCount") ?? 0

            // Increment the count
            room.setState(currentCount + 1, forKey: "visitCount")
            return false
        }

        let lookAction: (Room) -> Bool = { room in
            let visitCount: Int = room.getState(forKey: "visitCount") ?? 1

            // Try to find a description for this specific visit count
            if let description = descriptionsByVisitCount[visitCount] {
                print(description)
                return true
            }

            // Try to find a description for "any other visit count"
            if let fallbackDescription = descriptionsByVisitCount[0] {
                print(fallbackDescription)
                return true
            }

            // No custom description for this visit count
            return false
        }

        return (enterAction, lookAction)
    }

    // MARK: - Command Interception Patterns

    /// Creates a room that reacts to specific commands
    /// - Parameter handlers: Dictionary mapping verb strings to handler closures
    /// - Returns: A begin command action that intercepts specific commands
    public static func commandInterceptor(
        handlers: [String: (Command) -> Bool]
    ) -> (Room, Command) -> Bool {
        return { _, command in
            // Get the verb as a string
            let verb: String
            switch command {
            case .take: verb = "take"
            case .drop: verb = "drop"
            case .examine: verb = "examine"
            case .inventory: verb = "inventory"
            case .look: verb = "look"
            case .move: verb = "move"
            case .open: verb = "open"
            case .close: verb = "close"
            case .quit: verb = "quit"
            case .unknown: verb = "unknown"
            }

            // Check if we have a handler for this verb
            if let handler = handlers[verb] {
                return handler(command)
            }

            // No handler for this command
            return false
        }
    }

    // MARK: - Time-Based Patterns

    /// Creates a room where events happen at specific turns
    /// - Parameter schedule: Dictionary mapping turn numbers to event closures
    /// - Returns: An end turn action that fires events according to schedule
    public static func scheduledEvents(
        schedule: [Int: () -> Bool]
    ) -> (Room) -> Bool {
        return { room in
            // Get the current turn count for this room
            let turnCount: Int = room.getState(forKey: "turnCount") ?? 0

            // Increment for next time
            room.setState(turnCount + 1, forKey: "turnCount")

            // Check if we have an event for this turn
            if let event = schedule[turnCount] {
                return event()
            }

            // No scheduled event this turn
            return false
        }
    }
}
