import Foundation

/// Standard flag keys used throughout the game
/// These are based on the standard flags from the ZIL implementation
extension String {
    // General object flags

    /// Flag for articles - beginning with vowel (enables "an" vs "a")
    public static let vowelBit = "vowel"

    /// Flag for objects that can be attacked
    public static let attackBit = "attackable"

    /// Flag for containers (objects that can hold other objects)
    public static let contBit = "container"

    /// Flag for devices that can be turned on/off
    public static let deviceBit = "device"

    /// Flag for doors
    public static let doorBit = "door"

    /// Flag for objects that can be eaten
    public static let edibleBit = "edible"

    /// Flag for female objects (for pronoun handling)
    public static let femaleBit = "female"

    /// Flag for invisible objects
    public static let invisible = "invisible"

    /// Flag used for parser kludges
    public static let kludgeBit = "kludge"

    /// Flag for locked objects
    public static let lockedBit = "locked"

    /// Flag for objects that don't use a definite article
    public static let nArticleBit = "no-article"

    /// Flag for objects that don't have a description
    public static let nDescBit = "no-description"

    /// Flag for objects that are currently on (for devices)
    public static let onBit = "on"

    /// Flag for objects that can be opened
    public static let openableBit = "openable"

    /// Flag for objects that are currently open
    public static let openBit = "open"

    /// Flag for person objects
    public static let personBit = "person"

    /// Flag for plural objects (for grammar handling)
    public static let pluralBit = "plural"

    /// Flag for objects that can be read
    public static let readBit = "readable"

    /// Flag for objects that have a surface (things can be put on them)
    public static let surfaceBit = "surface"

    /// Flag for objects that can be taken
    public static let takeBit = "takeable"

    /// Flag for objects that can be used as tools
    public static let toolBit = "tool"

    /// Flag for objects that can be touched
    public static let touchBit = "touchable"

    /// Flag for transparent objects (can see through)
    public static let transBit = "transparent"

    /// Flag for objects that should try to be taken when interacted with indirectly
    public static let tryTakeBit = "try-take"

    /// Flag for objects that can be worn
    public static let wearBit = "wearable"

    /// Flag for objects that are currently worn
    public static let wornBit = "worn"

    // Note: Lighting-related flags are defined in LightingSystem.swift:
    // - lightSource
    // - lit
    // - naturallyLit
}
