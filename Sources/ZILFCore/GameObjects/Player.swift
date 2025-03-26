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
    public init(
        name: String = "Player",
        description: String = "As good-looking as ever.",
        startingRoom: Room
    ) {
        super.init(
            name: name,
            description: description,
            type: .player
        )
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
    
    /// All objects that are visible to the player.
    var objectsInScope: [GameObject] {
        var objectsInScope: [GameObject] = []

        // Add objects in player's inventory
        objectsInScope.append(contentsOf: inventory)

        // Add objects in the current room
        if let currentRoom {
            // Add objects directly in the room
            for obj in currentRoom.contents where obj !== self {
                objectsInScope.append(obj)

                // Add objects in visible containers
                if obj.hasFlags(.isContainer, .isOpen) || obj.hasFlag(.isTransparent) {
                    objectsInScope.append(contentsOf: obj.contents)
                }
            }

            // Add global objects accessible in this room
            if let world {
                for object in world.objects {
                    switch object.type {
                    case .global:
                        objectsInScope.append(object)
                    case .localGlobal(let rooms):
                        if rooms.contains(currentRoom) {
                            objectsInScope.append(object)
                        }
                    default:
                        break
                    }
                }
            }
        }

        return objectsInScope

//        world?.objects.filter {
//            switch $0.type {
//            case .global:
//                true
//            case .localGlobal(let rooms):
//                if let currentRoom { rooms.contains(currentRoom) } else { false }
//            case .object:
//                if let currentRoom { $0.isIn(currentRoom) } else { false }
//            default:
//                false
//            }
//        } ?? [] + inventory
    }
}

extension Player {
    /// Sets the game engine for this player.
    /// - Parameter engine: The game engine to associate with this player.
    func setEngine(_ engine: GameEngine) {
        self.engine = engine
    }
}
