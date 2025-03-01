//
//  StandardFlags.swift
//  ZILFSwift
//
//  Created on current date
//

import Foundation

/// Standard flag keys used throughout the game
/// These are based on the standard flags from the ZIL implementation
public extension String {
    // General object flags

    /// Flag for articles - beginning with vowel (enables "an" vs "a")
    static let vowelBit = "vowel"

    /// Flag for objects that can be attacked
    static let attackBit = "attackable"

    /// Flag for containers (objects that can hold other objects)
    static let contBit = "container"

    /// Flag for devices that can be turned on/off
    static let deviceBit = "device"

    /// Flag for doors
    static let doorBit = "door"

    /// Flag for objects that can be eaten
    static let edibleBit = "edible"

    /// Flag for female objects (for pronoun handling)
    static let femaleBit = "female"

    /// Flag for invisible objects
    static let invisible = "invisible"

    /// Flag used for parser kludges
    static let kludgeBit = "kludge"

    /// Flag for locked objects
    static let lockedBit = "locked"

    /// Flag for objects that don't use a definite article
    static let nArticleBit = "no-article"

    /// Flag for objects that don't have a description
    static let nDescBit = "no-description"

    /// Flag for objects that are currently on (for devices)
    static let onBit = "on"

    /// Flag for objects that can be opened
    static let openableBit = "openable"

    /// Flag for objects that are currently open
    static let openBit = "open"

    /// Flag for person objects
    static let personBit = "person"

    /// Flag for plural objects (for grammar handling)
    static let pluralBit = "plural"

    /// Flag for objects that can be read
    static let readBit = "readable"

    /// Flag for objects that have a surface (things can be put on them)
    static let surfaceBit = "surface"

    /// Flag for objects that can be taken
    static let takeBit = "takeable"

    /// Flag for objects that can be used as tools
    static let toolBit = "tool"

    /// Flag for objects that can be touched
    static let touchBit = "touchable"

    /// Flag for transparent objects (can see through)
    static let transBit = "transparent"

    /// Flag for objects that should try to be taken when interacted with indirectly
    static let tryTakeBit = "try-take"

    /// Flag for objects that can be worn
    static let wearBit = "wearable"

    /// Flag for objects that are currently worn
    static let wornBit = "worn"

    // Note: Lighting-related flags are defined in LightingSystem.swift:
    // - lightSource
    // - lit
    // - naturallyLit
}
