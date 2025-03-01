// Add a helper method to find the player by traversing up the object graph
public func findPlayer() -> Player? {
    // Check if this object's location is a room
    if let room = location as? Room {
        // Try to find the player in this room
        return room.contents.first { $0 is Player } as? Player
    }

    // If this object is in another container, traverse up
    if let container = location {
        return container.findPlayer()
    }

    // Could not find player
    return nil
}
