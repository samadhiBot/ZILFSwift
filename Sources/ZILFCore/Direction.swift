import Foundation

/// Directions for room connections.
public enum Direction: Hashable, Sendable {
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
    public init?(_ rawValue: String) {
        switch rawValue.lowercased() {
        case "n", "north": self = .north
        case "ne", "northeast": self = .northEast
        case "nw", "northwest": self = .northWest
        case "s", "south": self = .south
        case "se", "southeast": self = .southEast
        case "sw", "southwest": self = .southWest
        case "e", "east": self = .east
        case "w", "west": self = .west
        case "u", "up": self = .up
        case "d", "down": self = .down
        case "in", "inward": self = .inward
        case "out", "outward": self = .outward
        default: return nil
        }
    }
}

extension Direction {
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

extension Direction: CaseIterable {
    public static var allCases: [Direction] {
        [
            .north,
            .northEast,
            .northWest,
            .south,
            .southEast,
            .southWest,
            .east,
            .west,
            .up,
            .down,
            .inward,
            .outward,
        ]
    }
}
