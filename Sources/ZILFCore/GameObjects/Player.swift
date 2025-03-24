import Foundation

/// Represents the player character in the game world.
///
/// The `Player` class extends `GameObject` and provides functionality specific
/// to the player character, including movement between rooms and tracking the
/// player's current location.
public class Player: GameObject {
    /// The game engine instance managing this player.
    public private(set) var engine: GameEngine?

    /// Creates a new player instance starting in the specified room.
    /// - Parameter startingRoom: The room where the player begins the game.
    public init(startingRoom: Room) {
        super.init(name: "player", description: "As good-looking as ever.")
        self.moveTo(startingRoom)
    }

    /// The current room the player is located in.
    public var currentRoom: Room? {
        location as? Room
    }

    /// Objects contained within this object (alias for contents).
    public var inventory: [GameObject] {
        contents
    }

    /// Attempts to move the player in the specified direction.
    ///
    /// This method handles both standard exits and special exits with conditions.
    /// It will also trigger any entry actions for the destination room.
    ///
    /// - Parameter direction: The direction to move in.
    /// - Returns: `true` if the movement was successful, `false` otherwise.
    public func move(direction: Direction) -> Bool {
        guard let currentRoom = self.currentRoom else {
            return false
        }

        // First check if there's a special exit in this direction
        if let specialExit = currentRoom.find(specialExit: direction) {
            // Check if the exit condition passes
            if specialExit.checkCondition(in: world) {
                // Display success message if there is one
                if let successMessage = specialExit.successMessage {
                    print(successMessage)
                }

                // Execute onTraverse action if there is one
                specialExit.executeTraverse(in: world)

                // Move the player to the destination
                let destination = specialExit.destination

                // Remove from old room
                currentRoom.remove(self)

                // Use setLocation instead of direct assignment to update location
                // This automatically handles adding to the destination's contents
                moveTo(destination)

                // Trigger the room's enter action
                destination.executeEnterAction()

                return true
            } else {
                // Display failure message if there is one
                if let failureMessage = specialExit.failureMessage {
                    print(failureMessage)
                }
                return false
            }
        }

        // If no special exit, use the regular exit
        guard let newRoom = currentRoom.find(exit: direction) else {
            return false
        }

        // Remove from old room
        currentRoom.remove(self)

        // Use setLocation instead of direct assignment to update location
        // This automatically handles adding to the destination's contents
        moveTo(newRoom)

        // Trigger the room's enter action
        newRoom.executeEnterAction()

        return true
    }

    public var objectsInScope: [GameObject] {
        world?.objects.filter {
            switch $0.type {
            case .global:
                true
            case .localGlobal(let rooms):
                if let currentRoom { rooms.contains(currentRoom) } else { false }
            case .object:
                if let currentRoom { $0.isIn(currentRoom) } else { false }
            default:
                false
            }
        } ?? [] + inventory
    }
}

extension Player {
    /// Sets the game engine for this player.
    /// - Parameter engine: The game engine to associate with this player.
    func setEngine(_ engine: GameEngine) {
        self.engine = engine
    }
}
