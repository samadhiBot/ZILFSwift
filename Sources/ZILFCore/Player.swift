//
//  Player.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 3/1/25.
//

// Player representation
public class Player: GameObject {
    // Direct properties for critical components
    // Using implicitly unwrapped optional for engine which is set after initialization
    public private(set) var engine: GameEngine!
    public private(set) var world: GameWorld!

    public init(startingRoom: Room) {
        super.init(name: "player", description: "As good-looking as ever.")
        self.location = startingRoom
        startingRoom.contents.append(self)
    }

    // Called by GameWorld during initialization
    internal func setWorld(_ world: GameWorld) {
        self.world = world
    }

    // Called by GameEngine during initialization
    internal func setEngine(_ engine: GameEngine) {
        self.engine = engine
    }

    public var currentRoom: Room? {
        return location as? Room
    }

    public func move(direction: Direction) -> Bool {
        guard let currentRoom = self.currentRoom else {
            return false
        }

        // First check if there's a special exit in this direction
        if let specialExit = currentRoom.getSpecialExit(direction: direction) {
            // Check if the exit condition passes
            if specialExit.checkCondition() {
                // Display success message if there is one
                if let successMessage = specialExit.successMessage {
                    print(successMessage)
                }

                // Execute onTraverse action if there is one
                specialExit.executeTraverse()

                // Move the player to the destination
                let destination = specialExit.destination

                // Remove from old room
                if let index = currentRoom.contents.firstIndex(where: { $0 === self }) {
                    currentRoom.contents.remove(at: index)
                }

                // Add to new room
                self.location = destination
                destination.contents.append(self)

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
        guard let newRoom = currentRoom.getExit(direction: direction) else {
            return false
        }

        // Remove from old room
        if let index = currentRoom.contents.firstIndex(where: { $0 === self }) {
            currentRoom.contents.remove(at: index)
        }

        // Add to new room
        self.location = newRoom
        newRoom.contents.append(self)

        // Trigger the room's enter action
        newRoom.executeEnterAction()

        return true
    }
}
