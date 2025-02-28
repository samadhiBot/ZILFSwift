//
//  LightingSystem.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/28/25.
//

import Foundation

/// Standard flag keys used throughout the game
public extension String {
    /// Flag for objects or rooms that provide light
    static let lightSource = "light-source"

    /// Flag for objects that are currently lit/on
    static let lit = "lit"

    /// Flag for rooms that are naturally lit (don't require a light source)
    static let naturallyLit = "naturally-lit"

    /// Flag for transparent objects that light can pass through
    static let transparent = "transparent"
}

/// Light/Darkness Mechanics
///
/// This extension provides lighting functionality for the game world, including:
/// - Tracking which rooms and objects provide light
/// - Determining if a room is currently lit
/// - Handling dynamic lighting changes
/// - Providing helper functions like those in ZIL such as NOW-LIT? and NOW-DARK?
public extension GameWorld {

    /// Determine if a room is currently lit
    /// - Parameter room: The room to check
    /// - Returns: True if the room is lit by any source
    func isRoomLit(_ room: Room) -> Bool {
        // 1. If the room is naturally lit, it's always lit
        if room.hasFlag(.naturallyLit) {
            return true
        }

        // 2. If the room itself is a light source and is lit, it's lit
        if room.hasFlag(.lightSource) && room.hasFlag(.lit) {
            return true
        }

        // 3. Check for light sources in the room
        let lightSources = room.contents.filter { obj in
            return obj.hasFlag(.lightSource) && obj.hasFlag(.lit)
        }

        if !lightSources.isEmpty {
            return true
        }

        // 4. Check if the player is in the room and has a light source
        if player.currentRoom === room {
            let playerLightSources = player.contents.filter { obj in
                return obj.hasFlag(.lightSource) && obj.hasFlag(.lit)
            }

            if !playerLightSources.isEmpty {
                return true
            }
        }

        // 5. Check transparent containers in the room for light sources
        for container in room.contents {
            if container.isContainer() {
                // Light can pass through if container is transparent or open
                let lightCanPass = container.hasFlag(.transparent) || container.hasFlag("open")

                if lightCanPass {
                    let containerLightSources = container.contents.filter { obj in
                        return obj.hasFlag(.lightSource) && obj.hasFlag(.lit)
                    }

                    if !containerLightSources.isEmpty {
                        return true
                    }
                }
            }
        }

        // No light sources found
        return false
    }

    /// Check if a room just became lit (equivalent to ZIL's NOW-LIT?)
    /// - Parameter room: The room to check
    /// - Returns: True if the room just became lit
    func didRoomBecomeLit(_ room: Room) -> Bool {
        // Get previous light status
        let wasLit: Bool = room.getState(forKey: "wasLit") ?? false

        // Get current light status
        let isLit = isRoomLit(room)

        // Store the current state for next time
        room.setState(isLit, forKey: "wasLit")

        // Return true if it was dark and is now lit
        return !wasLit && isLit
    }

    /// Check if a room just became dark (equivalent to ZIL's NOW-DARK?)
    /// - Parameter room: The room to check
    /// - Returns: True if the room just became dark
    func didRoomBecomeDark(_ room: Room) -> Bool {
        // Get previous light status
        let wasLit: Bool = room.getState(forKey: "wasLit") ?? false

        // Get current light status
        let isLit = isRoomLit(room)

        // Store the current state for next time
        room.setState(isLit, forKey: "wasLit")

        // Return true if it was lit and is now dark
        return wasLit && !isLit
    }

    /// Turn on all light sources a player is carrying
    /// - Returns: True if any light sources were turned on
    func turnOnAllPlayerLights() -> Bool {
        var anyLightTurnedOn = false

        for obj in player.contents {
            if obj.hasFlag(.lightSource) && !obj.hasFlag(.lit) {
                obj.setFlag(.lit)
                anyLightTurnedOn = true
            }
        }

        return anyLightTurnedOn
    }

    /// Turn off all light sources a player is carrying
    /// - Returns: True if any light sources were turned off
    func turnOffAllPlayerLights() -> Bool {
        var anyLightTurnedOff = false

        for obj in player.contents {
            if obj.hasFlag(.lightSource) && obj.hasFlag(.lit) {
                obj.clearFlag(.lit)
                anyLightTurnedOff = true
            }
        }

        return anyLightTurnedOff
    }

    /// Get all available light sources in a room or carried by the player
    /// - Parameter room: The room to check
    /// - Returns: Array of light source objects
    func availableLightSources(in room: Room) -> [GameObject] {
        var lightSources: [GameObject] = []

        // Room itself might be a light source
        if room.hasFlag(.lightSource) {
            lightSources.append(room)
        }

        // Add light sources in the room
        for obj in room.contents where obj.hasFlag(.lightSource) {
            lightSources.append(obj)
        }

        // Add player's light sources if player is in this room
        if player.currentRoom === room {
            for obj in player.contents where obj.hasFlag(.lightSource) {
                lightSources.append(obj)
            }
        }

        return lightSources
    }

    /// Check if a given object is currently providing light
    /// - Parameter object: The object to check
    /// - Returns: True if the object is providing light
    func isProvidingLight(_ object: GameObject) -> Bool {
        return object.hasFlag(.lightSource) && object.hasFlag(.lit)
    }

    /// Reset a room's lighting state tracking for testing purposes
    /// - Parameter room: The room to reset lighting state for
    func resetRoomLightingState(_ room: Room) {
        // Clear any stored lighting state
        room.setState(false, forKey: "wasLit")
    }
}

/// Light/Darkness extensions for GameObjects
public extension GameObject {
    /// Make this object a light source
    /// - Parameter initiallyLit: Whether the light source starts lit
    func makeLightSource(initiallyLit: Bool = false) {
        setFlag(.lightSource)
        if initiallyLit {
            setFlag(.lit)
        }
    }

    /// Turn this light source on
    /// - Returns: True if the light was turned on, false if it wasn't a light source
    @discardableResult
    func turnLightOn() -> Bool {
        guard hasFlag(.lightSource) else { return false }

        setFlag(.lit)
        return true
    }

    /// Turn this light source off
    /// - Returns: True if the light was turned off, false if it wasn't a light source
    @discardableResult
    func turnLightOff() -> Bool {
        guard hasFlag(.lightSource) else { return false }

        clearFlag(.lit)
        return true
    }

    /// Toggle this light source on/off
    /// - Returns: True if the light is now on, false if it's off or not a light source
    @discardableResult
    func toggleLight() -> Bool {
        guard hasFlag(.lightSource) else { return false }

        if hasFlag(.lit) {
            clearFlag(.lit)
            return false
        } else {
            setFlag(.lit)
            return true
        }
    }
}

/// Light/Darkness extensions for Room
public extension Room {
    /// Make this room naturally lit (doesn't require a light source)
    func makeNaturallyLit() {
        setFlag(.naturallyLit)
    }

    /// Make this room dark (requires a light source)
    func makeDark() {
        clearFlag(.naturallyLit)
    }

    /// Check if this room is currently lit
    /// - Parameter world: The game world
    /// - Returns: True if the room is lit
    func isLit(in world: GameWorld) -> Bool {
        return world.isRoomLit(self)
    }
}
