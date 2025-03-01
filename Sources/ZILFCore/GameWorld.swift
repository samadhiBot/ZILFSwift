// GameWorld contains all game objects and state
public class GameWorld {
    public var rooms: [Room] = []
    public var objects: [GameObject] = []
    public var globalObjects: [GameObject] = []
    public var player: Player
    public var lastMentionedObject: GameObject?
    public let eventManager = EventManager()

    public init(player: Player) {
        self.player = player
    }

    public func registerRoom(_ room: Room) {
        rooms.append(room)
    }

    public func registerObject(_ object: GameObject) {
        objects.append(object)
    }

    /// Schedule an event to run after a number of turns
    public func queueEvent(name: String, turns: Int, action: @escaping () -> Bool) {
        eventManager.scheduleEvent(name: name, turns: turns, action: action)
    }

    /// Cancel a scheduled event
    public func dequeueEvent(named name: String) -> Bool {
        return eventManager.dequeueEvent(named: name)
    }

    /// Check if an event is scheduled for this turn
    public func isEventRunning(named name: String) -> Bool {
        return eventManager.isEventRunningThisTurn(named: name)
    }

    /// Checks if an event is in the queue at all (this turn or future turns)
    public func isEventScheduled(named name: String) -> Bool {
        // Use the direct method from EventManager instead of parsing event strings
        return eventManager.isEventScheduled(named: name)
    }

    /// Waits for a specified number of turns or until an event or room action produces output
    /// This is similar to the WAIT-TURNS routine in ZIL
    /// - Parameter turns: The number of turns to wait
    /// - Returns: True if the wait was interrupted by something producing output
    public func waitTurns(_ turns: Int) -> Bool {
        var turnCount = 0
        var outputProduced = false

        while turnCount < turns && !outputProduced {
            // Process room end-of-turn action first
            if let room = player.currentRoom {
                let roomOutput = room.executeEndTurnAction()
                outputProduced = roomOutput
            }

            // Process events for this turn if no output was produced by the room
            if !outputProduced {
                let eventsOutput = eventManager.processEvents()
                outputProduced = eventsOutput
            }

            turnCount += 1
        }

        return outputProduced
    }
}
