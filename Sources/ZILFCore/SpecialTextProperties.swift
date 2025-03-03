import Foundation

/// Keys for stored text properties
public enum SpecialTextKey: String {
    /// Default room description
    case description
    /// Short description for brief mode
    case briefDescription
    /// Initial description (first time seeing)
    case initialDescription
    /// Description when object/room is dark
    case darkDescription
    /// Custom description based on visit count
    case visitDescription
    /// Extra detail text when examining
    case detailText
    /// Text for objects in a container
    case insideText
    /// Text for objects on a surface
    case onText
    /// Additional decoration text
    case decorationText
    /// Text for a closed container
    case closedText
    /// Text for an open container
    case openText
}

/// Extension for handling special text properties like descriptions that can change
/// based on state, visit counts, etc.
extension GameObject {
    /// Set a special text property
    /// - Parameters:
    ///   - text: The text to store
    ///   - forKey: The special text key
    public func setSpecialText(_ text: String, forKey key: SpecialTextKey) {
        setState(text, forKey: "text_\(key.rawValue)")
    }

    /// Get a special text property
    /// - Parameter forKey: The special text key
    /// - Returns: The stored text, or nil if not set
    public func getSpecialText(forKey key: SpecialTextKey) -> String? {
        return getState(forKey: "text_\(key.rawValue)")
    }

    /// Set a description for a specific visit count
    /// - Parameters:
    ///   - text: The description text to use
    ///   - visitCount: The visit count when this description should be used
    public func setDescription(_ text: String, forVisitCount visitCount: Int) {
        setState(text, forKey: "visitDescription_\(visitCount)")
    }

    /// Get the current description based on state and properties
    /// - Parameters:
    ///   - visitCount: Optional visit count, if tracking visits
    ///   - isLit: Whether the current environment is lit
    /// - Returns: The appropriate description
    public func getCurrentDescription(visitCount: Int? = nil, isLit: Bool = true) -> String {
        // Handle darkness first
        if !isLit {
            if let darkDesc = getSpecialText(forKey: .darkDescription) {
                return darkDesc
            }
            return "It's too dark to see."
        }

        // If there's a visit count, check for visit-specific descriptions
        if let visitCount = visitCount {
            if visitCount == 1, let initialDesc = getSpecialText(forKey: .initialDescription) {
                return initialDesc
            }

            if let visitDesc: String = getState(forKey: "visitDescription_\(visitCount)") {
                return visitDesc
            }
        }

        // Then check for a special description stored in properties
        if let specialDesc = getSpecialText(forKey: .description) {
            return specialDesc
        }

        // Otherwise return the default description
        return description
    }

    /// Mark this object as visited and get an appropriate description
    /// - Parameter isLit: Whether the environment is lit
    /// - Returns: The appropriate description
    public func getDescriptionAndIncreaseVisits(isLit: Bool = true) -> String {
        // Get the current visit count or default to 0
        let visitCount: Int = getState(forKey: "visitCount") ?? 0

        // Increment for next time
        setState(visitCount + 1, forKey: "visitCount")

        // Get description based on the count BEFORE incrementing
        return getCurrentDescription(visitCount: visitCount + 1, isLit: isLit)
    }

    /// Get text that describes the contents of this object
    /// - Returns: Text description of contents
    public func getContentsDescription() -> String {
        guard isContainer() else { return "" }

        if !canSeeInside() {
            if let closedText = getSpecialText(forKey: .closedText) {
                return closedText
            }
            return "It's closed."
        }

        if contents.isEmpty {
            return "It's empty."
        }

        let prefix = getSpecialText(forKey: .insideText) ?? "Inside you see:"
        let itemList = contents.map { "  \($0.name)" }.joined(separator: "\n")
        return "\(prefix)\n\(itemList)"
    }
}

/// Extension for Room-specific special text handling
extension Room {
    /// Get the appropriate room description based on lighting, state, and visit count
    /// - Parameters:
    ///   - world: The game world context
    ///   - forceBrief: Whether to use the brief description
    /// - Returns: The appropriate room description
    public func getRoomDescription(in world: GameWorld, forceBrief: Bool = false) -> String {
        // Check if the room is lit
        let isRoomLit = world.isRoomLit(self)

        // Get the current visit count or default to 0
        let visitCount: Int = getState(forKey: "visitCount") ?? 0

        // Increment visit count
        setState(visitCount + 1, forKey: "visitCount")

        // If brief mode is active and not the first visit, use brief description
        let shouldUseBrief = (forceBrief || world.useBriefDescriptions) && visitCount > 0

        if shouldUseBrief {
            if let briefDesc = getSpecialText(forKey: .briefDescription) {
                return briefDesc
            }
        }

        // Get the main description based on lighting and visit count
        return getCurrentDescription(visitCount: visitCount + 1, isLit: isRoomLit)
    }

    /// Get a full description of the room including contents and exits
    /// - Parameter world: The game world context
    /// - Returns: A complete room description
    public func getFullRoomDescription(in world: GameWorld) -> String {
        var result = getRoomDescription(in: world)

        // If the room is dark, don't show contents or exits
        if !world.isRoomLit(self) {
            return result
        }

        // Add descriptions of notable objects
        let visibleObjects = contents.filter { obj in
            // Don't describe the player
            if obj === world.player {
                return false
            }

            // Don't describe containers' contents separately
            if let container = obj.location, container !== self {
                return false
            }

            return true
        }

        if !visibleObjects.isEmpty {
            result += "\n\nYou can see:"
            for obj in visibleObjects {
                result += "\n  \(obj.name)"

                // If it's an open container, show its contents
                if obj.isContainer() && obj.canSeeInside() && !obj.contents.isEmpty {
                    let containedItems = obj.contents.map { "    \($0.name)" }.joined(
                        separator: "\n")
                    result += "\n" + containedItems
                }
            }
        }

        // Add exits
        var exitDirections: [String] = []
        for direction in Direction.allCases {
            if getExit(direction: direction) != nil {
                exitDirections.append(direction.rawValue)
            }
        }

        if !exitDirections.isEmpty {
            result += "\n\nExits: " + exitDirections.joined(separator: ", ")
        } else {
            result += "\n\nThere are no obvious exits."
        }

        return result
    }
}

/// Extension for GameWorld to handle special text in a game context
extension GameWorld {
    /// Whether to use brief room descriptions after first visit
    public var useBriefDescriptions: Bool {
        get { getState(forKey: "useBriefDescriptions") ?? false }
        set { setState(newValue, forKey: "useBriefDescriptions") }
    }

    /// Set to use brief room descriptions
    public func setBriefMode() {
        useBriefDescriptions = true
    }

    /// Set to use verbose room descriptions
    public func setVerboseMode() {
        useBriefDescriptions = false
    }

    /// Toggle between brief and verbose mode
    /// - Returns: The new mode state
    @discardableResult
    public func toggleBriefMode() -> Bool {
        useBriefDescriptions.toggle()
        return useBriefDescriptions
    }

    // Helper method to set state directly in the game world
    private func setState<T>(_ value: T, forKey key: String) {
        // We'll add the state directly to the player, since it's always part of the world
        player.setState(value, forKey: "world_\(key)")
    }

    // Helper method to get state from the game world
    private func getState<T>(forKey key: String) -> T? {
        return player.getState(forKey: "world_\(key)")
    }
}
