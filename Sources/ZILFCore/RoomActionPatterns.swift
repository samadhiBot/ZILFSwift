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
    ///   - enterMessage: Optional message to display when entering a dark room
    /// - Returns: Actions to attach to a room for dynamic lighting
    public static func dynamicLighting(
        lightSource: @escaping () -> Bool,
        enterMessage: String? = "It's pitch black. You can't see a thing."
    ) -> (enterAction: (Room) -> Bool, lookAction: (Room) -> Bool) {
        let enterAction: (Room) -> Bool = { room in
            // Update the room's lighting state based on the light source
            room.setState(lightSource(), forKey: "isLit")

            // If we entered a dark room, show the message
            if !room.hasState("isLit"), let message = enterMessage {
                print(message)
                return true
            }
            return false
        }

        let lookAction: (Room) -> Bool = { room in
            // If the room is dark, we can't see
            if !room.hasState("isLit") {
                print("It's pitch black here. You can't see anything.")
                return true
            }

            // Otherwise, let the standard look action handle it
            return false
        }

        return (enterAction, lookAction)
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
