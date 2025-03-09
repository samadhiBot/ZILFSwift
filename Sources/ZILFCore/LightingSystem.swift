import Foundation

/// Standard flag keys used throughout the lighting system
extension String {
    /// Flag for objects or rooms that provide light.
    public static let lightSource = "light-source"

    /// Flag for objects that are currently lit/on.
    public static let lit = "lit"

    /// Flag for rooms that are naturally lit (don't require a light source).
    public static let naturallyLit = "naturally-lit"

    /// Flag for transparent objects that light can pass through.
    public static let transparent = "transparent"
}

// MARK: - GameWorld Lighting Extensions

/// Light/darkness mechanics for the game world.
///
/// This extension provides comprehensive lighting functionality, including:
/// - Tracking which rooms and objects provide light
/// - Determining if a room is currently lit
/// - Handling dynamic lighting changes
/// - Providing helper functions similar to ZIL (NOW-LIT?, NOW-DARK?)
extension GameWorld {

    /// Gets all available light sources in a room or carried by the player.
    /// - Parameter room: The room to check for light sources.
    /// - Returns: Array of objects that can function as light sources.
    public func availableLightSources(in room: Room) -> [GameObject] {
        var lightSources: [GameObject] = []

        // Room itself might be a light source
        if room.hasFlag(.isLightSource) {
            lightSources.append(room)
        }

        // Add light sources in the room
        for obj in room.contents where obj.hasFlag(.isLightSource) {
            lightSources.append(obj)
        }

        // Add player's light sources if player is in this room
        if player.currentRoom === room {
            for obj in player.inventory where obj.hasFlag(.isLightSource) {
                lightSources.append(obj)
            }
        }

        return lightSources
    }

    /// Checks if a room just became dark (equivalent to ZIL's NOW-DARK?).
    /// - Parameter room: The room to check.
    /// - Returns: `true` if the room just transitioned from lit to dark.
    public func didRoomBecomeDark(_ room: Room) -> Bool {
        // Get previous light status
        let wasLit: Bool = room.getState(forKey: "wasLit") ?? false

        // Get current light status
        let isLit = isRoomLit(room)

        // Store the current state for next time
        room.setState(isLit, forKey: "wasLit")

        // Return true if it was lit and is now dark
        return wasLit && !isLit
    }

    /// Checks if a room just became lit (equivalent to ZIL's NOW-LIT?).
    /// - Parameter room: The room to check.
    /// - Returns: `true` if the room just transitioned from dark to lit.
    public func didRoomBecomeLit(_ room: Room) -> Bool {
        // Get previous light status
        let wasLit: Bool = room.getState(forKey: "wasLit") ?? false

        // Get current light status
        let isLit = isRoomLit(room)

        // Store the current state for next time
        room.setState(isLit, forKey: "wasLit")

        // Return true if it was dark and is now lit
        return !wasLit && isLit
    }

    /// Checks if a given object is currently providing light.
    /// - Parameter object: The object to check.
    /// - Returns: `true` if the object is a light source and is currently lit.
    public func isProvidingLight(_ object: GameObject) -> Bool {
        return object.hasFlag(.isLightSource) && object.hasFlag(.isOn)
    }

    /// Determines if a room is currently lit by any light source.
    /// - Parameter room: The room to check.
    /// - Returns: `true` if the room has any source of light.
    public func isRoomLit(_ room: Room) -> Bool {
        // 1. If the room is naturally lit, it's always lit
        if room.hasFlag(.isNaturallyLit) {
            return true
        }

        // 2. If the room itself is a light source and is lit, it's lit
        if room.hasFlag(.isLightSource) && room.hasFlag(.isOn) {
            return true
        }

        // 3. Check for light sources in the room
        let lightSources = room.contents.filter { obj in
            return obj.hasFlag(.isLightSource) && obj.hasFlag(.isOn)
        }

        if !lightSources.isEmpty {
            return true
        }

        // 4. Check if the player is in the room and has a light source
        if player.currentRoom === room {
            let playerLightSources = player.inventory.filter { obj in
                return obj.hasFlag(.isLightSource) && obj.hasFlag(.isOn)
            }

            if !playerLightSources.isEmpty {
                return true
            }
        }

        // 5. Check transparent containers in the room for light sources
        for container in room.contents where container.hasFlag(.isContainer) {
            // Light can pass through if container is transparent or open
            if container.hasFlags(.isTransparent, .isOpen, matching: .any) {
                if container.contents.contains(where: { obj in
                    obj.hasFlags(.isLightSource, .isOn)
                }) {
                    return true
                }
            }
        }

        // No light sources found
        return false
    }

    /// Resets a room's lighting state tracking for testing purposes.
    /// - Parameter room: The room to reset lighting state for.
    public func resetRoomLightingState(_ room: Room) {
        // Clear any stored lighting state
        room.setState(false, forKey: "wasLit")
    }

    /// Turns off all light sources a player is carrying.
    /// - Returns: `true` if any light sources were turned off.
    public func turnOffAllPlayerLights() -> Bool {
        var anyLightTurnedOff = false

        for obj in player.inventory {
            if obj.hasFlag(.isLightSource) && obj.hasFlag(.isOn) {
                obj.clearFlag(.isOn)
                anyLightTurnedOff = true
            }
        }

        return anyLightTurnedOff
    }

    /// Turns on all light sources a player is carrying.
    /// - Returns: `true` if any light sources were turned on.
    public func turnOnAllPlayerLights() -> Bool {
        var anyLightTurnedOn = false

        for obj in player.inventory {
            if obj.hasFlag(.isLightSource) && !obj.hasFlag(.isOn) {
                obj.setFlag(.isOn)
                anyLightTurnedOn = true
            }
        }

        return anyLightTurnedOn
    }
}

// MARK: - GameObject Lighting Extensions

/// Light/darkness functionality for game objects.
extension GameObject {
    /// Configures this object as a light source.
    /// - Parameter initiallyLit: Whether the light source starts in an active state.
    public func makeLightSource(initiallyLit: Bool = false) {
        setFlag(.isLightSource)
        if initiallyLit {
            setFlag(.isOn)
        }
    }

    /// Toggles this light source between on and off states.
    /// - Returns: `true` if the light is now on, `false` if it's off or not a light source.
    @discardableResult
    public func toggleLight() -> Bool {
        guard hasFlag(.isLightSource) else { return false }

        if hasFlag(.isOn) {
            clearFlag(.isOn)
            return false
        } else {
            setFlag(.isOn)
            return true
        }
    }

    /// Turns this light source off.
    /// - Returns: `true` if the light was turned off, `false` if it wasn't a light source.
    @discardableResult
    public func turnLightOff() -> Bool {
        guard hasFlag(.isLightSource) else { return false }

        clearFlag(.isOn)
        return true
    }

    /// Turns this light source on.
    /// - Returns: `true` if the light was turned on, `false` if it wasn't a light source.
    @discardableResult
    public func turnLightOn() -> Bool {
        guard hasFlag(.isLightSource) else { return false }

        setFlag(.isOn)
        return true
    }
}

// MARK: - Room Lighting Extensions

/// Light/darkness functionality for rooms.
extension Room {
    /// Checks if this room is currently lit.
    /// - Parameter world: The game world.
    /// - Returns: `true` if the room has any source of light.
    public func isLit(in world: GameWorld) -> Bool {
        return world.isRoomLit(self)
    }

    /// Configures this room to require a light source (not naturally lit).
    public func makeDark() {
        clearFlag(.isNaturallyLit)
    }

    /// Configures this room to be naturally lit (doesn't require a light source).
    public func makeNaturallyLit() {
        setFlag(.isNaturallyLit)
    }
}
