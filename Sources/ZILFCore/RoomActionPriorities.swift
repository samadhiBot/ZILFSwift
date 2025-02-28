//
//  RoomActionPriorities.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 6/1/25.
//

/// Room Action Priorities
///
/// This file extends the Room class to support prioritized action handlers.
/// It allows multiple actions to be registered for each phase, with priority levels
/// determining the order of execution. Higher priority actions execute first, and any
/// action can stop the sequence by returning true.
///
/// ## Example
/// ```swift
/// let room = Room(name: "Kitchen", description: "A well-equipped kitchen.")
///
/// // Add a high priority action that always runs first
/// room.addEnterAction(Room.PrioritizedAction(priority: .high) { room in
///     print("This runs first when entering the kitchen")
///     return false // Let other actions run
/// })
///
/// // Add a normal priority action
/// room.addEnterAction(Room.PrioritizedAction { room in
///     print("This runs after high priority actions")
///     return false
/// })
///
/// // Add a critical action that would stop execution
/// room.addCommandAction(Room.PrioritizedCommandAction(priority: .critical) { room, command in
///     if case .examine(let obj) = command, obj.name == "kettle" {
///         print("This intercepts examining the kettle and prevents other actions")
///         return true // Stop further processing
///     }
///     return false
/// })
/// ```

import Foundation

// MARK: - Room Action Priority Configuration

/// Extended room action functionality with priority support
public extension Room {
    /// Priority level for room actions
    enum ActionPriority: Int, Comparable {
        /// Lowest priority, runs after everything else
        case low = 0
        /// Standard priority, runs in the middle
        case normal = 50
        /// High priority, runs before normal actions
        case high = 100
        /// Highest priority, runs first before all other actions
        case critical = 200

        public static func < (lhs: ActionPriority, rhs: ActionPriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    /// An action with associated priority
    struct PrioritizedAction {
        let priority: ActionPriority
        let action: (Room) -> Bool

        /// Create a new prioritized action
        /// - Parameters:
        ///   - priority: The priority level for this action
        ///   - action: The closure to execute
        public init(priority: ActionPriority = .normal, action: @escaping (Room) -> Bool) {
            self.priority = priority
            self.action = action
        }
    }

    /// A prioritized command action
    struct PrioritizedCommandAction {
        let priority: ActionPriority
        let action: (Room, Command) -> Bool

        /// Create a new prioritized command action
        /// - Parameters:
        ///   - priority: The priority level for this action
        ///   - action: The closure to execute
        public init(priority: ActionPriority = .normal, action: @escaping (Room, Command) -> Bool) {
            self.priority = priority
            self.action = action
        }
    }

    // MARK: - Private Action Storage

    /// Get the array of enter actions
    private var enterActions: [PrioritizedAction] {
        get { getState(forKey: "enterActions") ?? [] }
        set { setState(newValue, forKey: "enterActions") }
    }

    /// Get the array of end turn actions
    private var endTurnActions: [PrioritizedAction] {
        get { getState(forKey: "endTurnActions") ?? [] }
        set { setState(newValue, forKey: "endTurnActions") }
    }

    /// Get the array of begin turn actions
    private var beginTurnActions: [PrioritizedAction] {
        get { getState(forKey: "beginTurnActions") ?? [] }
        set { setState(newValue, forKey: "beginTurnActions") }
    }

    /// Get the array of command actions
    private var commandActions: [PrioritizedCommandAction] {
        get { getState(forKey: "commandActions") ?? [] }
        set { setState(newValue, forKey: "commandActions") }
    }

    // MARK: - Add Actions

    /// Add an enter action with priority
    /// - Parameter action: The prioritized action to add
    ///
    /// This action will be executed when a player enters the room.
    /// Actions are executed in order of priority (highest first). If an action returns true,
    /// no further actions will be executed.
    func addEnterAction(_ action: PrioritizedAction) {
        var actions = enterActions
        actions.append(action)
        enterActions = actions

        // Set up the main enter action to execute our prioritized actions
        enterAction = { [weak self] room in
            guard let self = self else { return false }
            return self.executeActionsByPriority(self.enterActions, for: room)
        }
    }

    /// Add an end turn action with priority
    /// - Parameter action: The prioritized action to add
    ///
    /// This action will be executed at the end of each turn while the player is in the room.
    /// Actions are executed in order of priority (highest first). If an action returns true,
    /// no further actions will be executed.
    func addEndTurnAction(_ action: PrioritizedAction) {
        var actions = endTurnActions
        actions.append(action)
        endTurnActions = actions

        // Set up the main end turn action to execute our prioritized actions
        endTurnAction = { [weak self] room in
            guard let self = self else { return false }
            return self.executeActionsByPriority(self.endTurnActions, for: room)
        }
    }

    /// Add a begin turn action with priority
    /// - Parameter action: The prioritized action to add
    ///
    /// This action will be executed at the beginning of each turn before any command processing.
    /// Actions are executed in order of priority (highest first). If an action returns true,
    /// no further actions will be executed.
    func addBeginTurnAction(_ action: PrioritizedAction) {
        var actions = beginTurnActions
        actions.append(action)
        beginTurnActions = actions

        // Set up the main begin turn action to execute our prioritized actions
        beginTurnAction = { [weak self] room in
            guard let self = self else { return false }
            return self.executeActionsByPriority(self.beginTurnActions, for: room)
        }
    }

    /// Add a command action with priority
    /// - Parameter action: The prioritized command action to add
    ///
    /// This action will be executed when a command is being processed while the player is in the room.
    /// Actions are executed in order of priority (highest first). If an action returns true,
    /// no further actions will be executed and the command is considered handled.
    func addCommandAction(_ action: PrioritizedCommandAction) {
        var actions = commandActions
        actions.append(action)
        commandActions = actions

        // Set up the main command action to execute our prioritized actions
        beginCommandAction = { [weak self] room, command in
            guard let self = self else { return false }
            return self.executeCommandActionsByPriority(self.commandActions, for: room, command: command)
        }
    }

    // MARK: - Private Execution Helpers

    /// Execute actions in priority order until one returns true
    /// - Parameters:
    ///   - actions: The prioritized actions to execute
    ///   - room: The room to pass to the actions
    /// - Returns: True if any action produced output or handled the action
    private func executeActionsByPriority(_ actions: [PrioritizedAction], for room: Room) -> Bool {
        guard !actions.isEmpty else { return false }

        // Sort by priority (highest first)
        let sortedActions = actions.sorted { $0.priority > $1.priority }

        // Execute in priority order until one returns true
        for action in sortedActions {
            if action.action(room) {
                return true
            }
        }

        return false
    }

    /// Execute command actions in priority order until one returns true
    /// - Parameters:
    ///   - actions: The prioritized command actions to execute
    ///   - room: The room to pass to the actions
    ///   - command: The command to process
    /// - Returns: True if any action handled the command
    private func executeCommandActionsByPriority(_ actions: [PrioritizedCommandAction], for room: Room, command: Command) -> Bool {
        guard !actions.isEmpty else { return false }

        // Sort by priority (highest first)
        let sortedActions = actions.sorted { $0.priority > $1.priority }

        // Execute in priority order until one returns true
        for action in sortedActions {
            if action.action(room, command) {
                return true
            }
        }

        return false
    }
}
