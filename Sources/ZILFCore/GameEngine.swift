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
            case .look, .inventory, .quit, .take, .drop, .move:
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

        // Process the command with default handling
        switch command {
        case .look:
            handleLook()

        case .inventory:
            handleInventory()

        case .move(let direction):
            if let direction = direction {
                handleMove(direction: direction)
            } else {
                outputHandler("Which way do you want to go?")
            }

        case .take(let obj):
            if let obj = obj {
                handleTake(obj)
            } else {
                outputHandler("Take what?")
            }

        case .drop(let obj):
            if let obj = obj {
                handleDrop(obj)
            } else {
                outputHandler("Drop what?")
            }

        case .examine(let obj):
            if let obj = obj {
                handleExamine(obj)
            } else {
                outputHandler("Examine what?")
            }

        case .open(let obj):
            if let obj = obj {
                handleOpen(obj)
            } else {
                outputHandler("Open what?")
            }

        case .close(let obj):
            if let obj = obj {
                handleClose(obj)
            } else {
                outputHandler("Close what?")
            }

        case .quit:
            handleQuit()

        case .unknown(let message):
            outputHandler(message)

        case .wear(let obj):
            if let obj = obj {
                handleWear(obj)
            } else {
                outputHandler("Wear what?")
            }

        case .unwear(let obj):
            if let obj = obj {
                handleUnwear(obj)
            } else {
                outputHandler("Take off what?")
            }

        case .putIn(let item, let container):
            if let item = item, let container = container {
                handlePutIn(item, container: container)
            } else {
                outputHandler("You need to specify what to put where.")
            }

        case .putOn(let item, let surface):
            if let item = item, let surface = surface {
                handlePutOn(item, surface: surface)
            } else {
                outputHandler("You need to specify what to put where.")
            }

        case .turnOn(let obj):
            if let obj = obj {
                handleTurnOn(obj)
            } else {
                outputHandler("Turn on what?")
            }

        case .turnOff(let obj):
            if let obj = obj {
                handleTurnOff(obj)
            } else {
                outputHandler("Turn off what?")
            }

        case .flip(let obj):
            if let obj = obj {
                handleFlip(obj)
            } else {
                outputHandler("Flip what?")
            }

        case .wait:
            handleWait()

        case .again:
            handleAgain()

        case .read(let obj):
            if let obj = obj {
                handleRead(obj)
            } else {
                outputHandler("Read what?")
            }

        case .attack(let obj):
            if let obj = obj {
                handleAttack(obj)
            } else {
                outputHandler("Attack what?")
            }

        case .burn(let obj):
            if let obj = obj {
                handleBurn(obj)
            } else {
                outputHandler("Burn what?")
            }

        case .climb(let obj):
            if let obj = obj {
                handleClimb(obj)
            } else {
                outputHandler("Climb what?")
            }

        case .drink(let obj):
            if let obj = obj {
                handleDrink(obj)
            } else {
                outputHandler("Drink what?")
            }

        case .eat(let obj):
            if let obj = obj {
                handleEat(obj)
            } else {
                outputHandler("Eat what?")
            }

        case .empty(let obj):
            if let obj = obj {
                handleEmpty(obj)
            } else {
                outputHandler("Empty what?")
            }

        case .fill(let obj):
            if let obj = obj {
                handleFill(obj)
            } else {
                outputHandler("Fill what?")
            }

        case .lock(let obj, let tool):
            if let obj = obj {
                handleLock(obj, with: tool)
            } else {
                outputHandler("Lock what?")
            }

        case .lookUnder(let obj):
            if let obj = obj {
                handleLookUnder(obj)
            } else {
                outputHandler("Look under what?")
            }

        case .pull(let obj):
            if let obj = obj {
                handlePull(obj)
            } else {
                outputHandler("Pull what?")
            }

        case .push(let obj):
            if let obj = obj {
                handlePush(obj)
            } else {
                outputHandler("Push what?")
            }

        case .remove(let obj):
            if let obj = obj {
                handleRemove(obj)
            } else {
                outputHandler("Remove what?")
            }

        case .rub(let obj):
            if let obj = obj {
                handleRub(obj)
            } else {
                outputHandler("Rub what?")
            }

        case .search(let obj):
            if let obj = obj {
                handleSearch(obj)
            } else {
                outputHandler("Search what?")
            }

        case .smell(let obj):
            if let obj = obj {
                handleSmell(obj)
            } else {
                outputHandler("Smell what?")
            }

        case .thinkAbout(let obj):
            if let obj = obj {
                handleThinkAbout(obj)
            } else {
                outputHandler("Think about what?")
            }

        case .throwAt(let item, let target):
            if let item = item, let target = target {
                handleThrowAt(item, target: target)
            } else {
                outputHandler("You need to specify what to throw and at what.")
            }

        case .unlock(let obj, let tool):
            if let obj = obj {
                handleUnlock(obj, with: tool)
            } else {
                outputHandler("Unlock what?")
            }

        case .wake(let obj):
            if let obj = obj {
                handleWake(obj)
            } else {
                outputHandler("Wake whom?")
            }

        case .wave(let obj):
            if let obj = obj {
                handleWave(obj)
            } else {
                outputHandler("Wave what?")
            }

        case .give(let item, let recipient):
            if let item = item, let recipient = recipient {
                handleGive(item, to: recipient)
            } else {
                outputHandler("You need to specify what to give and to whom.")
            }

        case .tell(let person, let topic):
            if let person = person, let topic = topic {
                handleTell(person, about: topic)
            } else {
                outputHandler("You need to specify whom to tell and about what.")
            }

        case .dance:
            handleDance()

        case .jump:
            handleJump()

        case .no:
            handleNo()

        case .pronouns:
            handlePronouns()

        case .sing:
            handleSing()

        case .swim:
            handleSwim()

        case .waveHands:
            handleWaveHands()

        case .yes:
            handleYes()

        case .brief, .verbose, .superbrief:
            handleDescriptionMode(command)

        case .save, .restore, .restart, .undo, .version, .help, .script, .unscript:
            handleGameCommand(command)

        case .custom(let words):
            handleCustomCommand(words)
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

    /// Handle AGAIN command (repeat last command)
    private func handleAgain() {
        if let lastCommand {
            outputHandler("(repeating the last command)")
            executeCommand(lastCommand)
        } else {
            outputHandler("There's no command to repeat.")
        }
    }

    /// Handle the ATTACK command
    private func handleAttack(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.attack(obj)) {
            // The object handled the attack command
            return
        }

        // Default behavior
        if obj.hasFlag(.isAttackable) {
            outputHandler("You attack the \(obj.name), but nothing happens.")
        } else {
            outputHandler("That wouldn't be helpful.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the BURN command
    private func handleBurn(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.burn(obj)) {
            // The object handled the burn command
            return
        }

        // Default behavior
        if obj.hasFlag(.isBurnable) {
            // Check if player has a light source
            let hasLightSource = world.player.inventory.contains { $0.hasFlags(.isLightSource, .isFlammable) }

            if hasLightSource {
                outputHandler("You burn the \(obj.name).")
                // Implement burning behavior (e.g., destroy object, transform it)
            } else {
                outputHandler("You don't have anything to light it with.")
            }
        } else {
            outputHandler("That's not something you can burn.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the CLIMB command
    private func handleClimb(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.climb(obj)) {
            // The object handled the climb command
            return
        }

        // Default behavior
        if obj.hasFlag(.isClimbable) {
            outputHandler("You climb the \(obj.name), but don't see anything interesting.")
        } else {
            outputHandler("You can't climb that.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
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

    /// Handle custom commands that aren't covered by other methods
    private func handleCustomCommand(_ words: [String]) {
        if words.isEmpty {
            outputHandler("I don't understand.")
            return
        }

        // Here you can add handling for specific custom commands
        outputHandler("Sorry, I don't know how to '\(words.joined(separator: " "))'.")
    }

    /// Handle the DANCE command
    private func handleDance() {
        outputHandler("You dance a little jig. Nobody's watching, fortunately.")
    }

    /// Handle description mode commands (brief/verbose/superbrief)
    private func handleDescriptionMode(_ command: Command) {
        switch command {
        case .brief:
            world.setBriefMode()
            outputHandler("Brief descriptions.")
        case .verbose:
            world.setVerboseMode()
            outputHandler("Verbose descriptions.")
        case .superbrief:
            world.useBriefDescriptions = true
            // Typically superbrief shows even less than brief
            outputHandler("Superbrief descriptions.")
        default:
            outputHandler("Unknown description mode.")
        }
    }

    /// Handle the DRINK command
    private func handleDrink(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.drink(obj)) {
            // The object handled the drink command
            return
        }

        // Default behavior
        if obj.hasFlag(.isDrinkable) {
            outputHandler("You drink the \(obj.name). It quenches your thirst.")
            // Implement drinking effects if needed
        } else {
            outputHandler("That's not something you can drink.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
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

    /// Handle the EAT command
    private func handleEat(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.eat(obj)) {
            // The object handled the eat command
            return
        }

        // Default behavior
        if obj.hasFlag(.isEdible) {
            outputHandler("You eat the \(obj.name). It was delicious!")
            // Remove the eaten object
            obj.moveTo(nil)
        } else {
            outputHandler("That's not something you can eat.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the EMPTY command
    private func handleEmpty(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.empty(obj)) {
            // The object handled the empty command
            return
        }

        // Default behavior
        if obj.hasFlag(.isContainer) {
            if obj.contents.isEmpty {
                outputHandler("The \(obj.name) is already empty.")
            } else {
                // Move all contents to the current room
                if let room = world.player.currentRoom {
                    for item in obj.contents {
                        item.moveTo(room)
                    }
                    outputHandler("You empty the \(obj.name).")
                } else {
                    outputHandler("You have nowhere to empty that.")
                }
            }
        } else {
            outputHandler("That's not something you can empty.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
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

        // If this is a container, also describe contents if it's open or transparent
        if obj.hasFlag(.isContainer) && (obj.hasFlag(.isOpen) || obj.hasFlag(.isTransparent)) {
            let contents = obj.contents
            if contents.isEmpty {
                outputHandler("The \(obj.name) is empty.")
            } else {
                outputHandler("The \(obj.name) contains:")
                for item in contents {
                    outputHandler("  \(item.name)")
                }
            }
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the FILL command
    private func handleFill(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.fill(obj)) {
            // The object handled the fill command
            return
        }

        // Default behavior - this is highly dependent on game context
        outputHandler("You can't fill that here.")

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
        if obj.processCommand(.flip(obj)) {
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

    /// Handle game meta-commands (save, restore, etc.)
    private func handleGameCommand(_ command: Command) {
        switch command {
        case .save:
            outputHandler("Game saved.")
            // Implement save functionality
        case .restore:
            outputHandler("Game restored.")
            // Implement restore functionality
        case .restart:
            handleRestart()
        case .undo:
            outputHandler("You can't change the past.")
            // Implement undo functionality
        case .version:
            outputHandler("ZILF Game Engine v1.0")
        case .help:
            printHelp()
        case .script:
            outputHandler("Transcript recording started.")
            // Implement script functionality
        case .unscript:
            outputHandler("Transcript recording stopped.")
            // Implement unscript functionality
        default:
            outputHandler("Unknown game command.")
        }
    }

    /// Handle GIVE command
    private func handleGive(_ item: GameObject, to recipient: GameObject) {
        // Check if player has the item
        if item.location !== world.player {
            outputHandler("You're not carrying that.")
            return
        }

        // Check if recipient is accessible
        if !isObjectAccessibleForExamine(recipient) {
            outputHandler("You don't see them here.")
            return
        }

        // Check if the recipient has a custom handler for this command
        if recipient.processCommand(.give(item: item, recipient: recipient)) {
            // The recipient handled the give command
            return
        }

        // Default behavior
        if recipient.hasFlag(.isPerson) {
            item.moveTo(recipient)
            outputHandler("You give the \(item.name) to the \(recipient.name).")
        } else {
            outputHandler("You can't give things to that.")
        }

        // Update last mentioned object
        world.lastMentionedObject = item
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
            case .look, .inventory, .quit, .take, .drop, .move:
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

        // Process the command with default handling
        switch command {
        case .look:
            handleLook()

        case .inventory:
            handleInventory()

        case .move(let direction):
            if let direction = direction {
                handleMove(direction: direction)
            } else {
                outputHandler("Which way do you want to go?")
            }

        case .take(let obj):
            if let obj = obj {
                handleTake(obj)
            } else {
                outputHandler("Take what?")
            }

        case .drop(let obj):
            if let obj = obj {
                handleDrop(obj)
            } else {
                outputHandler("Drop what?")
            }

        case .examine(let obj):
            if let obj = obj {
                handleExamine(obj)
            } else {
                outputHandler("Examine what?")
            }

        case .open(let obj):
            if let obj = obj {
                handleOpen(obj)
            } else {
                outputHandler("Open what?")
            }

        case .close(let obj):
            if let obj = obj {
                handleClose(obj)
            } else {
                outputHandler("Close what?")
            }

        case .quit:
            handleQuit()

        case .unknown(let message):
            outputHandler(message)

        case .wear(let obj):
            if let obj = obj {
                handleWear(obj)
            } else {
                outputHandler("Wear what?")
            }

        case .unwear(let obj):
            if let obj = obj {
                handleUnwear(obj)
            } else {
                outputHandler("Take off what?")
            }

        case .putIn(let item, let container):
            if let item = item, let container = container {
                handlePutIn(item, container: container)
            } else {
                outputHandler("You need to specify what to put where.")
            }

        case .putOn(let item, let surface):
            if let item = item, let surface = surface {
                handlePutOn(item, surface: surface)
            } else {
                outputHandler("You need to specify what to put where.")
            }

        case .turnOn(let obj):
            if let obj = obj {
                handleTurnOn(obj)
            } else {
                outputHandler("Turn on what?")
            }

        case .turnOff(let obj):
            if let obj = obj {
                handleTurnOff(obj)
            } else {
                outputHandler("Turn off what?")
            }

        case .flip(let obj):
            if let obj = obj {
                handleFlip(obj)
            } else {
                outputHandler("Flip what?")
            }

        case .wait:
            handleWait()

        case .again:
            handleAgain()

        case .read(let obj):
            if let obj = obj {
                handleRead(obj)
            } else {
                outputHandler("Read what?")
            }

        case .attack(let obj):
            if let obj = obj {
                handleAttack(obj)
            } else {
                outputHandler("Attack what?")
            }

        case .burn(let obj):
            if let obj = obj {
                handleBurn(obj)
            } else {
                outputHandler("Burn what?")
            }

        case .climb(let obj):
            if let obj = obj {
                handleClimb(obj)
            } else {
                outputHandler("Climb what?")
            }

        case .drink(let obj):
            if let obj = obj {
                handleDrink(obj)
            } else {
                outputHandler("Drink what?")
            }

        case .eat(let obj):
            if let obj = obj {
                handleEat(obj)
            } else {
                outputHandler("Eat what?")
            }

        case .empty(let obj):
            if let obj = obj {
                handleEmpty(obj)
            } else {
                outputHandler("Empty what?")
            }

        case .fill(let obj):
            if let obj = obj {
                handleFill(obj)
            } else {
                outputHandler("Fill what?")
            }

        case .lock(let obj, let tool):
            if let obj = obj {
                handleLock(obj, with: tool)
            } else {
                outputHandler("Lock what?")
            }

        case .lookUnder(let obj):
            if let obj = obj {
                handleLookUnder(obj)
            } else {
                outputHandler("Look under what?")
            }

        case .pull(let obj):
            if let obj = obj {
                handlePull(obj)
            } else {
                outputHandler("Pull what?")
            }

        case .push(let obj):
            if let obj = obj {
                handlePush(obj)
            } else {
                outputHandler("Push what?")
            }

        case .remove(let obj):
            if let obj = obj {
                handleRemove(obj)
            } else {
                outputHandler("Remove what?")
            }

        case .rub(let obj):
            if let obj = obj {
                handleRub(obj)
            } else {
                outputHandler("Rub what?")
            }

        case .search(let obj):
            if let obj = obj {
                handleSearch(obj)
            } else {
                outputHandler("Search what?")
            }

        case .smell(let obj):
            if let obj = obj {
                handleSmell(obj)
            } else {
                outputHandler("Smell what?")
            }

        case .thinkAbout(let obj):
            if let obj = obj {
                handleThinkAbout(obj)
            } else {
                outputHandler("Think about what?")
            }

        case .throwAt(let item, let target):
            if let item = item, let target = target {
                handleThrowAt(item, target: target)
            } else {
                outputHandler("You need to specify what to throw and at what.")
            }

        case .unlock(let obj, let tool):
            if let obj = obj {
                handleUnlock(obj, with: tool)
            } else {
                outputHandler("Unlock what?")
            }

        case .wake(let obj):
            if let obj = obj {
                handleWake(obj)
            } else {
                outputHandler("Wake whom?")
            }

        case .wave(let obj):
            if let obj = obj {
                handleWave(obj)
            } else {
                outputHandler("Wave what?")
            }

        case .give(let item, let recipient):
            if let item = item, let recipient = recipient {
                handleGive(item, to: recipient)
            } else {
                outputHandler("You need to specify what to give and to whom.")
            }

        case .tell(let person, let topic):
            if let person = person, let topic = topic {
                handleTell(person, about: topic)
            } else {
                outputHandler("You need to specify whom to tell and about what.")
            }

        case .dance:
            handleDance()

        case .jump:
            handleJump()

        case .no:
            handleNo()

        case .pronouns:
            handlePronouns()

        case .sing:
            handleSing()

        case .swim:
            handleSwim()

        case .waveHands:
            handleWaveHands()

        case .yes:
            handleYes()

        case .brief, .verbose, .superbrief:
            handleDescriptionMode(command)

        case .save, .restore, .restart, .undo, .version, .help, .script, .unscript:
            handleGameCommand(command)

        case .custom(let words):
            handleCustomCommand(words)
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

    /// Handle the INVENTORY command
    /// Displays a list of items the player is carrying
    private func handleInventory() {
        let items = world.player.inventory

        if items.isEmpty {
            outputHandler("You're not carrying anything.")
        } else {
            outputHandler("You are carrying:")
            for obj in items {
                let wornSuffix = obj.hasFlag(.isBeingWorn) ? " (being worn)" : ""
                outputHandler("  \(obj.name)\(wornSuffix)")
            }
        }
    }

    /// Handle the JUMP command
    private func handleJump() {
        outputHandler("You jump, but achieve nothing by doing so.")
    }

    /// Handle the LOCK command
    private func handleLock(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.lock(obj, with: tool)) {
            // The object handled the lock command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDoor) && !obj.hasFlag(.isContainer) {
            outputHandler("That's not something you can lock.")
            return
        }

        if obj.hasFlag(.isLocked) {
            outputHandler("That's already locked.")
            return
        }

        // Check if we have a tool
        if let tool = tool {
            // Check if player has the tool
            if tool.location !== world.player {
                outputHandler("You don't have the \(tool.name).")
                return
            }

            if tool.hasFlag(.isTool) {
                obj.setFlag(.isLocked)
                outputHandler("You lock the \(obj.name) with the \(tool.name).")
            } else {
                outputHandler("You can't lock anything with that.")
            }
        } else {
            outputHandler("You need something to lock it with.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
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

    /// Handle the LOOK UNDER command
    private func handleLookUnder(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.lookUnder(obj)) {
            // The object handled the look under command
            return
        }

        // Default behavior
        outputHandler("You find nothing interesting under the \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
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

    /// Handle the NO command
    private func handleNo() {
        outputHandler("Okay, you don't want to.")
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
        if !obj.hasFlag(.isOpenable) {
            outputHandler("You can't open that.")
            return
        }

        // Check if already open
        if obj.hasFlag(.isOpen) {
            outputHandler("That's already open.")
            return
        }

        // Check if locked
        if obj.hasFlag(.isLocked) {
            outputHandler("It's locked.")
            return
        }

        // Open the object
        obj.setFlag(.isOpen)
        outputHandler("Opened.")

        // If this is a container and it has contents, describe them
        if obj.hasFlag(.isContainer) {
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

    /// Handle the PRONOUNS command
    private func handlePronouns() {
        if let lastObj = world.lastMentionedObject {
            outputHandler("It: \(lastObj.name)")
        } else {
            outputHandler("No pronouns are defined yet.")
        }
    }

    /// Handle the PULL command
    private func handlePull(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.pull(obj)) {
            // The object handled the pull command
            return
        }

        // Default behavior
        outputHandler("Nothing happens when you pull the \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the PUSH command
    private func handlePush(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.push(obj)) {
            // The object handled the push command
            return
        }

        // Default behavior
        outputHandler("Nothing happens when you push the \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle custom command: PUT IN (place something in a container)
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

        // Check if the container has a custom handler for this command
        if container.processCommand(.putIn(item: obj, container: container)) {
            // The container handled the put in command
            return
        }

        // Default behavior
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

        // Check if the surface has a custom handler for this command
        if surface.processCommand(.putOn(item: obj, surface: surface)) {
            // The surface handled the put on command
            return
        }

        // Default behavior
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
        if obj.processCommand(.read(obj)) {
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

    /// Handle the REMOVE command
    private func handleRemove(_ obj: GameObject) {
        // For most games, REMOVE is an alias for UNWEAR
        handleUnwear(obj)
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

    /// Handle the RUB command
    private func handleRub(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.rub(obj)) {
            // The object handled the rub command
            return
        }

        // Default behavior
        outputHandler("Rubbing the \(obj.name) doesn't seem to do anything.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the SEARCH command
    private func handleSearch(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.search(obj)) {
            // The object handled the search command
            return
        }

        // Default behavior
        if obj.hasFlag(.isContainer) {
            // If container is open or transparent, show contents
            if obj.hasFlag(.isOpen) || obj.hasFlag(.isTransparent) {
                let contents = obj.contents
                if contents.isEmpty {
                    outputHandler("The \(obj.name) is empty.")
                } else {
                    outputHandler("Searching the \(obj.name) reveals:")
                    for item in contents {
                        outputHandler("  \(item.name)")
                    }
                }
            } else {
                outputHandler("The \(obj.name) is closed.")
            }
        } else {
            outputHandler("You find nothing of interest.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the SING command
    private func handleSing() {
        outputHandler("You sing a little tune. Your singing voice leaves something to be desired.")
    }

    /// Handle the SMELL command
    private func handleSmell(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.smell(obj)) {
            // The object handled the smell command
            return
        }

        // Default behavior
        outputHandler("The \(obj.name) smells normal.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the SWIM command
    private func handleSwim() {
        // Check if current location is water
        if let room = world.player.currentRoom {
            if room.hasFlag(.isWaterLocation) {
                outputHandler("You swim around for a while.")
            } else {
                outputHandler("There's no water here to swim in.")
            }
        }
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

    /// Handle the TELL command
    private func handleTell(_ person: GameObject, about topic: String) {
        // Check if the person is accessible
        if !isObjectAccessibleForExamine(person) {
            outputHandler("You don't see them here.")
            return
        }

        // Check if the person has a custom handler for this command
        if person.processCommand(.tell(person: person, topic: topic)) {
            // The person handled the tell command
            return
        }

        // Default behavior
        if person.hasFlag(.isPerson) {
            outputHandler("The \(person.name) doesn't seem interested in your comments about \(topic).")
        } else {
            outputHandler("You can't talk to that.")
        }

        // Update last mentioned object
        world.lastMentionedObject = person
    }

    /// Handle the THINK ABOUT command
    private func handleThinkAbout(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't know enough about that to think about it.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.thinkAbout(obj)) {
            // The object handled the think about command
            return
        }

        // Default behavior
        outputHandler("You think about the \(obj.name), but don't come to any conclusions.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the THROW AT command
    private func handleThrowAt(_ item: GameObject, target: GameObject) {
        // Check if player has the item
        if item.location !== world.player {
            outputHandler("You're not carrying that.")
            return
        }

        // Check if target is accessible
        if !isObjectAccessibleForExamine(target) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the target has a custom handler for this command
        if target.processCommand(.throwAt(item: item, target: target)) {
            // The target handled the throw at command
            return
        }

        // Default behavior
        outputHandler("You throw the \(item.name) at the \(target.name), but nothing interesting happens.")

        // Drop the item in the current room
        if let room = world.player.currentRoom {
            item.moveTo(room)
        }

        // Update last mentioned object
        world.lastMentionedObject = item
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
        if obj.processCommand(.turnOff(obj)) {
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
        if obj.processCommand(.turnOn(obj)) {
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

    /// Handle the UNLOCK command
    private func handleUnlock(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.unlock(obj, with: tool)) {
            // The object handled the unlock command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDoor) && !obj.hasFlag(.isContainer) {
            outputHandler("That's not something you can unlock.")
            return
        }

        if !obj.hasFlag(.isLocked) {
            outputHandler("That's already unlocked.")
            return
        }

        // Check if we have a tool
        if let tool = tool {
            // Check if player has the tool
            if tool.location !== world.player {
                outputHandler("You don't have the \(tool.name).")
                return
            }

            if tool.hasFlag(.isTool) {
                obj.clearFlag(.isLocked)
                outputHandler("You unlock the \(obj.name) with the \(tool.name).")
            } else {
                outputHandler("You can't unlock anything with that.")
            }
        } else {
            outputHandler("You need something to unlock it with.")
        }

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

        // Check if the object has a custom handler for this command
        if obj.processCommand(.unwear(obj)) {
            // The object handled the unwear command
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

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle WAIT command
    private func handleWait() {
        outputHandler("Time passes...")
    }

    /// Handle the WAKE command
    private func handleWake(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            outputHandler("You don't see them here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.wake(obj)) {
            // The object handled the wake command
            return
        }

        // Default behavior
        if obj.hasFlag(.isPerson) {
            outputHandler("The \(obj.name) is already awake.")
        } else {
            outputHandler("That doesn't make any sense.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the WAVE command
    private func handleWave(_ obj: GameObject) {
        // Check if the object is accessible (needs to be in inventory to wave)
        if obj.location !== world.player {
            outputHandler("You need to be holding that to wave it.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.wave(obj)) {
            // The object handled the wave command
            return
        }

        // Default behavior
        outputHandler("You wave the \(obj.name) around, but nothing happens.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the WAVE HANDS command
    private func handleWaveHands() {
        outputHandler("You wave your hands in the air, but nothing happens.")
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

        // Check if the object has a custom handler for this command
        if obj.processCommand(.wear(obj)) {
            // The object handled the wear command
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

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the YES command
    private func handleYes() {
        outputHandler("Nothing happens.")
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
                $0.hasFlags(.isContainer, .isOpen) || $0.hasFlag(.isTransparent)
            }
            let containersInInventory = world.player.inventory.filter {
                $0.hasFlags(.isContainer, .isOpen) || $0.hasFlag(.isTransparent)
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
        || verb == "superbrief" || verb == "help" || verb == "script" || verb == "unscript"
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
