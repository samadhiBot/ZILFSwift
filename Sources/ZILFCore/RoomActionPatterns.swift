import Foundation

/// A collection of common room action patterns that can be reused throughout the game.
///
/// This enum provides factory methods that create standardized room behaviors,
/// allowing for consistent implementation of common game mechanics without
/// duplicating code.
public enum RoomActionPatterns {

    // MARK: - Command Interception Patterns

    /// Creates a room that reacts to specific commands.
    ///
    /// This pattern allows rooms to provide custom handling for specific verbs.
    ///
    /// - Parameter handlers: Dictionary mapping verb strings to handler closures.
    /// - Returns: A begin command action that intercepts specific commands.
    public static func commandInterceptor(
        handlers: [String: (Command) -> Bool]
    ) -> (Room, Command) -> Bool {
        return { _, command in
            // Get the verb as a string
            let verb: String
            switch command {
            case .take: verb = "take"
            case .drop: verb = "drop"
            case .examine: verb = "examine"
            case .inventory: verb = "inventory"
            case .look: verb = "look"
            case .move: verb = "move"
            case .open: verb = "open"
            case .close: verb = "close"
            case .quit: verb = "quit"
            case .unknown: verb = "unknown"
            case .custom(let words) where !words.isEmpty:
                verb = words[0]
            case .custom:
                verb = "custom"
            default:
                // Extract the verb name from the enum case
                let mirror = Mirror(reflecting: command)
                verb = String(describing: mirror.subjectType)
                    .components(separatedBy: ".")
                    .last ?? "unknown"
            }

            // Check if we have a handler for this verb
            if let handler = handlers[verb] {
                return handler(command)
            }

            // No handler for this command
            return false
        }
    }

    // MARK: - Lighting Patterns

    /// Creates a room that gets its lighting from another source (like a switch or an object).
    ///
    /// This pattern allows for rooms with dynamic lighting that changes based on
    /// external conditions.
    ///
    /// - Parameters:
    ///   - lightSource: A closure that returns `true` if light is available.
    ///   - enterDarkMessage: Optional message to display when entering a dark room.
    ///   - enterLitMessage: Optional message to display when entering a lit room.
    ///   - darkDescription: Description to use when the room is dark.
    /// - Returns: Actions to attach to a room for dynamic lighting.
    public static func dynamicLighting(
        lightSource: @escaping () -> Bool,
        enterDarkMessage: String? = "You enter a pitch-black room.",
        enterLitMessage: String? = nil,
        darkDescription: String = "It's pitch black here. You can't see anything."
    ) -> (enterAction: (Room) -> Bool, lookAction: (Room) -> Bool) {
        let enterAction: (Room) -> Bool = { room in
            // Get previous light state
            let wasLit: Bool = room.getState(forKey: "wasLit") ?? false

            // Update the room's lighting state based on the light source
            let isLit = lightSource()
            room.setState(isLit, forKey: "wasLit")

            // If we entered a dark room, show the message
            if !isLit && enterDarkMessage != nil {
                print(enterDarkMessage!)
                return true
            }

            // If we entered a lit room and it was previously dark, show the transition message
            if isLit && !wasLit && enterLitMessage != nil {
                print(enterLitMessage!)
                return true
            }

            return false
        }

        let lookAction: (Room) -> Bool = { room in
            // If the room is dark, we can't see
            if !lightSource() {
                print(darkDescription)
                return true
            }

            // Otherwise, let the standard look action handle it
            return false
        }

        return (enterAction, lookAction)
    }

    /// Creates a room that responds to changing light conditions.
    ///
    /// This pattern allows handling the transition between lit and dark states,
    /// such as playing sound effects or triggering events.
    ///
    /// - Parameters:
    ///   - world: The game world.
    ///   - onLitChange: Closure called when the room becomes lit.
    ///   - onDarkChange: Closure called when the room becomes dark.
    /// - Returns: A begin turn action that responds to lighting changes.
    public static func lightingChangeHandler(
        world: GameWorld,
        onLitChange: @escaping (Room) -> Bool = { _ in return false },
        onDarkChange: @escaping (Room) -> Bool = { _ in return false }
    ) -> (Room) -> Bool {
        let beginTurnAction: (Room) -> Bool = { room in
            var result = false

            // Initialize the room's lighting state if necessary
            if room.getState(forKey: "wasLit") == nil {
                room.setState(world.isRoomLit(room), forKey: "wasLit")
            }

            // Check if lighting changed
            if world.didRoomBecomeLit(room) {
                result = onLitChange(room)
            }

            if world.didRoomBecomeDark(room) {
                result = onDarkChange(room) || result
            }

            return result
        }

        return beginTurnAction
    }

    /// Creates actions for a room with a light switch.
    ///
    /// This pattern implements a standard light switch that can be turned on and off
    /// through player commands.
    ///
    /// - Parameters:
    ///   - switchName: The name of the light switch object.
    ///   - initiallyOn: Whether the light is initially on.
    ///   - onSound: Sound message when turning on.
    ///   - offSound: Sound message when turning off.
    /// - Returns: Command action for handling light switch commands and a lighting source closure.
    public static func lightSwitch(
        switchName: String,
        initiallyOn: Bool = true,
        onSound: String = "Click! The lights turn on.",
        offSound: String = "Click! The lights turn off."
    ) -> (commandAction: (Room, Command) -> Bool, lightSource: () -> Bool) {
        // Store the switch state in a closure variable
        var isSwitchOn = initiallyOn

        // Return the command handler and a closure for checking the light status
        let commandAction: (Room, Command) -> Bool = { _, command in
            switch command {
            case .examine:
                // Check if this is examining the switch (need to get object from command context)
                // This is a simplified version - in a real implementation, we would
                // need to get the object from the command context
                print("A standard light switch. It's currently \(isSwitchOn ? "on" : "off").")
                return true

            case .turnOn, .flip:
                // Handle turning on the switch
                if isSwitchOn {
                    print("The \(switchName) is already on.")
                } else {
                    isSwitchOn = true
                    print(onSound)
                }
                return true

            case .turnOff:
                // Handle turning off the switch
                if !isSwitchOn {
                    print("The \(switchName) is already off.")
                } else {
                    isSwitchOn = false
                    print(offSound)
                }
                return true

            case .unknown(let text):
                // Handle text commands for switch operation
                if text.lowercased().contains("turn on \(switchName.lowercased())") ||
                   text.lowercased().contains("switch on \(switchName.lowercased())") ||
                   text.lowercased().contains("flip \(switchName.lowercased()) on") {

                    if isSwitchOn {
                        print("The \(switchName) is already on.")
                    } else {
                        isSwitchOn = true
                        print(onSound)
                    }
                    return true
                }

                if text.lowercased().contains("turn off \(switchName.lowercased())") ||
                   text.lowercased().contains("switch off \(switchName.lowercased())") ||
                   text.lowercased().contains("flip \(switchName.lowercased()) off") {

                    if !isSwitchOn {
                        print("The \(switchName) is already off.")
                    } else {
                        isSwitchOn = false
                        print(offSound)
                    }
                    return true
                }

                // Not a recognized command
                return false

            case .custom(let words):
                // Handle custom commands related to the switch
                if words.count >= 2 {
                    // Check for commands like "turn on switch" or "flip switch"
                    if (words[0] == "turn" && words[1] == "on" && words.count >= 3 && words[2].contains(switchName)) ||
                       (words[0] == "flip" && words.contains(where: { $0.contains(switchName) })) {

                        if isSwitchOn {
                            print("The \(switchName) is already on.")
                        } else {
                            isSwitchOn = true
                            print(onSound)
                        }
                        return true
                    }

                    // Check for "turn off switch"
                    if words[0] == "turn" && words[1] == "off" && words.count >= 3 && words[2].contains(switchName) {
                        if !isSwitchOn {
                            print("The \(switchName) is already off.")
                        } else {
                            isSwitchOn = false
                            print(offSound)
                        }
                        return true
                    }
                }

                return false

            default:
                return false
            }
        }

        // Return both the command action and a closure for checking light status
        return (commandAction, { isSwitchOn })
    }

    // MARK: - Atmospheric Patterns

    /// Creates a room that has random atmospheric messages.
    ///
    /// This pattern adds ambient flavor text that appears occasionally to make
    /// the environment feel more dynamic.
    ///
    /// - Parameters:
    ///   - messages: Array of possible messages.
    ///   - chance: Chance (0.0-1.0) of a message appearing each turn.
    /// - Returns: An end turn action that occasionally shows atmospheric messages.
    public static func randomAtmosphere(
        messages: [String],
        chance: Double = 0.3
    ) -> (Room) -> Bool {
        return { _ in
            guard !messages.isEmpty, Double.random(in: 0...1) < chance else {
                return false
            }

            let randomIndex = Int.random(in: 0..<messages.count)
            print(messages[randomIndex])
            return true
        }
    }

    // MARK: - State Tracking Patterns

    /// Creates a room that counts visits and can have different descriptions based on visit count.
    ///
    /// This pattern allows rooms to change their description based on how many times
    /// the player has visited, enabling progressive narrative reveals.
    ///
    /// - Parameter descriptionsByVisitCount: Dictionary mapping visit counts to descriptions.
    ///   Use `0` as a key for the default description.
    /// - Returns: Actions to track visits and show the appropriate description.
    public static func visitCounter(
        descriptionsByVisitCount: [Int: String]
    ) -> (enterAction: (Room) -> Bool, lookAction: (Room) -> Bool) {
        let enterAction: (Room) -> Bool = { room in
            // Get current visit count or default to 0
            let currentCount: Int = room.getState(forKey: "visitCount") ?? 0

            // Increment the count
            room.setState(currentCount + 1, forKey: "visitCount")
            return false
        }

        let lookAction: (Room) -> Bool = { room in
            let visitCount: Int = room.getState(forKey: "visitCount") ?? 1

            // Try to find a description for this specific visit count
            if let description = descriptionsByVisitCount[visitCount] {
                print(description)
                return true
            }

            // Try to find a description for "any other visit count"
            if let fallbackDescription = descriptionsByVisitCount[0] {
                print(fallbackDescription)
                return true
            }

            // No custom description for this visit count
            return false
        }

        return (enterAction, lookAction)
    }

    // MARK: - Time-Based Patterns

    /// Creates a room where events happen at specific turns.
    ///
    /// This pattern allows scheduling room events to occur after a specific
    /// number of turns the player has spent in the room.
    ///
    /// - Parameter schedule: Dictionary mapping turn numbers to event closures.
    /// - Returns: An end turn action that fires events according to schedule.
    public static func scheduledEvents(
        schedule: [Int: () -> Bool]
    ) -> (Room) -> Bool {
        return { room in
            // Get the current turn count for this room
            let turnCount: Int = room.getState(forKey: "turnCount") ?? 0

            // Increment for next time
            room.setState(turnCount + 1, forKey: "turnCount")

            // Check if we have an event for this turn
            if let event = schedule[turnCount] {
                return event()
            }

            // No scheduled event this turn
            return false
        }
    }
}
