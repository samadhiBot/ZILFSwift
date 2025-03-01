//
//  GameEvent.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/26/25.
//

import Foundation

/// Represents a scheduled game event
public class GameEvent {
    /// The function to execute when the event fires
    public let action: () -> Bool

    /// The number of turns remaining until the event fires
    /// A value of -1 means the event repeats every turn
    private(set) var turnsRemaining: Int

    /// Whether this event is currently in the queue
    private(set) var isActive: Bool = true

    /// Descriptive name for debugging
    public let name: String

    /// Priority of the event (higher numbers execute first)
    public let priority: Int

    /// Create a new game event
    /// - Parameters:
    ///   - name: Descriptive name for the event
    ///   - turns: Turns until the event fires, or -1 for recurring
    ///   - priority: Priority of the event (higher numbers execute first)
    ///   - action: The function to execute when the event fires
    public init(name: String, turns: Int, priority: Int = 0, action: @escaping () -> Bool) {
        self.name = name
        self.turnsRemaining = turns
        self.priority = priority
        self.action = action
    }

    /// Deactivate this event (remove it from the queue)
    public func deactivate() {
        isActive = false
    }

    /// Check if the event should fire this turn
    public func shouldFireThisTurn() -> Bool {
        return isActive && (turnsRemaining == 1 || turnsRemaining == -1)
    }

    /// Decrement the turns remaining
    /// - Returns: True if the event has expired and should be removed
    public func decrementTurns() -> Bool {
        guard isActive else { return true }

        if turnsRemaining > 0 {
            turnsRemaining -= 1
            return turnsRemaining == 0
        }
        return false // Don't remove recurring events
    }
}
