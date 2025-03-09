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
            case .customCommand(let verb, _, _):
                // Allow certain custom commands in darkness
                if verb == "wait" || verb == "again" || verb == "version" || verb == "save"
                    || verb == "restore" || verb == "restart" || verb == "undo" || verb == "brief"
                    || verb == "verbose" || verb == "superbrief"
                {
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
        case .take(let obj), .drop(let obj), .examine(let obj), .open(let obj), .close(let obj):
            return obj
        case .customCommand(_, let objects, _):
            return objects.first
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
        case .customCommand(_, let objects, _):
            return objects.isEmpty ? nil : objects
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
        case .customCommand(let verb, _, _): return verb
        }
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
        if obj.processCommand(.close(obj)) {
            // The object handled the close command
            return
        }

        // Default behavior
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
        if obj.processCommand(.drop(obj)) {
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
        if obj.processCommand(.examine(obj)) {
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
        if obj.processCommand(.customCommand("flip", [obj], additionalData: nil)) {
            // The object handled the flip command
            return
        }

        // Default behavior
        if !obj.hasFlag(String.deviceBit) {
            outputHandler("That's not something you can flip.")
            return
        }

        if obj.hasFlag(String.onBit) {
            obj.clearFlag(String.onBit)
            outputHandler("You turn off \(obj.name).")
        } else {
            obj.setFlag(String.onBit)
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
            currentRoom.processCommand(.move(direction))
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
        if obj.processCommand(.open(obj)) {
            // The object handled the open command
            return
        }

        // Default behavior
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
        if !surface.hasFlag(.surfaceBit) {
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
        if !container.isOpen() {
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
        if obj.processCommand(.customCommand("read", [obj], additionalData: nil)) {
            // The object handled the read command
            return
        }

        // Default behavior
        if !obj.hasFlag(String.readBit) {
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
        if obj.processCommand(.take(obj)) {
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
        if !obj.isTakeable() {
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
        if obj.processCommand(.customCommand("turn_off", [obj], additionalData: nil)) {
            // The object handled the turn off command
            return
        }

        // Default behavior
        if !obj.hasFlag(String.deviceBit) {
            outputHandler("That's not something you can turn off.")
            return
        }

        if !obj.hasFlag(String.onBit) {
            outputHandler("That's already off.")
            return
        }

        obj.clearFlag(String.onBit)
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
        if obj.processCommand(.customCommand("turn_on", [obj], additionalData: nil)) {
            // The object handled the turn on command
            return
        }

        // Default behavior
        if !obj.hasFlag(String.deviceBit) {
            outputHandler("That's not something you can turn on.")
            return
        }

        if obj.hasFlag(String.onBit) {
            outputHandler("That's already on.")
            return
        }

        obj.setFlag(String.onBit)
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
        if !obj.hasFlag(String.wornBit) {
            outputHandler("You're not wearing \(obj.name).")
            return
        }

        // Unwear the object
        obj.clearFlag(String.wornBit)
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
}
