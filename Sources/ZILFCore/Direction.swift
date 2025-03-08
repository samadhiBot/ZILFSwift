import Foundation

/// Directions for room connections.
public enum Direction: Hashable {
    /// The northern direction.
    case north

    /// The northeastern direction.
    case northEast

    /// The northwestern direction.
    case northWest

    /// The southern direction.
    case south

    /// The southeastern direction.
    case southEast

    /// The southwestern direction.
    case southWest

    /// The eastern direction.
    case east

    /// The western direction.
    case west

    /// The upward direction.
    case up

    /// The downward direction.
    case down

    /// The inward direction.
    case inward

    /// The outward direction.
    case outward

    /// A custom direction.
    case custom(String)
}

extension Direction {
    /// Attempts to derive a direction from a string.
    ///
    /// - Parameter string: A string representing a direction.
    /// - Returns: A direction if one can be derived.
    public static func from(_ string: String) -> Direction? {
        switch string.lowercased() {
        case "n", "north": .north
        case "ne", "northeast": .northEast
        case "nw", "northwest": .northWest
        case "s", "south": .south
        case "se", "southeast": .southEast
        case "sw", "southwest": .southWest
        case "e", "east": .east
        case "w", "west": .west
        case "u", "up": .up
        case "d", "down": .down
        case "in", "inward": .inward
        case "out", "outward": .outward
        default: nil
        }
    }

    /// The direction's opposite, useful for two-way connections.
    public var opposite: Direction? {
        switch self {
        case .north: .south
        case .northEast: .southWest
        case .northWest: .southEast
        case .south: .north
        case .southEast: .northWest
        case .southWest: .northEast
        case .east: .west
        case .west: .east
        case .up: .down
        case .down: .up
        case .inward: .outward
        case .outward: .inward
        case .custom: nil
        }
    }
    
    /// The direction's raw text value, for use in game output.
    public var rawValue: String {
        switch self {
        case .north: "north"
        case .northEast: "northeast"
        case .northWest: "northwest"
        case .south: "south"
        case .southEast: "southeast"
        case .southWest: "southwest"
        case .east: "east"
        case .west: "west"
        case .up: "up"
        case .down: "down"
        case .inward: "in"
        case .outward: "out"
        case .custom(let direction): direction
        }
    }
}
