//
//  File.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation

public class GameEngine {
    public var world: GameWorld
    private var parser: CommandParser
    private var isRunning = false
    private var outputHandler: (String) -> Void
    private var lastCommand: Command?

    // Game over state tracking
    private var isGameOver = false
    private var gameOverMessage: String?

    // Add public accessors for testing
    public func getState<T>(forKey key: String) -> T? {
        switch key {
        case "isGameOver":
            return isGameOver as? T
        case "gameOverMessage":
            return gameOverMessage as? T
        default:
            return nil
        }
    }

    // World creator function for game restarts
    private var worldCreator: (() -> GameWorld)?

    public init(world: GameWorld, outputHandler: @escaping (String) -> Void = { print($0) }, worldCreator: (() -> GameWorld)? = nil) {
        self.world = world
        self.parser = CommandParser(world: world)
        self.outputHandler = outputHandler
        self.worldCreator = worldCreator

        // Register the engine in the player object for access
        // Store it directly in the player which is accessible everywhere
        world.player.setState(self, forKey: "engine")
    }

    public func start() {
        isRunning = true
        isGameOver = false

        outputHandler("Welcome to the Hello World Adventure!")
        outputHandler("Type 'help' for a list of commands.\n")

        // Start with a look at the current room
        executeCommand(.look)

        // Main game loop
        while isRunning {
            if isGameOver {
                // If game is over, only accept restart or quit commands
                print("> ", terminator: "") // Use print directly with terminator to fix cursor position
                guard let input = readLine()?.lowercased() else { continue }

                switch input {
                case "restart":
                    handleRestart()
                case "quit":
                    handleQuit()
                    break
                default:
                    outputHandler("Please type RESTART or QUIT.")
                }
                continue
            }

            print("> ", terminator: "") // Use print directly with terminator to fix cursor position
            guard let input = readLine() else { continue }

            if input.lowercased() == "help" {
                printHelp()
                continue
            }

            let command = parser.parse(input)
            executeCommand(command)

            // Advance time after each command (except game verbs)
            if !isGameVerb(getVerbForCommand(command)) {
                advanceTime()
            }
        }
    }

    public func executeCommand(_ command: Command) {
        // Don't process commands if game is over
        if isGameOver {
            return
        }

        // Store the command for potential "again" (g) command
        if getVerbForCommand(command) != "again" {
            lastCommand = command
        }

        // If we're in a dark room, only allow certain commands
        guard let currentRoom = world.player.currentRoom else {
            outputHandler("Error: Player has no current room!")
            return
        }

        let isRoomDark = !world.isRoomLit(currentRoom)

        if isRoomDark {
            // Check if the current room has a handler for this command
            if let beginCommandAction = currentRoom.beginCommandAction,
               beginCommandAction(currentRoom, command) {
                // The room's custom action handled the command
                advanceTime()
                return
            }

            // Commands allowed in darkness
            switch command {
            case .look, .inventory, .quit, .move, .take, .drop:
                // These commands are allowed in darkness
                break
            case .customCommand(let verb, _, _):
                // Allow certain custom commands in darkness
                if verb == "wait" || verb == "again" ||
                   verb == "version" || verb == "save" ||
                   verb == "restore" || verb == "restart" ||
                   verb == "undo" || verb == "brief" ||
                   verb == "verbose" || verb == "superbrief" {
                    break
                } else {
                    outputHandler("It's too dark to see.")
                    return
                }
            default:
                outputHandler("It's too dark to see.")
                return
            }
        }

        // Check if the current room has a handler for this command
        if let beginCommandAction = currentRoom.beginCommandAction,
           beginCommandAction(currentRoom, command) {
            // The room's custom action handled the command
            advanceTime()
            return
        }

        // Process the command
        switch command {
        case .look:
            handleLook()
        case .inventory:
            handleInventory()
        case .move(let direction):
            handleMove(direction: direction)
        case .take(let obj):
            handleTake(obj)
        case .drop(let obj):
            handleDrop(obj)
        case .examine(let obj):
            handleExamine(obj)
        case .open(let obj):
            handleOpen(obj)
        case .close(let obj):
            handleClose(obj)
        case .quit:
            handleQuit()
        case .unknown(let message):
            outputHandler(message)
        case .customCommand(let verb, let objects, _):
            switch verb {
            case "wear":
                if let obj = objects.first {
                    handleWear(obj)
                } else {
                    outputHandler("Wear what?")
                }
            case "unwear", "remove", "take_off":
                if let obj = objects.first {
                    handleUnwear(obj)
                } else {
                    outputHandler("Take off what?")
                }
            case "put_on":
                if let objects = getMultipleGameObjects(from: command), objects.count >= 2 {
                    handlePutOn(objects[0], surface: objects[1])
                } else {
                    outputHandler("You need to specify what to put where.")
                }
            case "put_in":
                if let objects = getMultipleGameObjects(from: command), objects.count >= 2 {
                    handlePutIn(objects[0], container: objects[1])
                } else {
                    outputHandler("You need to specify what to put where.")
                }
            case "turn_on":
                if let obj = objects.first {
                    handleTurnOn(obj)
                }
            case "turn_off":
                if let obj = objects.first {
                    handleTurnOff(obj)
                }
            case "flip":
                if let obj = objects.first {
                    handleFlip(obj)
                }
            case "wait":
                handleWait()
            case "again":
                handleAgain()
            case "read":
                if let obj = objects.first {
                    handleRead(obj)
                }
            default:
                outputHandler("Sorry, that command isn't implemented yet.")
            }
        }

        // Only advance time for non-game verbs
        let verb = getVerbForCommand(command)
        if !isGameVerb(verb) {
            advanceTime()
        }
    }

    /// Handle the LOOK command
    private func handleLook() {
        if let room = world.player.currentRoom {
            // Check if the room's look action handles the description
            if !room.executeLookAction() {
                // If not, show the full room description using our special text properties
                let roomDescription = room.getFullRoomDescription(in: world)
                outputHandler(roomDescription)
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
        // Process one turn of game actions and events
        let _ = world.waitTurns(1)
    }

    /// Helper to check if a command is a "game verb" that doesn't advance time
    private func isGameVerb(_ verb: String) -> Bool {
        return verb == "save" || verb == "restore" || verb == "version" ||
               verb == "quit" || verb == "undo" || verb == "restart" ||
               verb == "brief" || verb == "verbose" || verb == "superbrief"
    }

    private func printHelp() {
        outputHandler("""
        Available commands:
        - look: Look around
        - inventory (or i): Check your inventory
        - take/get [object]: Pick up an object
        - drop [object]: Drop an object
        - examine/x [object]: Look at an object in detail
        - open [object]: Open a container
        - close [object]: Close a container
        - wear [object]: Put on wearable items
        - unwear/take off [object]: Remove worn items
        - put [object] in/on [container/surface]: Place objects in containers or on surfaces
        - turn on/off [device]: Operate devices
        - flip/switch [device]: Toggle devices on/off
        - wait (or z): Wait one turn
        - again (or g): Repeat your last command
        - read [object]: Read something
        - north/south/east/west/up/down (or n/s/e/w/u/d): Move in that direction
        - quit: End the game
        """)
    }

    // MARK: - Helper Methods

    /// Check if an object is accessible for examination
    /// - Parameter obj: The object to check
    /// - Returns: True if the object can be examined
    private func isObjectAccessibleForExamine(_ obj: GameObject) -> Bool {
        // Object is in player's inventory
        if obj.isIn(world.player) {
            return true
        }

        // Object is in current room
        if let room = world.player.currentRoom, obj.isIn(room) {
            return true
        }

        // Object is in an open container in the room or player's inventory
        return isObjectVisible(obj)
    }

    /// Retrieve multiple game objects from a command
    private func getMultipleGameObjects(from command: Command) -> [GameObject]? {
        switch command {
        case .customCommand(_, let objects, _):
            return objects.isEmpty ? nil : objects
        default:
            return nil
        }
    }

    /// Get the first game object from a command
    private func getGameObject(from command: Command) -> GameObject? {
        switch command {
        case .take(let obj), .drop(let obj), .examine(let obj), .open(let obj), .close(let obj):
            return obj
        case .customCommand(_, let objects, _):
            return objects.first
        default:
            return nil
        }
    }

    /// Get the verb string for a command
    private func getVerbForCommand(_ command: Command) -> String {
        switch command {
        case .look: return "look"
        case .inventory: return "inventory"
        case .move: return "move"
        case .take: return "take"
        case .drop: return "drop"
        case .examine: return "examine"
        case .open: return "open"
        case .close: return "close"
        case .quit: return "quit"
        case .unknown: return "unknown"
        case .customCommand(let verb, _, _): return verb
        }
    }

    /// Handle the INVENTORY command
    private func handleInventory() {
        let items = world.player.inventory

        if items.isEmpty {
            outputHandler("You're not carrying anything.")
        } else {
            outputHandler("You are carrying:")
            for obj in items {
                outputHandler("  \(obj.name)")
            }
        }
    }

    /// Handle the TAKE command
    private func handleTake(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if object is already in inventory
        if obj.location === world.player {
            outputHandler("You're already carrying that.")
            return
        }

        // Check if object is takeable
        if !obj.isTakeable() {
            outputHandler("You can't take that.")
            return
        }

        // Take the object
        obj.moveTo(destination: world.player)
        outputHandler("Taken.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the DROP command
    private func handleDrop(_ obj: GameObject) {
        // Check if player has the object
        if obj.location !== world.player {
            outputHandler("You're not carrying that.")
            return
        }

        // Drop the object in the current room
        if let room = world.player.currentRoom {
            obj.moveTo(destination: room)
            outputHandler("Dropped.")

            // Update last mentioned object
            world.lastMentionedObject = obj
        } else {
            outputHandler("You have nowhere to drop that.")
        }
    }

    /// Handle the EXAMINE command
    private func handleExamine(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Show the object's description
        outputHandler(obj.description)

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the MOVE command
    private func handleMove(direction: Direction) {
        let player = world.player

        if player.move(direction: direction) {
            // Player successfully moved, show the new room description
            handleLook()
        } else {
            outputHandler("You can't go that way.")
        }
    }

    /// Handle the OPEN command
    private func handleOpen(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if object is openable
        if !obj.isOpenable() {
            outputHandler("You can't open that.")
            return
        }

        // Check if already open
        if obj.isOpen() {
            outputHandler("That's already open.")
            return
        }

        // Open the object
        let _ = obj.open()
        outputHandler("Opened.")

        // If this is a container and it has contents, describe them
        if obj.isContainer() && obj.canSeeInside() {
            let contents = obj.contents
            if !contents.isEmpty {
                outputHandler("You see:")
                for item in contents {
                    outputHandler("  \(item.name)")
                }
            }
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the CLOSE command
    private func handleClose(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if object is openable
        if !obj.isOpenable() {
            outputHandler("You can't close that.")
            return
        }

        // Check if already closed
        if !obj.isOpen() {
            outputHandler("That's already closed.")
            return
        }

        // Close the object
        let _ = obj.close()
        outputHandler("Closed.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle custom commands
    private func handleCustomCommand(verb: String, objects: [GameObject], additionalData: String?) {
        switch verb.lowercased() {
        case "wear", "put_on":
            if let obj = objects.first {
                handleWear(obj)
            } else {
                outputHandler("Wear what?")
            }

        case "unwear", "take_off", "remove":
            if let obj = objects.first {
                handleUnwear(obj)
            } else {
                outputHandler("Take off what?")
            }

        case "put_in":
            if objects.count >= 2 {
                handlePutIn(objects[0], container: objects[1])
            } else {
                outputHandler("You need to specify what to put where.")
            }

        case "turn_on":
            if let obj = objects.first {
                handleTurnOn(obj)
            } else {
                outputHandler("Turn on what?")
            }

        case "turn_off":
            if let obj = objects.first {
                handleTurnOff(obj)
            } else {
                outputHandler("Turn off what?")
            }

        case "flip":
            if let obj = objects.first {
                handleFlip(obj)
            } else {
                outputHandler("Flip what?")
            }

        case "wait":
            handleWait()

        case "again":
            handleAgain()

        case "read":
            if let obj = objects.first {
                handleRead(obj)
            } else {
                outputHandler("Read what?")
            }

        default:
            outputHandler("I don't know how to do that.")
        }
    }

    /// Handle WEAR command
    private func handleWear(_ obj: GameObject) {
        // Check if the object is in the player's inventory
        if !obj.isIn(world.player) {
            outputHandler("You need to be holding \(obj.name) first.")
            return
        }

        // Check if the object is wearable
        if !obj.hasFlag(String.wearBit) {
            outputHandler("You can't wear \(obj.name).")
            return
        }

        // Check if the object is already worn
        if obj.hasFlag(String.wornBit) {
            outputHandler("You're already wearing \(obj.name).")
            return
        }

        // Wear the object
        obj.setFlag(String.wornBit)
        outputHandler("You put on \(obj.name).")
    }

    /// Handle UNWEAR command
    private func handleUnwear(_ obj: GameObject) {
        // Check if the object is in the player's inventory
        if !obj.isIn(world.player) {
            outputHandler("You're not wearing \(obj.name).")
            return
        }

        // Check if the object is worn
        if !obj.hasFlag(String.wornBit) {
            outputHandler("You're not wearing \(obj.name).")
            return
        }

        // Unwear the object
        obj.clearFlag(String.wornBit)
        outputHandler("You take off \(obj.name).")
    }

    /// Handle PUT_IN command
    private func handlePutIn(_ obj: GameObject, container: GameObject) {
        // Check if player has the object
        if obj.location !== world.player {
            outputHandler("You're not carrying that.")
            return
        }

        // Check if container is accessible
        if !isObjectAccessibleForExamine(container) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if destination is a container
        if !container.isContainer() {
            outputHandler("You can't put anything in that.")
            return
        }

        // Check if container is open
        if !container.isOpen() {
            outputHandler("The \(container.name) is closed.")
            return
        }

        // Put the object in the container
        obj.moveTo(destination: container)
        outputHandler("You put the \(obj.name) in the \(container.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle TURN_ON command
    private func handleTurnOn(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object is a device
        if !obj.hasFlag(.deviceBit) {
            outputHandler("You can't turn on \(obj.name).")
            return
        }

        // Check if the device is already on
        if obj.hasFlag(.onBit) {
            outputHandler("The \(obj.name) is already on.")
            return
        }

        // Turn on the device
        obj.setFlag(.onBit)

        // If it's a light source, handle lighting change
        if obj.hasFlag(.lightSource) {
            obj.setFlag(.lit)
        }

        outputHandler("You turn on the \(obj.name).")
    }

    /// Handle TURN_OFF command
    private func handleTurnOff(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object is a device
        if !obj.hasFlag(.deviceBit) {
            outputHandler("You can't turn off \(obj.name).")
            return
        }

        // Check if the device is already off
        if !obj.hasFlag(.onBit) {
            outputHandler("The \(obj.name) is already off.")
            return
        }

        // Turn off the device
        obj.clearFlag(.onBit)

        // If it's a light source, handle lighting change
        if obj.hasFlag(.lightSource) {
            obj.clearFlag(.lit)
        }

        outputHandler("You turn off the \(obj.name).")
    }

    /// Handle FLIP command (toggle on/off)
    private func handleFlip(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object is a device
        if !obj.hasFlag(.deviceBit) {
            outputHandler("You can't flip \(obj.name).")
            return
        }

        // Toggle the device state
        if obj.hasFlag(.onBit) {
            obj.clearFlag(.onBit)

            // If it's a light source, handle lighting change
            if obj.hasFlag(.lightSource) {
                obj.clearFlag(.lit)
            }

            outputHandler("You turn off the \(obj.name).")
        } else {
            obj.setFlag(.onBit)

            // If it's a light source, handle lighting change
            if obj.hasFlag(.lightSource) {
                obj.setFlag(.lit)
            }

            outputHandler("You turn on the \(obj.name).")
        }
    }

    /// Handle WAIT command
    private func handleWait() {
        outputHandler("Time passes...")
    }

    /// Handle AGAIN command (repeat last command)
    private func handleAgain() {
        if let lastCommand = lastCommand {
            outputHandler("(repeating the last command)")
            executeCommand(lastCommand)
        } else {
            outputHandler("There's no command to repeat.")
        }
    }

    /// Handle READ command
    private func handleRead(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object is readable
        if !obj.hasFlag(.readBit) {
            outputHandler("There's nothing to read on \(obj.name).")
            return
        }

        // Get the text to display
        let text: String? = obj.getState(forKey: "readText")
        if let text = text {
            outputHandler(text)
        } else {
            outputHandler("You can't make out anything written on \(obj.name).")
        }
    }

    /// Handle the QUIT command
    private func handleQuit() {
        outputHandler("Thanks for playing!")
        isRunning = false
    }

    /// Handle Game Over - called when the game ends
    /// - Parameters:
    ///   - message: Message to display to the player
    ///   - isVictory: Whether this is a victory (win) or defeat (lose)
    public func gameOver(message: String, isVictory: Bool = false) {
        if isGameOver {
            return  // Don't trigger game over more than once
        }

        isGameOver = true
        gameOverMessage = message

        // Display the game over message with appropriate formatting
        outputHandler("\n*** \(isVictory ? "VICTORY" : "GAME OVER") ***")
        outputHandler(message)

        // Prompt for restart or quit
        outputHandler("\nWould you like to RESTART or QUIT?")

        // Handle the player's choice
        while isGameOver && isRunning {
            print("> ", terminator: "") // Use print directly with terminator to fix cursor position
            guard let input = readLine()?.lowercased() else { continue }

            switch input {
            case "restart":
                handleRestart()
            case "quit":
                handleQuit()
            default:
                outputHandler("Please type RESTART or QUIT.")
            }
        }
    }

    /// Handle restarting the game
    private func handleRestart() {
        isGameOver = false
        gameOverMessage = nil

        // Reset the game world
        let newWorld = recreateWorld()
        world = newWorld
        parser = CommandParser(world: world)

        outputHandler("\n--- Game Restarted ---\n")

        // Start with a look at the current room
        executeCommand(.look)
    }

    /// Recreate the game world for restart
    /// - Returns: A fresh game world, or nil if creation fails
    private func recreateWorld() -> GameWorld {
        if let worldCreator = worldCreator {
            let freshWorld = worldCreator()

            // Register the engine in the new world's player
            freshWorld.player.setState(self, forKey: "engine")

            return freshWorld
        } else {
            // Fall back to a simple new world if no creator function was provided
            let freshWorld = GameWorld(player: Player(startingRoom: Room(name: "Default", description: "Default room")))

            // Register the engine in the new world's player
            freshWorld.player.setState(self, forKey: "engine")

            return freshWorld
        }
    }

    /// Execute the game loop - an alternative to start() that doesn't block
    /// - Parameter input: The command input string
    /// - Returns: True if the game is still running, false if it ended
    public func executeGameLoop(input: String) -> Bool {
        if !isRunning || isGameOver {
            return false
        }

        if input.lowercased() == "help" {
            printHelp()
        } else {
            let command = parser.parse(input)
            executeCommand(command)

            // Check for game over after command execution
            if isGameOver {
                return false
            }

            // Advance time after each command (except game verbs)
            if !isGameVerb(getVerbForCommand(command)) {
                advanceTime()
            }
        }

        return isRunning && !isGameOver
    }

    /// Check if a character is in a dangerous situation that could lead to death
    /// - Returns: True if the player is in danger
    public func isPlayerInDanger() -> Bool {
        // Game-specific logic to determine if player is in danger
        // Example: Checking if player is in a room with an enemy or hazard
        return false
    }

    // Helper function to check if an object is visible to the player
    private func isObjectVisible(_ obj: GameObject) -> Bool {
        // Check if object is in the current room or player's inventory
        if let room = world.player.currentRoom {
            if obj.isIn(room) || obj.isIn(world.player) {
                return true
            }

            // Check if object is in an open container in the room or inventory
            let containersInRoom = room.contents.filter { $0.isContainer() && $0.isOpen() }
            let containersInInventory = world.player.contents.filter { $0.isContainer() && $0.isOpen() }

            let allContainers = containersInRoom + containersInInventory

            for container in allContainers {
                if obj.isIn(container) {
                    return true
                }
            }

            // Check if this is a global object accessible from the current room
            if obj.isGlobalObject() && world.isGlobalObjectAccessible(obj, in: room) {
                return true
            }
        }

        return false
    }

    /// Executes the move direction component of a command
    private func executeMove(_ direction: Direction) {
        // Check if there's a special exit in this direction
        if let room = world.player.currentRoom,
           let specialExit = room.getSpecialExit(direction: direction) {

            // Check if the special exit condition is met
            let conditionMet = specialExit.condition(world)
            if conditionMet == false {
                // Condition failed, show failure message if provided
                if let failureMessage = specialExit.failureMessage {
                    outputHandler(failureMessage)
                } else {
                    outputHandler("You can't go that way.")
                }
                return
            }

            // Execute the traversal, including any custom behavior
            let destination = specialExit.destination
            world.player.moveTo(destination: destination)

            // Show success message if provided, otherwise look at new location
            if let successMessage = specialExit.successMessage {
                outputHandler(successMessage)
            }

            // Execute the onTraverse action if provided
            if let onTraverse = specialExit.onTraverse {
                onTraverse(world)
            }

            // Auto-look in the new room
            executeCommand(.look)

        } else {
            // No special exit, try normal movement
            handleMove(direction: direction)
        }
    }

    // Handle custom command: PUT ON (place something on a surface)
    private func handlePutOn(_ obj: GameObject, surface: GameObject) {
        // Check if player has the object
        if obj.location !== world.player {
            outputHandler("You're not carrying that.")
            return
        }

        // Check if surface is accessible
        if !isObjectAccessibleForExamine(surface) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if destination is a surface
        if !surface.hasFlag(.surfaceBit) {
            outputHandler("You can't put anything on that.")
            return
        }

        // Put the object on the surface
        obj.moveTo(destination: surface)
        outputHandler("You put the \(obj.name) on the \(surface.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Kill the player, triggering game over
    /// - Parameter message: The death message to display
    public func playerDied(message: String) {
        gameOver(message: message, isVictory: false)
    }

    /// Player has won the game
    /// - Parameter message: The victory message to display
    public func playerWon(message: String) {
        gameOver(message: message, isVictory: true)
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
