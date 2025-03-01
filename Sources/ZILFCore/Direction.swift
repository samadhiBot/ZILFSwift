//
//  GameModel.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation

// Directions for room connections
public enum Direction: String, CaseIterable {
    case north, south, east, west, up, down

    // Support common abbreviations
    public static func from(string: String) -> Direction? {
        switch string.lowercased() {
        case "n", "north": return .north
        case "s", "south": return .south
        case "e", "east": return .east
        case "w", "west": return .west
        case "u", "up": return .up
        case "d", "down": return .down
        default: return nil
        }
    }

    // Opposite direction - useful for two-way connections
    public var opposite: Direction {
        switch self {
        case .north: return .south
        case .south: return .north
        case .east: return .west
        case .west: return .east
        case .up: return .down
        case .down: return .up
        }
    }
}
