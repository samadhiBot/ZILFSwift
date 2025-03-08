import Foundation

/// Directions for room connections.
public enum Direction: String, CaseIterable {
    /// The northern direction.
    case north

    /// The northeastern direction.
    case northeast

    /// The northwestern direction.
    case northwest

    /// The southern direction.
    case south

    /// The southeastern direction.
    case southeast

    /// The southwestern direction.
    case southwest

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
}

extension Direction {
    /// Attempts to derive a direction from common abbreviations.
    ///
    /// - Parameter string: A string representing a direction.
    /// - Returns: A direction if one can be derived.
    public static func from(string: String) -> Direction? {
        switch string.lowercased() {
        case "n", "north": .north
        case "ne", "northeast": .northeast
        case "nw", "northwest": .northwest
        case "s", "south": .south
        case "se", "southeast": .southeast
        case "sw", "southwest": .southwest
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
    public var opposite: Direction {
        switch self {
        case .north: .south
        case .northeast: .southwest
        case .northwest: .southeast
        case .south: .north
        case .southeast: .northwest
        case .southwest: .northeast
        case .east: .west
        case .west: .east
        case .up: .down
        case .down: .up
        case .inward: .outward
        case .outward: .inward
        }
    }
}
