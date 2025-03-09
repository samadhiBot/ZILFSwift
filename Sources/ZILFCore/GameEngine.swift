import Foundation

/// The main game engine for ZILF games.
///
/// Handles command processing, game state management, and core gameplay logic.
public class GameEngine {
    /// The game world containing rooms, objects, and the player
    public var world: GameWorld

    /// Command parser used to convert text input to game commands
    private var parser: CommandParser

    /// Flag indicating if the game engine is currently running
    private var isRunning = false

    /// Function that handles output text from the game
    private var outputHandler: (String) -> Void

    /// Stores the last command processed by the engine
    private var lastCommand: Command?

    /// Public accessor for the current command (the last processed command)
    public var currentCommand: Command? {
        return lastCommand
    }

    /// Flag indicating if the game has ended
    private(set) var isGameOver = false

    /// Message to display when the game ends
    private var gameOverMessage: String?

    /// Function that creates a new game world instance, used for game restarts
    private var worldCreator: (() -> GameWorld)?

    /// Initializes a new game engine with a game world
    ///
    /// - Parameters:
    ///   - world: The game world that contains all game objects and state
    ///   - outputHandler: Function that handles text output from the game
    ///   - worldCreator: Optional function that creates a new world instance for game restarts
    public init(
        world: GameWorld,
        outputHandler: @escaping (String) -> Void = { print($0) },
        worldCreator: (() -> GameWorld)? = nil
    ) {
        self.world = world
        self.parser = CommandParser(world: world)
        self.outputHandler = outputHandler
        self.worldCreator = worldCreator

        // Set engine directly on player using proper API instead of state dictionary
        world.player.setEngine(self)
    }

    // MARK: - Public Methods

    /// Executes a single game command
    ///
    /// - Parameter command: The command to execute
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
                beginCommandAction(currentRoom, command)
            {
                // The room's custom action handled the command
                advanceTime()
                return
            }

            // Commands allowed in darkness
            switch command {
            case .look, .inventory, .quit, .move, .take, .drop:
                // These commands are allowed in darkness
                break
            case .custom(let words) where words.count > 1:
                // Allow certain custom commands in darkness
                if words[0] == "wait" || words[0] == "again" || words[0] == "version" || words[0] == "save"
                    || words[0] == "restore" || words[0] == "restart" || words[0] == "undo" || words[0] == "brief"
                    || words[0] == "verbose" || words[0] == "superbrief"
                {
                    break
                } else {
                    outputHandler("It's too dark to see.")
                    return
                }
            case .wait, .again, .version, .save, .restore, .restart, .undo, .brief, .verbose, .superbrief:
                // These meta commands are allowed in darkness
                break
            default:
                outputHandler("It's too dark to see.")
                return
            }
        }

        // Check if the current room has a handler for this command
        if let beginCommandAction = currentRoom.beginCommandAction,
            beginCommandAction(currentRoom, command)
        {
            // The room's custom action handled the command
            advanceTime()
            return
        }

        // Check if the command involves an object that has a custom handler
        if let obj = getGameObject(from: command) {
            // Check if the object is accessible before attempting to process its command
            if isObjectAccessibleForExamine(obj) && obj.processCommand(command) {
                // The object handled the command
                advanceTime()
                return
            }
        }

        // Process the command with default handling
        switch command {
        case .look:
            handleLook()
        case .inventory:
            handleInventory()
        case .move:
            if let direction = extractDirectionFromCommand(command) {
                handleMove(direction: direction)
            } else {
                outputHandler("Which way do you want to go?")
            }
        case .take:
            if let obj = getObjectFromContext() {
                handleTake(obj)
            } else {
                outputHandler("Take what?")
            }
        case .drop:
            if let obj = getObjectFromContext() {
                handleDrop(obj)
            } else {
                outputHandler("Drop what?")
            }
        case .examine:
            if let obj = getObjectFromContext() {
                handleExamine(obj)
            } else {
                outputHandler("Examine what?")
            }
        case .open:
            if let obj = getObjectFromContext() {
                handleOpen(obj)
            } else {
                outputHandler("Open what?")
            }
        case .close:
            if let obj = getObjectFromContext() {
                handleClose(obj)
            } else {
                outputHandler("Close what?")
            }
        case .quit:
            handleQuit()
        case .unknown(let message):
            outputHandler(message)
        case .wear:
            if let obj = getObjectFromContext() {
                handleWear(obj)
            } else {
                outputHandler("Wear what?")
            }
        case .unwear:
            if let obj = getObjectFromContext() {
                handleUnwear(obj)
            } else {
                outputHandler("Take off what?")
            }
        case .putIn:
            if let objects = getMultipleGameObjects(from: command), objects.count >= 2 {
                handlePutIn(objects[0], container: objects[1])
            } else {
                outputHandler("You need to specify what to put where.")
            }
        case .putOn:
            if let objects = getMultipleGameObjects(from: command), objects.count >= 2 {
                handlePutOn(objects[0], surface: objects[1])
            } else {
                outputHandler("You need to specify what to put where.")
            }
        case .turnOn:
            if let obj = getObjectFromContext() {
                handleTurnOn(obj)
            } else {
                outputHandler("Turn on what?")
            }
        case .turnOff:
            if let obj = getObjectFromContext() {
                handleTurnOff(obj)
            } else {
                outputHandler("Turn off what?")
            }
        case .flip:
            if let obj = getObjectFromContext() {
                handleFlip(obj)
            } else {
                outputHandler("Flip what?")
            }
        case .wait:
            handleWait()
        case .again:
            handleAgain()
        case .read:
            if let obj = getObjectFromContext() {
                handleRead(obj)
            } else {
                outputHandler("Read what?")
            }
        case .custom(let words):
            if words.isEmpty {
                outputHandler("I don't understand.")
                return
            }

            switch words[0] {
            case "wear":
                if words.count > 1 {
                    if let obj = findObject(named: words[1]) {
                        handleWear(obj)
                    } else {
                        outputHandler("You don't see that here.")
                    }
                } else {
                    outputHandler("Wear what?")
                }
            case "unwear", "remove", "take_off":
                if words.count > 1 {
                    if let obj = findObject(named: words[1]) {
                        handleUnwear(obj)
                    } else {
                        outputHandler("You don't see that here.")
                    }
                } else {
                    outputHandler("Take off what?")
                }
            case "put_on", "place_on", "set_on":
                if words.count >= 3 {
                    if let obj = findObject(named: words[1]),
                       let surface = findObject(named: words[2]) {
                        handlePutOn(obj, surface: surface)
                    } else {
                        outputHandler("You don't see that here.")
                    }
                } else {
                    outputHandler("You need to specify what to put where.")
                }
            case "put_in":
                if words.count >= 3 {
                    if let obj = findObject(named: words[1]),
                       let container = findObject(named: words[2]) {
                        handlePutIn(obj, container: container)
                    } else {
                        outputHandler("You don't see that here.")
                    }
                } else {
                    outputHandler("You need to specify what to put where.")
                }
            case "turn_on":
                if words.count > 1 {
                    if let obj = findObject(named: words[1]) {
                        handleTurnOn(obj)
                    } else {
                        outputHandler("You don't see that here.")
                    }
                } else {
                    outputHandler("Turn on what?")
                }
            case "turn_off":
                if words.count > 1 {
                    if let obj = findObject(named: words[1]) {
                        handleTurnOff(obj)
                    } else {
                        outputHandler("You don't see that here.")
                    }
                } else {
                    outputHandler("Turn off what?")
                }
            case "flip", "switch", "toggle":
                if words.count > 1 {
                    if let obj = findObject(named: words[1]) {
                        handleFlip(obj)
                    } else {
                        outputHandler("You don't see that here.")
                    }
                } else {
                    outputHandler("Flip what?")
                }
            case "wait":
                handleWait()
            case "again":
                handleAgain()
            case "read", "peruse":
                if words.count > 1 {
                    if let obj = findObject(named: words[1]) {
                        handleRead(obj)
                    } else {
                        outputHandler("You don't see that here.")
                    }
                } else {
                    outputHandler("Read what?")
                }
            default:
                outputHandler("Sorry, that command isn't implemented yet.")
            }
        default:
            // Check if this is a direction command (move)
            if let direction = extractDirectionFromCommand(command) {
                handleMove(direction: direction)
            } else {
                outputHandler("I don't know how to do that.")
            }
        }

        // Only advance time for non-game verbs
        let verb = getVerbForCommand(command)
        if !isGameVerb(verb) {
            advanceTime()
        }
    }

    /// Execute the game loop - an alternative to start() that doesn't block
    ///
    /// - Parameter input: The command input string
    ///
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

    /// Handle Game Over - called when the game ends
    ///
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
            print("> ", terminator: "")  // Use print directly with terminator to fix cursor position
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

    /// Check if a character is in a dangerous situation that could lead to death
    ///
    /// - Returns: True if the player is in danger
    public func isPlayerInDanger() -> Bool {
        // Game-specific logic to determine if player is in danger
        // Example: Checking if player is in a room with an enemy or hazard
        return false
    }

    /// Kill the player, triggering game over
    ///
    /// - Parameter message: The death message to display
    public func playerDied(message: String) {
        gameOver(message: message, isVictory: false)
    }

    /// Player has won the game
    ///
    /// - Parameter message: The victory message to display
    public func playerWon(message: String) {
        gameOver(message: message, isVictory: true)
    }

    /// Starts the game and runs the main game loop
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
                print("> ", terminator: "")  // Use print directly with terminator to fix cursor position
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

            print("> ", terminator: "")  // Use print directly with terminator to fix cursor position
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

    // MARK: - Private Methods

    /// Advances game time by one turn
    /// This processes scheduled events and updates game state
    private func advanceTime() {
        // Process one turn of game actions and events
        let _ = world.waitTurns(1)
    }

    /// Executes the move direction component of a command
    ///
    /// - Parameter direction: The direction to move in
    private func executeMove(_ direction: Direction) {
        // Check if there's a special exit in this direction
        if let room = world.player.currentRoom,
            let specialExit = room.getSpecialExit(direction: direction)
        {

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
            world.player.moveTo(destination)

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

    /// Get the first game object from a command
    ///
    /// - Parameter command: The command to extract an object from
    ///
    /// - Returns: The first game object in the command or nil if none
    private func getGameObject(from command: Command) -> GameObject? {
        switch command {
        case .take, .drop, .examine, .open, .close:
            // In the new structure, these commands don't directly contain objects
            // We need to find the object using the CommandParser or context
            // For now, return nil as this would need a broader refactoring
            return nil
        case .custom(let words) where words.count > 1:
            // We'll need to find objects based on the words
            // This will require integration with the CommandParser
            // For now, return nil as this would need a broader refactoring
            return nil
        default:
            return nil
        }
    }

    /// Retrieve multiple game objects from a command
    ///
    /// - Parameter command: The command to extract objects from
    ///
    /// - Returns: Array of game objects or nil if none found
    private func getMultipleGameObjects(from command: Command) -> [GameObject]? {
        switch command {
        case .custom(let words) where words.count > 1:
            // This would require integration with the CommandParser to find objects
            // For now, return nil as this would need a broader refactoring
            return nil
        default:
            return nil
        }
    }

    /// Get the verb string for a command
    ///
    /// - Parameter command: The command to extract the verb from
    ///
    /// - Returns: String representation of the command's verb
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
        case .wear: return "wear"
        case .unwear: return "unwear"
        case .putIn: return "put_in"
        case .putOn: return "put_on"
        case .turnOn: return "turn_on"
        case .turnOff: return "turn_off"
        case .wait: return "wait"
        case .again: return "again"
        case .read: return "read"
        case .flip: return "flip"
        case .save: return "save"
        case .restore: return "restore"
        case .restart: return "restart"
        case .undo: return "undo"
        case .brief: return "brief"
        case .verbose: return "verbose"
        case .superbrief: return "superbrief"
        case .version: return "version"
        case .custom(let words) where !words.isEmpty:
            return words[0]
        case .custom:
            return "custom"
        default:
            // Extract the verb name from the enum case
            let mirror = Mirror(reflecting: command)
            let label = mirror.children.first?.label ?? String(describing: command)
            return label
        }
    }

    /// Extracts direction from a movement command
    ///
    /// - Parameter command: The command to extract direction from
    ///
    /// - Returns: Direction if available, nil otherwise
    private func extractDirectionFromCommand(_ command: Command) -> Direction? {
        switch command {
        case .move:
            // In the new Command structure, we need to get the direction from context
            // This would typically come from the CommandParser
            // For now, we'll return nil and need to enhance this
            return nil
        case .custom(let words):
            // Check if the custom command has a direction word
            guard !words.isEmpty else { return nil }

            // Convert common direction words to Direction
            switch words[0].lowercased() {
            case "north", "n": return .north
            case "south", "s": return .south
            case "east", "e": return .east
            case "west", "w": return .west
            case "northeast", "ne": return .northEast
            case "northwest", "nw": return .northWest
            case "southeast", "se": return .southEast
            case "southwest", "sw": return .southWest
            case "up", "u": return .up
            case "down", "d": return .down
            case "in", "inside": return .inward
            case "out", "outside": return .outward
            default: return nil
            }
        default:
            return nil
        }
    }

    /// Gets the current object from context
    ///
    /// - Returns: The object in the current context or nil
    private func getObjectFromContext() -> GameObject? {
        // This is a placeholder method that would normally use the CommandParser and
        // game state to figure out which object a command like "take" or "examine"
        // is referring to.

        // For now, we'll try to use the last mentioned object
        return world.lastMentionedObject
    }

    /// Get a list of visible exit directions from a room
    ///
    /// - Parameter room: The room to check
    ///
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
                specialExit.isVisible
            {
                exits.append(direction.rawValue)
            }
        }

        // Remove duplicates in case a direction has both regular and special exits
        return Array(Set(exits))
    }

    /// Handle AGAIN command (repeat last command)
    private func handleAgain() {
        if let lastCommand {
            outputHandler("(repeating the last command)")
            executeCommand(lastCommand)
        } else {
            outputHandler("There's no command to repeat.")
        }
    }

    /// Handle the CLOSE command
    ///
    /// - Parameter obj: The object to be closed
    private func handleClose(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.close) {
            // The object handled the close command
            return
        }

        // Default behavior
        // Check if object is openable
        if !obj.hasFlag(.isOpenable) {
            outputHandler("You can't close that.")
            return
        }

        // Check if already closed
        if !obj.hasFlag(.isOpen) {
            outputHandler("That's already closed.")
            return
        }

        // Close the object
        obj.clearFlag(.isOpen)
        outputHandler("Closed.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle custom commands based on verb and objects
    ///
    /// - Parameters:
    ///   - verb: The custom verb string
    ///   - objects: Array of game objects involved in the command
    ///   - additionalData: Optional string with extra command data
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

    /// Handle the DROP command
    ///
    /// - Parameter obj: The object to be dropped
    private func handleDrop(_ obj: GameObject) {
        // Check if the object has a custom handler for this command
        if obj.processCommand(.drop) {
            // The object handled the drop command
            return
        }

        // Default behavior
        // Check if player has the object
        if obj.location !== world.player {
            outputHandler("You're not carrying that.")
            return
        }

        // Drop the object in the current room
        if let room = world.player.currentRoom {
            obj.moveTo(room)
            outputHandler("Dropped.")

            // Update last mentioned object
            world.lastMentionedObject = obj
        } else {
            outputHandler("You have nowhere to drop that.")
        }
    }

    /// Handle the EXAMINE command
    ///
    /// - Parameter obj: The object to be examined
    private func handleExamine(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.examine) {
            // The object handled the examine command
            return
        }

        // Default behavior: Show the object's description
        outputHandler(obj.description)

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle FLIP command
    ///
    /// - Parameter obj: The device to be flipped (toggled)
    private func handleFlip(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.custom(["flip"])) {
            // The object handled the flip command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDevice) {
            outputHandler("That's not something you can flip.")
            return
        }

        if obj.hasFlag(.isOn) {
            obj.clearFlag(.isOn)
            outputHandler("You turn off \(obj.name).")
        } else {
            obj.setFlag(.isOn)
            outputHandler("You turn on \(obj.name).")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the INVENTORY command
    /// Displays a list of items the player is carrying
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

    /// Handle the LOOK command
    /// Shows the description of the player's current location
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

    /// Handle the MOVE command
    ///
    /// - Parameter direction: The direction to move in
    private func handleMove(direction: Direction) {
        let player = world.player

        // Check if the current room has a custom handler for this direction
        if let currentRoom = player.location as? Room,
            currentRoom.processCommand(.move)
        {
            // The room handled the move command
            return
        }

        if player.move(direction: direction) {
            // Player successfully moved, show the new room description
            handleLook()
        } else {
            outputHandler("You can't go that way.")
        }
    }

    /// Handle the OPEN command
    ///
    /// - Parameter obj: The object to be opened
    private func handleOpen(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.open) {
            // The object handled the open command
            return
        }

        // Default behavior
        // Check if object is openable
        if !obj.hasFlag(.isOpenable) {
            outputHandler("You can't open that.")
            return
        }

        // Check if already open
        if obj.hasFlag(.isOpen) {
            outputHandler("That's already open.")
            return
        }

        // Open the object
        obj.setFlag(.isOpen)
        outputHandler("Opened.")

        // If this is a container and it has contents, describe them
        if obj.hasFlags(.isContainer, .isTransparent) {
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

    /// Handle custom command: PUT ON (place something on a surface)
    ///
    /// - Parameters:
    ///   - obj: The object to be placed
    ///   - surface: The surface to place the object on
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
        if !surface.hasFlag(.isSurface) {
            outputHandler("You can't put anything on that.")
            return
        }

        // Put the object on the surface
        obj.moveTo(surface)
        outputHandler("You put the \(obj.name) on the \(surface.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle PUT_IN command
    ///
    /// - Parameters:
    ///   - obj: The object to put in the container
    ///   - container: The container to put the object in
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
        if !container.hasFlag(.isContainer) {
            outputHandler("You can't put anything in that.")
            return
        }

        // Check if container is open
        if !container.hasFlag(.isOpen) {
            outputHandler("The \(container.name) is closed.")
            return
        }

        // Put the object in the container
        obj.moveTo(container)
        outputHandler("You put the \(obj.name) in the \(container.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the QUIT command
    /// Ends the game
    private func handleQuit() {
        outputHandler("Thanks for playing!")
        isRunning = false
    }

    /// Handle READ command
    ///
    /// - Parameter obj: The object to be read
    private func handleRead(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.custom(["read"])) {
            // The object handled the read command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isReadable) {
            outputHandler("There's nothing to read on \(obj.name).")
            return
        }

        // Get the text from the object's state or use a default
        if let text: String = obj.getState(forKey: "text") {
            outputHandler(text)
        } else {
            outputHandler("You read \(obj.name).")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle restarting the game
    /// Resets the game world and starts a new game
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

    /// Handle the TAKE command
    ///
    /// - Parameter obj: The object to be taken
    private func handleTake(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.take) {
            // The object handled the take command
            return
        }

        // Default behavior
        // Check if object is already in inventory
        if obj.location === world.player {
            outputHandler("You're already carrying that.")
            return
        }

        // Check if object is takeable
        if !obj.hasFlag(.isTakable) {
            outputHandler("You can't take that.")
            return
        }

        // Take the object
        obj.moveTo(world.player)
        outputHandler("Taken.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle TURN OFF command
    ///
    /// - Parameter obj: The device to be turned off
    private func handleTurnOff(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.custom(["turn_off"])) {
            // The object handled the turn off command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDevice) {
            outputHandler("That's not something you can turn off.")
            return
        }

        if !obj.hasFlag(.isOn) {
            outputHandler("That's already off.")
            return
        }

        obj.clearFlag(.isOn)
        outputHandler("You turn off \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle TURN ON command
    ///
    /// - Parameter obj: The device to be turned on
    private func handleTurnOn(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.custom(["turn_on"])) {
            // The object handled the turn on command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDevice) {
            outputHandler("That's not something you can turn on.")
            return
        }

        if obj.hasFlag(.isOn) {
            outputHandler("That's already on.")
            return
        }

        obj.setFlag(.isOn)
        outputHandler("You turn on \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle UNWEAR command
    ///
    /// - Parameter obj: The object to be removed (unworn)
    private func handleUnwear(_ obj: GameObject) {
        // Check if the object is in the player's inventory
        if !obj.isIn(world.player) {
            outputHandler("You're not wearing \(obj.name).")
            return
        }

        // Check if the object is worn
        if !obj.hasFlag(.isBeingWorn) {
            outputHandler("You're not wearing \(obj.name).")
            return
        }

        // Unwear the object
        obj.clearFlag(.isBeingWorn)
        outputHandler("You take off \(obj.name).")
    }

    /// Handle WAIT command
    private func handleWait() {
        outputHandler("Time passes...")
    }

    /// Handle WEAR command
    ///
    /// - Parameter obj: The object to be worn
    private func handleWear(_ obj: GameObject) {
        // Check if the object is in the player's inventory
        if !obj.isIn(world.player) {
            outputHandler("You need to be holding \(obj.name) first.")
            return
        }

        // Check if the object is wearable
        if !obj.hasFlag(.isWearable) {
            outputHandler("You can't wear \(obj.name).")
            return
        }

        // Check if the object is already worn
        if obj.hasFlag(.isBeingWorn) {
            outputHandler("You're already wearing \(obj.name).")
            return
        }

        // Wear the object
        obj.setFlag(.isBeingWorn)
        outputHandler("You put on \(obj.name).")
    }

    /// Check if an object is accessible for examination
    ///
    /// - Parameter obj: The object to check
    ///
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

    /// Helper function to check if an object is visible to the player
    ///
    /// - Parameter obj: The object to check visibility of
    ///
    /// - Returns: True if the object is visible to the player
    private func isObjectVisible(_ obj: GameObject) -> Bool {
        // Check if object is in the current room or player's inventory
        if let room = world.player.currentRoom {
            if obj.isIn(room) || obj.isIn(world.player) {
                return true
            }

            // Check if object is in an open container in the room or inventory
            let containersInRoom = room.contents.filter {
                $0.hasFlags(.isContainer, .isOpen)
            }
            let containersInInventory = world.player.inventory.filter {
                $0.hasFlags(.isContainer, .isOpen)
            }

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

    /// Helper to check if a command is a "game verb" that doesn't advance time
    ///
    /// - Parameter verb: The verb to check
    ///
    /// - Returns: True if the verb is a game system command
    private func isGameVerb(_ verb: String) -> Bool {
        return verb == "save" || verb == "restore" || verb == "version" || verb == "quit"
            || verb == "undo" || verb == "restart" || verb == "brief" || verb == "verbose"
            || verb == "superbrief"
    }

    /// Displays a help message with available commands
    private func printHelp() {
        outputHandler(
            """
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

    /// Recreate the game world for restart
    ///
    /// - Returns: A fresh game world
    private func recreateWorld() -> GameWorld {
        if let worldCreator {
            let freshWorld = worldCreator()

            // Register the engine in the new world's player
            freshWorld.player.setEngine(self)

            return freshWorld
        } else {
            // Fall back to a simple new world if no creator function was provided
            let freshWorld = GameWorld(
                player: Player(startingRoom: Room(name: "Default", description: "Default room")))

            // Register the engine in the new world's player
            freshWorld.player.setEngine(self)

            return freshWorld
        }
    }

    /// Helper method to find objects by name
    ///
    /// - Parameter name: The name of the object to find
    ///
    /// - Returns: The found GameObject if it exists and is accessible
    private func findObject(named name: String) -> GameObject? {
        // Look in inventory
        if let obj = world.player.inventory.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return obj
        }

        // Look in current room
        if let room = world.player.currentRoom,
           let obj = room.contents.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return obj
        }

        // Look in open containers in the room
        if let room = world.player.currentRoom {
            let containers = room.contents.filter { $0.hasFlags(.isContainer, .isOpen) }
            for container in containers {
                if let obj = container.contents.first(where: { $0.name.lowercased() == name.lowercased() }) {
                    return obj
                }
            }
        }

        // Check if this is a global object accessible from the current room
        if let room = world.player.currentRoom {
            // Find global objects by name
            let globalObjects = world.globalObjects.filter { $0.isGlobalObject() }
            if let obj = globalObjects.first(where: { $0.name.lowercased() == name.lowercased() }),
               world.isGlobalObjectAccessible(obj, in: room) {
                return obj
            }
        }

        return nil
    }
}
