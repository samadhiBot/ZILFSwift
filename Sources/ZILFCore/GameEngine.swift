//
//  File.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation

public class GameEngine {
    public let world: GameWorld
    private let parser: CommandParser
    private var isRunning = false
    private let outputHandler: OutputHandler

    public init(world: GameWorld, outputHandler: OutputHandler = StandardOutputHandler()) {
        self.world = world
        self.parser = CommandParser(world: world)
        self.outputHandler = outputHandler
    }

    public func start() {
        isRunning = true
        outputHandler.output("Welcome to the Hello World Adventure!")
        outputHandler.output("Type 'help' for a list of commands.\n")

        // Start with a look at the current room
        executeCommand(.look)

        // Main game loop
        while isRunning {
            outputHandler.output("\n> ", terminator: "")
            guard let input = readLine() else { continue }

            if input.lowercased() == "help" {
                printHelp()
                continue
            }

            let command = parser.parse(input)
            executeCommand(command)

            // Advance time after each command (except game verbs)
            if !isGameVerb(command) {
                advanceTime()
            }
        }
    }

    public func executeCommand(_ command: Command) {
        // First check if the current room has an M-BEG handler
        if let room = world.player.currentRoom {
            // If the room's begin turn action handles the command, we're done
            if room.executeBeginTurnAction() {
                return
            }

            // Check if the room handles this specific command
            if room.executeBeginCommandAction(command: command) {
                return
            }
        }

        // Check if the room is dark before processing most commands
        if let room = world.player.currentRoom, !world.isRoomLit(room) {
            // Allow certain commands even in darkness
            switch command {
            case .look:
                handleLook()
                return
            case .move:
                // Still allow movement in darkness
                break
            case .inventory:
                // Still allow inventory in darkness
                break
            case .quit:
                // Still allow quitting in darkness
                break
            case .examine(let obj):
                // Allow examining light sources or objects in inventory even in darkness
                if obj.hasFlag(.lightSource) || obj.location === world.player {
                    // Process the examine command normally
                    break
                } else {
                    // For other objects, show a darkness message
                    outputHandler.output("It's too dark to see anything here.")
                    return
                }
            default:
                // For most commands, show a message about darkness
                outputHandler.output("It's too dark to see anything here.")
                return
            }
        }

        // Process the command as normal
        switch command {
        case .close(let obj):
            world.lastMentionedObject = obj

            if !obj.isContainer() {
                outputHandler.output("\(obj.name) cannot be closed.", terminator: "\n")
            } else if !obj.isOpenable() {
                outputHandler.output("\(obj.name) isn't something you can close.", terminator: "\n")
            } else if !obj.isOpen() {
                outputHandler.output("\(obj.name) is already closed.", terminator: "\n")
            } else {
                obj.close()
                outputHandler.output("You close \(obj.name).", terminator: "\n")
            }

        case .drop(let obj):
            if obj.location === world.player {
                // Remove from inventory
                if let index = world.player.contents.firstIndex(where: { $0 === obj }) {
                    world.player.contents.remove(at: index)
                }

                // Add to current room
                obj.location = world.player.currentRoom
                world.player.currentRoom?.contents.append(obj)

                outputHandler.output("Dropped.")

                world.lastMentionedObject = obj
            } else {
                outputHandler.output("You're not carrying that.")
            }

        case .examine(let obj):
            // Use getCurrentDescription to get the appropriate description
            let objDescription: String

            if obj.location === world.player {
                // Objects in inventory can always be seen
                objDescription = obj.getCurrentDescription(isLit: true)
            } else {
                // Other objects depend on room lighting
                objDescription = obj.getCurrentDescription(isLit: obj.location == nil || world.isRoomLit(obj.location as? Room ?? Room(name: "", description: "")))
            }

            outputHandler.output(objDescription, terminator: "\n")

            // Show detail text if available
            if let detailText = obj.getSpecialText(forKey: .detailText) {
                outputHandler.output(detailText, terminator: "\n")
            }

            world.lastMentionedObject = obj

            // If it's a container, use our getContentsDescription method
            if obj.isContainer() {
                let contentsDescription = obj.getContentsDescription()
                if !contentsDescription.isEmpty {
                    outputHandler.output(contentsDescription, terminator: "\n")
                }
            }

        case .inventory:
            if world.player.contents.isEmpty {
                outputHandler.output("You're not carrying anything.")
            } else {
                outputHandler.output("You are carrying:")
                for obj in world.player.contents {
                    outputHandler.output("  \(obj.name)")
                }
            }

        case .look:
            handleLook()

        case .move(let direction):
            if world.player.move(direction: direction) {
                executeCommand(.look)
            } else {
                outputHandler.output("You can't go that way.")
            }

        case .open(let obj):
            world.lastMentionedObject = obj

            if !obj.isContainer() {
                outputHandler.output("\(obj.name) cannot be opened.", terminator: "\n")
            } else if !obj.isOpenable() {
                outputHandler.output("\(obj.name) isn't something you can open.", terminator: "\n")
            } else if obj.isOpen() {
                outputHandler.output("\(obj.name) is already open.", terminator: "\n")
            } else {
                obj.open()
                outputHandler.output("You open \(obj.name).", terminator: "\n")

                // If there are visible contents, describe them
                if !obj.contents.isEmpty {
                    outputHandler.output("Inside you see:", terminator: "\n")
                    for item in obj.contents {
                        outputHandler.output("  \(item.name)", terminator: "\n")
                    }
                }
            }

        case .quit:
            outputHandler.output("Thanks for playing!")
            isRunning = false

        case .take(let obj):
            world.lastMentionedObject = obj

            if !obj.hasFlag("takeable") {
                outputHandler.output("You can't take that.", terminator: "\n")
                return
            }

            // Check if the object is directly in the room
            if obj.location === world.player.currentRoom {
                // Remove from room
                if let index = world.player.currentRoom?.contents.firstIndex(where: { $0 === obj }) {
                    world.player.currentRoom?.contents.remove(at: index)
                }

                // Add to inventory
                obj.location = world.player
                world.player.contents.append(obj)

                outputHandler.output("Taken.", terminator: "\n")
            }
            // Check if it's in a container in the room or inventory
            else if let container = obj.location,
                        container.isContainer() && container.canSeeInside() {
                // Object is in an open container
                if let index = container.contents.firstIndex(where: { $0 === obj }) {
                    container.contents.remove(at: index)
                }

                // Add to inventory
                obj.location = world.player
                world.player.contents.append(obj)

                outputHandler.output("Taken.", terminator: "\n")
            }
            // Check if the object is already in the player's inventory
            else if obj.location === world.player {
                outputHandler.output("You already have that.", terminator: "\n")
            }
            else {
                outputHandler.output("That's not here to take.", terminator: "\n")
            }

        case .unknown(let message):
            outputHandler.output(message)
        }
    }

    /// Handle the LOOK command
    private func handleLook() {
        if let room = world.player.currentRoom {
            // Check if the room's look action handles the description
            if !room.executeLookAction() {
                // If not, show the full room description using our special text properties
                let roomDescription = room.getFullRoomDescription(in: world)
                outputHandler.output(roomDescription, terminator: "\n")
            }
        }
    }

    /// Get a list of visible exit directions from a room
    /// - Parameter room: The room to check
    /// - Returns: A list of exit direction names
    private func getVisibleExits(_ room: Room) -> [String] {
        var exits: [String] = []

        // Add normal exits
        for direction in Direction.allCases {
            if room.getExit(direction: direction) != nil {
                exits.append(direction.rawValue)
            }
        }

        // Add visible special exits
        for direction in Direction.allCases {
            if let specialExit = room.getSpecialExit(direction: direction),
               specialExit.isVisible {
                exits.append(direction.rawValue)
            }
        }

        // Remove duplicates in case a direction has both regular and special exits
        return Array(Set(exits))
    }

    private func advanceTime() {
        // First check if the current room has an M-END handler
        if let room = world.player.currentRoom {
            room.executeEndTurnAction()
        }

        // Process any scheduled events
        let _ = world.eventManager.processEvents()
    }

    /// Helper to check if a command is a "game verb" that doesn't advance time
    private func isGameVerb(_ command: Command) -> Bool {
        switch command {
        case .look, .inventory, .quit:
            return true
        default:
            return false
        }
    }

    private func printHelp() {
        outputHandler.output("""
        Available commands:
          look - Look around the current location
          north/south/east/west/up/down - Move in a direction
          go [direction] - Move in a direction
          examine [object] - Look at something specific
          take [object] - Pick up an object
          drop [object] - Drop an object you're carrying
          inventory - List what you're carrying
          quit - End the game
        """)
    }
}

// Protocol for handling output from the game engine
public protocol OutputHandler {
    func output(_ text: String, terminator: String)
    func output(_ text: String)
}

// Default implementation that prints to stdout
public class StandardOutputHandler: OutputHandler {
    public init() {}

    public func output(_ text: String, terminator: String) {
        print(text, terminator: terminator)
    }

    public func output(_ text: String) {
        output(text, terminator: "\n")
    }
}
