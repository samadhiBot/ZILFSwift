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
            outputHandler.output(obj.description, terminator: "\n")

            world.lastMentionedObject = obj

            // If it's a container and we can see inside, show the contents
            if obj.isContainer() && obj.canSeeInside() {
                if obj.contents.isEmpty {
                    outputHandler.output("It's empty.", terminator: "\n")
                } else {
                    outputHandler.output("It contains:", terminator: "\n")
                    for item in obj.contents {
                        outputHandler.output("  \(item.name)", terminator: "\n")
                    }
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
        guard let room = world.player.currentRoom else {
            outputHandler.output("You can't see anything.")
            return
        }

        // First try the room's specific look handler
        if !room.executeLookAction() {
            // If no custom description, output the default
            outputHandler.output(room.description)
        }

        // Always run the flash action for important details
        room.executeFlashAction()

        // Describe objects in the room
        // List exits
        let availableExits = room.exits.keys.map { $0.rawValue }.joined(separator: ", ")
        if !availableExits.isEmpty {
            outputHandler.output("Exits: \(availableExits)")
        } else {
            outputHandler.output("There are no obvious exits.")
        }

        // List objects in the room (except the player)
        let visibleObjects = room.contents.filter { $0 !== world.player }
        if !visibleObjects.isEmpty {
            outputHandler.output("\nYou can see:")
            for obj in visibleObjects {
                outputHandler.output("  \(obj.name)")
            }
        }
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
