/// Manages scheduled events in the game
public class EventManager {
    /// The queue of scheduled events
    private var eventQueue: [GameEvent] = []

    /// Schedule an event to run after a number of turns
    /// - Parameters:
    ///   - name: Descriptive name for the event
    ///   - turns: Turns until the event fires (use -1 for recurring)
    ///   - priority: Priority of the event (higher numbers execute first)
    ///   - action: The function to execute when the event fires
    /// - Returns: The created event
    @discardableResult
    public func scheduleEvent(name: String, turns: Int, priority: Int = 0, action: @escaping () -> Bool) -> GameEvent {
        let event = GameEvent(name: name, turns: turns, priority: priority, action: action)
        eventQueue.append(event)

        // Re-sort the queue by priority so higher priority events execute first
        eventQueue.sort { $0.priority > $1.priority }

        return event
    }

    /// Dequeue (cancel) a scheduled event by name
    /// - Parameter name: The name of the event to cancel
    /// - Returns: True if an event was dequeued
    public func dequeueEvent(named name: String) -> Bool {
        let found = eventQueue.first { $0.name == name && $0.isActive }
        found?.deactivate()
        return found != nil
    }

    /// Check if an event is scheduled to run on the current turn
    /// - Parameter name: The name of the event to check
    /// - Returns: True if the event is scheduled for this turn
    public func isEventRunningThisTurn(named name: String) -> Bool {
        return eventQueue.contains {
            $0.name == name && $0.isActive && $0.shouldFireThisTurn()
        }
    }

    /// Check if an event with the given name exists in the queue
    /// - Parameter name: The name of the event to check
    /// - Returns: True if an active event with this name exists in the queue
    public func isEventScheduled(named name: String) -> Bool {
        return eventQueue.contains {
            $0.name == name && $0.isActive
        }
    }

    /// Process all events for the current turn
    /// - Returns: True if any event fired and produced output
    public func processEvents() -> Bool {
        var producedOutput = false

        // Sort events by priority before processing them
        let eventsToProcess = eventQueue.filter { $0.shouldFireThisTurn() && $0.isActive }
            .sorted { $0.priority > $1.priority }

        // Fire events that are due this turn in priority order
        for event in eventsToProcess {
            let result = event.action()
            producedOutput = producedOutput || result
        }

        // Then, decrement turn counters and collect events to remove
        let remainingEvents = eventQueue.filter { event in
            // Keep the event if it's inactive (it will be removed) or if it hasn't expired
            !event.isActive || !event.decrementTurns()
        }

        // Replace the event queue
        eventQueue = remainingEvents

        return producedOutput
    }

    /// Remove all events from the queue
    public func clearAllEvents() {
        eventQueue.removeAll()
    }

    /// Get a list of all active events (for debugging)
    public func listActiveEvents() -> [String] {
        return eventQueue
            .filter { $0.isActive }
            .map { "\($0.name) - \($0.turnsRemaining == -1 ? "recurring" : "in \($0.turnsRemaining) turns")" }
    }
}
