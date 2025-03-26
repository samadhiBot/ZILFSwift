import Foundation

/// Represents a special exit with custom conditions and behaviors
public class SpecialExit {
    /// The destination room this exit leads to
    public let destination: Room

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
    ///   - condition: Condition that must be true for the exit to be available
    ///   - isVisible: Whether this exit is shown in room descriptions
    ///   - successMessage: The message shown when successfully used
    ///   - failureMessage: The message shown when attempted but not available
    ///   - onTraverse: Code to run when the exit is successfully used
    public init(
        destination: Room,
        condition: @escaping (GameWorld?) -> Bool = { _ in true },
        isVisible: Bool = true,
        successMessage: String? = nil,
        failureMessage: String? = nil,
        onTraverse: ((GameWorld?) -> Void)? = nil
    ) {
        self.destination = destination
        self.condition = condition
        self.isVisible = isVisible
        self.successMessage = successMessage
        self.failureMessage = failureMessage
        self.onTraverse = onTraverse
    }

    /// Check if the exit condition is met
    /// - Returns: True if the condition passes
    public func checkCondition(in world: GameWorld?) -> Bool {
        condition(world)
    }

    /// Execute the onTraverse action
    public func executeTraverse(in world: GameWorld?) {
        onTraverse?(world)
    }
}

/// Extension to Room for creating common types of special exits
extension Room {
    /// Add a special exit in the given direction.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - specialExit: The special exit to add.
    public func setSpecialExit(
        _ direction: Direction,
        to specialExit: SpecialExit
    ) {
        setState(specialExit, forKey: "specialExit\(direction.name)")
    }

    /// Get a special exit in the specified direction, if one exists.
    ///
    /// - Parameter direction: The direction of the exit.
    /// - Returns: The special exit, or nil if no special exit exists in that direction.
    public func find(specialExit direction: Direction) -> SpecialExit? {
        getState(forKey: "specialExit\(direction.name)")
    }

    /// Check if a special exit is available in the given direction.
    ///
    /// - Parameter direction: The direction to check.
    /// - Returns: True if a special exit exists and its condition passes.
    public func isSpecialExitAvailable(direction: Direction) -> Bool {
        if let specialExit = find(specialExit: direction) {
            specialExit.condition(world)
        } else {
            false
        }
    }

    /// Create a hidden exit that's only visible when a condition is met.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - destination: The room this exit leads to.
    ///   - condition: When the exit is available.
    ///   - revealMessage: Message when the exit is revealed.
    public func setHiddenExit(
        direction: Direction,
        destination: Room,
        condition: @escaping (GameWorld?) -> Bool = { _ in true },
        revealMessage: String? = nil
    ) {
        let specialExit = SpecialExit(
            destination: destination,
            condition: condition,
            isVisible: false,
            successMessage: revealMessage
        )
        setSpecialExit(direction, to: specialExit)
    }

    /// Create a locked exit that requires an object (key) to pass.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - destination: The room this exit leads to.
    ///   - key: The object that unlocks this exit.
    ///   - lockedMessage: The message shown when trying to use while locked.
    ///   - unlockedMessage: The message shown when successfully unlocking.
    public func setLockedExit(
        direction: Direction,
        destination: Room,
        key: GameObject,
        lockedMessage: String = "That way seems to be locked.",
        unlockedMessage: String = "You unlock the passage with the key."
    ) {
        let condition: (GameWorld?) -> Bool = { world in
            world?.player.inventory.contains(key) ?? false
        }
        let specialExit = SpecialExit(
            destination: destination,
            condition: condition,
            isVisible: true,
            successMessage: unlockedMessage,
            failureMessage: lockedMessage
        )
        setSpecialExit(direction, to: specialExit)
    }

    /// Create a one-way exit.
    ///
    /// No automatic return exit is created.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - destination: The room this exit leads to.
    ///   - message: Optional message when using this exit.
    public func setOneWayExit(
        direction: Direction,
        destination: Room,
        message: String? = nil
    ) {
        let specialExit = SpecialExit(
            destination: destination,
            successMessage: message
        )
        setSpecialExit(direction, to: specialExit)
    }

    /// Create a scripted exit that runs custom code when traversed.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - destination: The room this exit leads to.
    ///   - script: Code to run when the exit is used.
    public func setScriptedExit(
        direction: Direction,
        destination: Room,
        script: @escaping (GameWorld?) -> Void
    ) {
        let specialExit = SpecialExit(
            destination: destination,
            onTraverse: script
        )
        setSpecialExit(direction, to: specialExit)
    }

    /// Create a conditional exit that's only available when a condition is met.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - destination: The room this exit leads to.
    ///   - condition: When the exit is available.
    ///   - failureMessage: The message shown when exit cannot be used.
    public func setConditionalExit(
        direction: Direction,
        destination: Room,
        condition: @escaping (GameWorld?) -> Bool,
        failureMessage: String = "You can't go that way right now."
    ) {
        let specialExit = SpecialExit(
            destination: destination,
            condition: condition,
            failureMessage: failureMessage
        )
        setSpecialExit(direction, to: specialExit)
    }

    /// Create a deadly exit that triggers game over when used.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - deathMessage: The message to display when the player uses this exit.
    ///   - condition: Optional condition that must be true for the exit to be deadly.
    public func setDeadlyExit(
        direction: Direction,
        deathMessage: String,
        condition: ((Room) -> Bool)? = nil
    ) {
        let exitAction: (GameWorld?) -> Void = { world in
            if let condition, !condition(self) {
                return // If condition exists and is false, it's not deadly right now.
            }

            if let engine = world?.player.engine {
                engine.gameOver(with: .defeat(deathMessage))
            } else {
                print(deathMessage)
            }
        }

        let specialExit = SpecialExit(
            destination: Room(
                name: "Game Over",
                description: "Game over room (player never reaches)"
            ),
            onTraverse: exitAction
        )
        setSpecialExit(direction, to: specialExit)
    }

    /// Create a victory exit that triggers game win when used.
    ///
    /// - Parameters:
    ///   - direction: The direction of the exit.
    ///   - victoryMessage: The victory message to display.
    ///   - condition: Optional condition that must be true for the exit to trigger victory.
    public func setVictoryExit(
        direction: Direction,
        victoryMessage: String,
        condition: ((Room) -> Bool)? = nil
    ) {
        let exitAction: (GameWorld?) -> Void = { world in
            if let condition, !condition(self) {
                return // If condition is false, it's not a victory yet.
            }

            if let engine = world?.player.engine {
                engine.gameOver(with: .victory(victoryMessage))
            } else {
                print(victoryMessage)
            }
        }

        let specialExit = SpecialExit(
            destination: Room(
                name: "Victory",
                description: "Victory room (player never reaches)",
                flags: .isNaturallyLit
            ),
            onTraverse: exitAction
        )
        setSpecialExit(direction, to: specialExit)
    }
}
