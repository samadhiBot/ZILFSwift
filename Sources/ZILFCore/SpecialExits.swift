//
//  SpecialExits.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 6/25/25.
//

import Foundation

/// Represents a special exit with custom conditions and behaviors
public class SpecialExit {
    /// The destination room this exit leads to
    public let destination: Room

    /// Reference to the game world (for condition evaluation)
    private weak var world: GameWorld?

    /// The condition that must be met for the exit to be available
    public let condition: (GameWorld?) -> Bool

    /// An optional message to display when the exit is successfully used
    public let successMessage: String?

    /// An optional message to display when the exit cannot be used
    public let failureMessage: String?

    /// Whether this exit should be visible in room descriptions
    public let isVisible: Bool

    /// Optional code to run when the exit is used successfully
    public let onTraverse: ((GameWorld?) -> Void)?

    /// Initialize a new special exit
    /// - Parameters:
    ///   - destination: The room this exit leads to
    ///   - world: Reference to the game world
    ///   - condition: Condition that must be true for the exit to be available
    ///   - isVisible: Whether this exit is shown in room descriptions
    ///   - successMessage: Message shown when successfully used
    ///   - failureMessage: Message shown when attempted but not available
    ///   - onTraverse: Code to run when the exit is successfully used
    public init(
        destination: Room,
        world: GameWorld? = nil,
        condition: @escaping (GameWorld?) -> Bool = { _ in true },
        isVisible: Bool = true,
        successMessage: String? = nil,
        failureMessage: String? = nil,
        onTraverse: ((GameWorld?) -> Void)? = nil
    ) {
        self.destination = destination
        self.world = world
        self.condition = condition
        self.isVisible = isVisible
        self.successMessage = successMessage
        self.failureMessage = failureMessage
        self.onTraverse = onTraverse
    }

    /// Set the world reference
    /// - Parameter world: The game world
    public func setWorld(_ world: GameWorld) {
        self.world = world
    }

    /// Check if the exit condition is met
    /// - Returns: True if the condition passes
    public func checkCondition() -> Bool {
        return condition(world)
    }

    /// Execute the onTraverse action
    public func executeTraverse() {
        onTraverse?(world)
    }
}

/// Extension to Room for creating common types of special exits
public extension Room {
    /// Add a special exit in the given direction
    /// - Parameters:
    ///   - direction: Direction of the exit
    ///   - specialExit: The special exit to add
    ///   - world: The game world
    func setSpecialExit(direction: Direction, specialExit: SpecialExit, world: GameWorld) {
        specialExit.setWorld(world)
        setState(specialExit, forKey: "specialExit_\(direction.rawValue)")
    }

    /// Get a special exit in the specified direction, if one exists
    /// - Parameter direction: Direction of the exit
    /// - Returns: The special exit, or nil if no special exit exists in that direction
    func getSpecialExit(direction: Direction) -> SpecialExit? {
        return getState(forKey: "specialExit_\(direction.rawValue)")
    }

    /// Check if a special exit is available in the given direction
    /// - Parameter direction: Direction to check
    /// - Returns: True if a special exit exists and its condition passes
    func isSpecialExitAvailable(direction: Direction) -> Bool {
        guard let specialExit = getSpecialExit(direction: direction) else {
            return false
        }
        return specialExit.checkCondition()
    }

    /// Create a hidden exit that's only visible when a condition is met
    /// - Parameters:
    ///   - direction: Direction of the exit
    ///   - destination: Room this exit leads to
    ///   - world: The game world
    ///   - condition: When the exit is available
    ///   - revealMessage: Message when the exit is revealed
    func setHiddenExit(
        direction: Direction,
        destination: Room,
        world: GameWorld,
        condition: @escaping (GameWorld?) -> Bool = { _ in true },
        revealMessage: String? = nil
    ) {
        let specialExit = SpecialExit(
            destination: destination,
            world: world,
            condition: condition,
            isVisible: false,
            successMessage: revealMessage
        )
        setSpecialExit(direction: direction, specialExit: specialExit, world: world)
    }

    /// Create a locked exit that requires an object (key) to pass
    /// - Parameters:
    ///   - direction: Direction of the exit
    ///   - destination: Room this exit leads to
    ///   - world: The game world
    ///   - key: The object that unlocks this exit
    ///   - lockedMessage: Message shown when trying to use while locked
    ///   - unlockedMessage: Message shown when successfully unlocking
    func setLockedExit(
        direction: Direction,
        destination: Room,
        world: GameWorld,
        key: GameObject,
        lockedMessage: String = "That way seems to be locked.",
        unlockedMessage: String = "You unlock the passage with the key."
    ) {
        let condition: (GameWorld?) -> Bool = { world in
            guard let world = world else { return false }
            // Check if player has the key
            return world.player.contents.contains { $0 === key }
        }

        let specialExit = SpecialExit(
            destination: destination,
            world: world,
            condition: condition,
            isVisible: true,
            successMessage: unlockedMessage,
            failureMessage: lockedMessage
        )
        setSpecialExit(direction: direction, specialExit: specialExit, world: world)
    }

    /// Create a one-way exit (no automatic return exit is created)
    /// - Parameters:
    ///   - direction: Direction of the exit
    ///   - destination: Room this exit leads to
    ///   - world: The game world
    ///   - message: Optional message when using this exit
    func setOneWayExit(
        direction: Direction,
        destination: Room,
        world: GameWorld,
        message: String? = nil
    ) {
        let specialExit = SpecialExit(
            destination: destination,
            world: world,
            successMessage: message
        )
        setSpecialExit(direction: direction, specialExit: specialExit, world: world)
    }

    /// Create a scripted exit that runs custom code when traversed
    /// - Parameters:
    ///   - direction: Direction of the exit
    ///   - destination: Room this exit leads to
    ///   - world: The game world
    ///   - script: Code to run when the exit is used
    func setScriptedExit(
        direction: Direction,
        destination: Room,
        world: GameWorld,
        script: @escaping (GameWorld?) -> Void
    ) {
        let specialExit = SpecialExit(
            destination: destination,
            world: world,
            onTraverse: script
        )
        setSpecialExit(direction: direction, specialExit: specialExit, world: world)
    }

    /// Create a conditional exit that's only available when a condition is met
    /// - Parameters:
    ///   - direction: Direction of the exit
    ///   - destination: Room this exit leads to
    ///   - world: The game world
    ///   - condition: When the exit is available
    ///   - failureMessage: Message shown when exit cannot be used
    func setConditionalExit(
        direction: Direction,
        destination: Room,
        world: GameWorld,
        condition: @escaping (GameWorld?) -> Bool,
        failureMessage: String = "You can't go that way right now."
    ) {
        let specialExit = SpecialExit(
            destination: destination,
            world: world,
            condition: condition,
            failureMessage: failureMessage
        )
        setSpecialExit(direction: direction, specialExit: specialExit, world: world)
    }

    /// Create a deadly exit that triggers game over when used
    /// - Parameters:
    ///   - direction: The direction of the exit
    ///   - deathMessage: The message to display when the player uses this exit
    ///   - world: The game world
    ///   - condition: Optional condition that must be true for the exit to be deadly
    func setDeadlyExit(
        direction: Direction,
        deathMessage: String,
        world: GameWorld,
        condition: ((Room) -> Bool)? = nil
    ) {
        // Create a special exit action
        let exitAction: (GameWorld?) -> Void = { world in
            // Check the condition if provided
            if let condition = condition, !condition(self) {
                // If condition is false, it's not deadly right now
                return
            }

            // Get the game engine from the player
            if let world = world,
               let engine: GameEngine = world.player.getState(forKey: "engine") {
                // Trigger game over
                engine.playerDied(message: deathMessage)
            } else {
                // If no engine is available, just show the message
                print(deathMessage)
            }
        }

        // Create a room that doesn't matter (player will never reach it)
        let dummyRoom = Room(name: "Game Over", description: "Game over room")

        // Create a special exit instance
        let specialExit = SpecialExit(
            destination: dummyRoom,
            world: world,
            onTraverse: exitAction
        )
        setSpecialExit(direction: direction, specialExit: specialExit, world: world)
    }

    /// Create a victory exit that triggers game win when used
    /// - Parameters:
    ///   - direction: The direction of the exit
    ///   - victoryMessage: The victory message to display
    ///   - world: The game world
    ///   - condition: Optional condition that must be true for the exit to trigger victory
    func setVictoryExit(
        direction: Direction,
        victoryMessage: String,
        world: GameWorld,
        condition: ((Room) -> Bool)? = nil
    ) {
        // Create a special exit action
        let exitAction: (GameWorld?) -> Void = { world in
            // Check the condition if provided
            if let condition = condition, !condition(self) {
                // If condition is false, it's not a victory yet
                return
            }

            // Get the game engine from the player
            if let world = world,
               let engine: GameEngine = world.player.getState(forKey: "engine") {
                // Trigger victory
                engine.playerWon(message: victoryMessage)
            } else {
                // If no engine is available, just show the message
                print(victoryMessage)
            }
        }

        // Create a room that doesn't matter (player will never reach it)
        let dummyRoom = Room(name: "Victory", description: "Victory room")

        // Create a special exit instance
        let specialExit = SpecialExit(
            destination: dummyRoom,
            world: world,
            onTraverse: exitAction
        )
        setSpecialExit(direction: direction, specialExit: specialExit, world: world)
    }
}
