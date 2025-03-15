import Foundation

/// The main game engine for ZILF games.
///
/// Handles command processing, game state management, and core gameplay logic.
@MainActor
public class GameEngine {
    /// The game world containing rooms, objects, and the player
    public var world: GameWorld

    /// Command parser used to convert text input to game commands
    private var parser: CommandParser

    /// Flag indicating if the game engine is currently running
    private var isRunning = false

    /// Output manager for handling game output and input
    private var outputManager: OutputManager

    /// Player's current score
    public private(set) var score: Int = 0

    /// Count of moves made in the game
    public private(set) var moveCount: Int = 0

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

    /// Introductory text to display when the game starts
    private var welcomeMessage: String?

    /// Version information to display at startup
    private var gameVersion: String?

    /// Function that creates a new game world instance, used for game restarts
    private var worldCreator: (() throws -> GameWorld)?

    /// Initializes a new game engine with a game world
    ///
    /// - Parameters:
    ///   - world: The game world that contains all game objects and state
    ///   - outputManager: Manager for handling game output and input
    ///   - worldCreator: Optional function that creates a new world instance for game restarts
    ///   - welcomeMessage: Optional introductory text to display when the game starts
    ///   - gameVersion: Optional version information to display at startup
    public init(
        world: GameWorld,
        outputManager: OutputManager = StandardOutputManager(),
        worldCreator: (() throws -> GameWorld)? = nil,
        welcomeMessage: String? = nil,
        gameVersion: String? = nil
    ) {
        self.world = world
        self.parser = CommandParser(world: world)
        self.outputManager = outputManager
        self.worldCreator = worldCreator
        self.welcomeMessage = welcomeMessage
        self.gameVersion = gameVersion

        // Set engine directly on player using proper API instead of state dictionary
        world.player.setEngine(self)

        // Set up global output to route through this engine
        setGlobalOutput { [weak self] message in
            self?.output(message)
        }
    }

    /// Outputs a message to the game's output
    public func output(_ message: String) {
        outputManager.output(message)
    }

    /// Gets input from the player
    public func getInput(prompt: String = "> ") -> String? {
        return outputManager.getInput(prompt: prompt)
    }

    /// Handle terminal resize event
    public func handleTerminalResize() {
        if let termManager = outputManager as? TerminalOutputManager {
            termManager.handleResize()

            // Update status line
            let locationName = world.player.currentRoom?.name ?? "Unknown"
            outputManager.updateStatusLine(location: locationName, score: score, moves: moveCount)
        }
    }

    // MARK: - Public Methods

    /// Executes a single game command
    ///
    /// - Parameter command: The command to execute
    public func executeCommand(_ command: Command) throws {
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
            output("Error: Player has no current room!")
            return
        }

        let isRoomDark = !currentRoom.isLit()

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
                    output("It's too dark to see.")
                    return
                }
            case .wait, .again, .version, .save, .restore, .restart, .undo, .brief, .verbose, .superbrief:
                // These meta commands are allowed in darkness
                break
            default:
                output("It's too dark to see.")
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
            if let direction {
                handleMove(direction: direction)
            } else {
                output("Which way do you want to go?")
            }

        case .take(let obj):
            if let obj {
                handleTake(obj)
            } else {
                output("Take what?")
            }

        case .drop(let obj):
            if let obj {
                handleDrop(obj)
            } else {
                output("Drop what?")
            }

        case .examine(let obj, let tool):
            if let obj {
                handleExamine(obj, with: tool)
            } else {
                output("Examine what?")
            }

        case .open(let obj, let tool):
            if let obj {
                handleOpen(obj, with: tool)
            } else {
                output("Open what?")
            }

        case .close(let obj):
            if let obj {
                handleClose(obj)
            } else {
                output("Close what?")
            }

        case .quit:
            handleQuit()

        case .unknown(let message):
            output(message)

        case .wear(let obj):
            if let obj {
                handleWear(obj)
            } else {
                output("Wear what?")
            }

        case .unwear(let obj):
            if let obj {
                handleUnwear(obj)
            } else {
                output("Take off what?")
            }

        case .putIn(let item, let container):
            if let item, let container {
                handlePutIn(item, container: container)
            } else {
                output("You need to specify what to put where.")
            }

        case .putOn(let item, let surface):
            if let item, let surface {
                handlePutOn(item, surface: surface)
            } else {
                output("You need to specify what to put where.")
            }

        case .turnOn(let obj):
            if let obj {
                handleTurnOn(obj)
            } else {
                output("Turn on what?")
            }

        case .turnOff(let obj):
            if let obj {
                handleTurnOff(obj)
            } else {
                output("Turn off what?")
            }

        case .flip(let obj):
            if let obj {
                handleFlip(obj)
            } else {
                output("Flip what?")
            }

        case .wait:
            handleWait()

        case .again:
            try handleAgain()

        case .read(let obj, let tool):
            if let obj {
                handleRead(obj, with: tool)
            } else {
                output("Read what?")
            }

        case .attack(let obj, let tool):
            if let obj {
                handleAttack(obj, with: tool)
            } else {
                output("Attack what?")
            }

        case .burn(let obj, let tool):
            if let obj {
                handleBurn(obj, with: tool)
            } else {
                output("Burn what?")
            }

        case .climb(let obj):
            if let obj {
                handleClimb(obj)
            } else {
                output("Climb what?")
            }

        case .drink(let obj):
            if let obj {
                handleDrink(obj)
            } else {
                output("Drink what?")
            }

        case .eat(let obj):
            if let obj {
                handleEat(obj)
            } else {
                output("Eat what?")
            }

        case .empty(let obj):
            if let obj {
                handleEmpty(obj)
            } else {
                output("Empty what?")
            }

        case .fill(let obj):
            if let obj {
                handleFill(obj)
            } else {
                output("Fill what?")
            }

        case .lock(let obj, let tool):
            if let obj {
                handleLock(obj, with: tool)
            } else {
                output("Lock what?")
            }

        case .lookUnder(let obj):
            if let obj {
                handleLookUnder(obj)
            } else {
                output("Look under what?")
            }

        case .pull(let obj):
            if let obj {
                handlePull(obj)
            } else {
                output("Pull what?")
            }

        case .push(let obj):
            if let obj {
                handlePush(obj)
            } else {
                output("Push what?")
            }

        case .remove(let obj):
            if let obj {
                handleRemove(obj)
            } else {
                output("Remove what?")
            }

        case .rub(let obj, let tool):
            if let obj {
                handleRub(obj, with: tool)
            } else {
                output("Rub what?")
            }

        case .search(let obj):
            if let obj {
                handleSearch(obj)
            } else {
                output("Search what?")
            }

        case .smell(let obj):
            if let obj {
                handleSmell(obj)
            } else {
                output("Smell what?")
            }

        case .thinkAbout(let obj):
            if let obj {
                handleThinkAbout(obj)
            } else {
                output("Think about what?")
            }

        case .throwAt(let item, let target):
            if let item, let target {
                handleThrowAt(item, target: target)
            } else {
                output("You need to specify what to throw and at what.")
            }

        case .unlock(let obj, let tool):
            if let obj {
                handleUnlock(obj, with: tool)
            } else {
                output("Unlock what?")
            }

        case .wake(let obj):
            if let obj {
                handleWake(obj)
            } else {
                output("Wake whom?")
            }

        case .wave(let obj):
            if let obj {
                handleWave(obj)
            } else {
                output("Wave what?")
            }

        case .give(let item, let recipient):
            if let item, let recipient {
                handleGive(item, to: recipient)
            } else {
                output("You need to specify what to give and to whom.")
            }

        case .tell(let person, let topic):
            if let person, let topic {
                handleTell(person, about: topic)
            } else {
                output("You need to specify whom to tell and about what.")
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
            try handleGameCommand(command)

        case .custom(let words):
            handleCustomCommand(words)
        }

        // Only advance time for non-game verbs
        let verb = getVerbForCommand(command)
        if !isGameVerb(verb) {
            advanceTime()
        }

        // After executing any command, update the status line
        let locationName = world.player.currentRoom?.name ?? "Unknown"
        outputManager.updateStatusLine(location: locationName, score: score, moves: moveCount)
    }

    /// Execute the game loop - an alternative to start() that doesn't block
    ///
    /// - Parameter input: The command input string
    ///
    /// - Returns: True if the game is still running, false if it ended
    public func executeGameLoop(input: String) throws -> Bool {
        if !isRunning || isGameOver {
            return false
        }

        if input.lowercased() == "help" {
            printHelp()
        } else {
            let command = parser.parse(input)
            try executeCommand(command)

            // Check for game over after command execution
            if isGameOver {
                return false
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
        output("\n*** \(isVictory ? "VICTORY" : "GAME OVER") ***")
        output(message)

        // Prompt for restart or quit
        output("\nWould you like to RESTART or QUIT?")

        // Handle the player's choice will be managed separately in the game loop
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
    public func start() throws {
        isRunning = true
        isGameOver = false

        // Display welcome message if provided
        if let welcomeMessage = welcomeMessage {
            output(welcomeMessage)
        } else {
            output("Welcome to the Text Adventure!")
        }

        // Display version information if provided
        if let gameVersion = gameVersion {
            output(gameVersion)
        }

        output("Type 'help' for a list of commands.\n")

        // Start with a look at the current room
        try executeCommand(.look)

        // Update status line with initial information
        let locationName = world.player.currentRoom?.name ?? "Unknown"
        outputManager.updateStatusLine(location: locationName, score: score, moves: moveCount)

        // Main game loop
        while isRunning {
            if isGameOver {
                // If game is over, only accept restart or quit commands
                guard let input = getInput()?.lowercased() else { continue }

                switch input {
                case "restart":
                    try handleRestart()
                case "quit":
                    handleQuit()
                    break
                default:
                    output("Please type RESTART or QUIT.")
                }
                continue
            }

            guard let input = getInput() else { continue }

            if input.lowercased() == "help" {
                printHelp()
                continue
            }

            let command = parser.parse(input)
            try executeCommand(command)
        }

        // Clean up resources
        outputManager.shutdown()
    }

    /// Updates the player's score
    ///
    /// - Parameter points: The number of points to add to the score
    /// - Parameter notify: Whether to notify the player about the score change
    public func updateScore(points: Int, notify: Bool = true) {
        if points <= 0 {
            return
        }

        score += points

        if notify {
            output("[Your score just went up by \(points) point\(points == 1 ? "" : "s").]")
        }
    }

    // MARK: - Private Methods

    /// Advances game time by one turn
    /// This processes scheduled events and updates game state
    private func advanceTime() {
        // Process one turn of game actions and events
        let _ = world.waitTurns(1)

        // Increment move count
        moveCount += 1
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
    private func handleAgain() throws {
        if let lastCommand {
            output("(repeating the last command)")
            try executeCommand(lastCommand)
        } else {
            output("There's no command to repeat.")
        }
    }

    /// Handle the ATTACK command
    ///
    /// - Parameters:
    ///   - obj: The object to be attacked
    ///   - tool: The tool to attack with (optional)
    private func handleAttack(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the tool is accessible
        if let tool = tool, !isObjectAccessibleForExamine(tool) {
            output("You don't have the \(tool.name).")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.attack(obj, with: tool)) {
            // The object handled the attack command
            return
        }

        // Default behavior
        if obj.hasFlag(.isAttackable) {
            if let tool = tool {
                if tool.hasFlag(.isWeapon) {
                    output("You attack the \(obj.name) with the \(tool.name), but nothing happens.")
                } else {
                    output("The \(tool.name) isn't an effective weapon.")
                }
            } else {
                output("You attack the \(obj.name), but nothing happens.")
            }
        } else {
            output("That wouldn't be helpful.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the BURN command
    ///
    /// - Parameters:
    ///   - obj: The object to be burned
    ///   - tool: The tool to burn with (optional)
    private func handleBurn(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the tool is accessible
        if let tool = tool, !isObjectAccessibleForExamine(tool) {
            output("You don't have the \(tool.name).")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.burn(obj, with: tool)) {
            // The object handled the burn command
            return
        }

        // Default behavior
        if obj.hasFlag(.isBurnable) {
            let hasValidTool = tool?.hasFlag(.isFlammable) ?? false

            // Check if player has a light source if no tool is provided
            let hasLightSource = tool?.hasFlag(.isFlammable) ??
                world.player.inventory.contains { $0.hasFlags(.isLightSource, .isFlammable) }

            if hasValidTool || hasLightSource {
                if let tool = tool {
                    output("You burn the \(obj.name) with the \(tool.name).")
                } else {
                    output("You burn the \(obj.name).")
                }
                // Implement burning behavior (e.g., destroy object, transform it)
            } else {
                output("You don't have anything to light it with.")
            }
        } else {
            output("That's not something you can burn.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the CLIMB command
    private func handleClimb(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.climb(obj)) {
            // The object handled the climb command
            return
        }

        // Default behavior
        if obj.hasFlag(.isClimbable) {
            output("You climb the \(obj.name), but don't see anything interesting.")
        } else {
            output("You can't climb that.")
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
            output("You don't see that here.")
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
            output("You can't close that.")
            return
        }

        // Check if already closed
        if !obj.hasFlag(.isOpen) {
            output("That's already closed.")
            return
        }

        // Close the object
        obj.clearFlag(.isOpen)
        output("Closed.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle custom commands that aren't covered by other methods
    private func handleCustomCommand(_ words: [String]) {
        if words.isEmpty {
            output("I don't understand.")
            return
        }

        // Here you can add handling for specific custom commands
        output("Sorry, I don't know how to '\(words.joined(separator: " "))'.")
    }

    /// Handle the DANCE command
    private func handleDance() {
        output("You dance a little jig. Nobody's watching, fortunately.")
    }

    /// Handle description mode commands (brief/verbose/superbrief)
    private func handleDescriptionMode(_ command: Command) {
        switch command {
        case .brief:
            world.setBriefMode()
            output("Brief descriptions.")
        case .verbose:
            world.setVerboseMode()
            output("Verbose descriptions.")
        case .superbrief:
            world.useBriefDescriptions = true
            // Typically superbrief shows even less than brief
            output("Superbrief descriptions.")
        default:
            output("Unknown description mode.")
        }
    }

    /// Handle the DRINK command
    private func handleDrink(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.drink(obj)) {
            // The object handled the drink command
            return
        }

        // Default behavior
        if obj.hasFlag(.isDrinkable) {
            output("You drink the \(obj.name). It quenches your thirst.")
            // Implement drinking effects if needed
        } else {
            output("That's not something you can drink.")
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
            output("You're not carrying that.")
            return
        }

        // Drop the object in the current room
        if let room = world.player.currentRoom {
            obj.moveTo(room)
            output("Dropped.")

            // Update last mentioned object
            world.lastMentionedObject = obj
        } else {
            output("You have nowhere to drop that.")
        }
    }

    /// Handle the EAT command
    private func handleEat(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.eat(obj)) {
            // The object handled the eat command
            return
        }

        // Default behavior
        if obj.hasFlag(.isEdible) {
            output("You eat the \(obj.name). It was delicious!")
            // Remove the eaten object
            obj.moveTo(nil)
        } else {
            output("That's not something you can eat.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the EMPTY command
    private func handleEmpty(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
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
                output("The \(obj.name) is already empty.")
            } else {
                // Move all contents to the current room
                if let room = world.player.currentRoom {
                    for item in obj.contents {
                        item.moveTo(room)
                    }
                    output("You empty the \(obj.name).")
                } else {
                    output("You have nowhere to empty that.")
                }
            }
        } else {
            output("That's not something you can empty.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the EXAMINE command
    ///
    /// - Parameters:
    ///   - obj: The object to be examined
    ///   - tool: Optional tool to examine with (like a magnifying glass)
    private func handleExamine(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the tool is accessible
        if let tool = tool, !isObjectAccessibleForExamine(tool) {
            output("You don't have the \(tool.name).")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.examine(obj, with: tool)) {
            // The object handled the examine command
            return
        }

        // Default behavior: Show the object's description
        output(obj.description)

        // If examining with a tool, potentially provide additional details
        if let tool = tool {
            // Check if this is a special examination tool (e.g., magnifying glass)
            let isExaminationTool: Bool = tool.getState(forKey: "is_examination_tool") ?? false

            if isExaminationTool {
                // Get special examination text if available
                if let detailedText: String = obj.getState(forKey: "detailed_description") {
                    output("Using the \(tool.name), you can see: \(detailedText)")
                } else {
                    output("You examine the \(obj.name) carefully with the \(tool.name), but notice nothing special.")
                }
            } else {
                output("The \(tool.name) doesn't help you examine the \(obj.name) any better.")
            }
        }

        // If this is a container, also describe contents if it's open or transparent
        if obj.hasFlag(.isContainer) && (obj.hasFlag(.isOpen) || obj.hasFlag(.isTransparent)) {
            let contents = obj.contents
            if contents.isEmpty {
                output("The \(obj.name) is empty.")
            } else {
                output("The \(obj.name) contains:")
                for item in contents {
                    output("  \(item.name)")
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
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.fill(obj)) {
            // The object handled the fill command
            return
        }

        // Default behavior - this is highly dependent on game context
        output("You can't fill that here.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle FLIP command
    ///
    /// - Parameter obj: The device to be flipped (toggled)
    private func handleFlip(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.flip(obj)) {
            // The object handled the flip command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDevice) {
            output("That's not something you can flip.")
            return
        }

        if obj.hasFlag(.isOn) {
            obj.clearFlag(.isOn)
            output("You turn off \(obj.name).")
        } else {
            obj.setFlag(.isOn)
            output("You turn on \(obj.name).")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle game meta-commands (save, restore, etc.)
    private func handleGameCommand(_ command: Command) throws {
        switch command {
        case .save:
            output("Game saved.")
            // Implement save functionality
        case .restore:
            output("Game restored.")
            // Implement restore functionality
        case .restart:
            try handleRestart()
        case .undo:
            output("You can't change the past.")
            // Implement undo functionality
        case .version:
            if let gameVersion = gameVersion {
                output(gameVersion)
            } else {
                output("ZILF Game Engine v1.0")
            }
        case .help:
            printHelp()
        case .script:
            output("Transcript recording started.")
            // Implement script functionality
        case .unscript:
            output("Transcript recording stopped.")
            // Implement unscript functionality
        default:
            output("Unknown game command.")
        }
    }

    /// Handle GIVE command
    private func handleGive(_ item: GameObject, to recipient: GameObject) {
        // Check if player has the item
        if item.location !== world.player {
            output("You're not carrying that.")
            return
        }

        // Check if recipient is accessible
        if !isObjectAccessibleForExamine(recipient) {
            output("You don't see them here.")
            return
        }

        // Check if the recipient has a custom handler for this command
        if recipient.processCommand(.give(item, to: recipient)) {
            // The recipient handled the give command
            return
        }

        // Default behavior
        if recipient.hasFlag(.isPerson) {
            item.moveTo(recipient)
            output("You give the \(item.name) to the \(recipient.name).")
        } else {
            output("You can't give things to that.")
        }

        // Update last mentioned object
        world.lastMentionedObject = item
    }

    /// Handle the INVENTORY command
    /// Displays a list of items the player is carrying
    private func handleInventory() {
        let items = world.player.inventory

        if items.isEmpty {
            output("You're not carrying anything.")
        } else {
            output("You are carrying:")
            for obj in items {
                let wornSuffix = obj.hasFlag(.isBeingWorn) ? " (being worn)" : ""
                output("  \(obj.name)\(wornSuffix)")
            }
        }
    }

    /// Handle the JUMP command
    private func handleJump() {
        output("You jump, but achieve nothing by doing so.")
    }

    /// Handle the LOCK command
    private func handleLock(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.lock(obj, with: tool)) {
            // The object handled the lock command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDoor) && !obj.hasFlag(.isContainer) {
            output("That's not something you can lock.")
            return
        }

        if obj.hasFlag(.isLocked) {
            output("That's already locked.")
            return
        }

        // Check if we have a tool
        if let tool = tool {
            // Check if player has the tool
            if tool.location !== world.player {
                output("You don't have the \(tool.name).")
                return
            }

            if tool.hasFlag(.isTool) {
                obj.setFlag(.isLocked)
                output("You lock the \(obj.name) with the \(tool.name).")
                obj.setFlag(.isOpen)
            } else {
                output("You can't lock anything with that.")
            }
        } else {
            output("You need something to lock it with.")
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
                output(roomDescription)
            }
        }
    }

    /// Handle the LOOK UNDER command
    private func handleLookUnder(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.lookUnder(obj)) {
            // The object handled the look under command
            return
        }

        // Default behavior
        output("You find nothing interesting under the \(obj.name).")

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
            output("You can't go that way.")
        }
    }

    /// Handle the NO command
    private func handleNo() {
        output("Okay, you don't want to.")
    }

    /// Handle the OPEN command
    ///
    /// - Parameters:
    ///   - obj: The object to be opened
    ///   - tool: The tool to open with (optional)
    private func handleOpen(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the tool is accessible
        if let tool = tool, !isObjectAccessibleForExamine(tool) {
            output("You don't have the \(tool.name).")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.open(obj, with: tool)) {
            // The object handled the open command
            return
        }

        // Default behavior
        // Check if object is openable
        if !obj.hasFlag(.isOpenable) {
            output("You can't open that.")
            return
        }

        // Check if already open
        if obj.hasFlag(.isOpen) {
            output("That's already open.")
            return
        }

        // Check if locked
        if obj.hasFlag(.isLocked) {
            // See if tool can unlock it
            if let tool = tool {
                // Check if this tool functions as a key
                let isKey: Bool = tool.getState(forKey: "is_key") ?? false
                if isKey {
                    // Check if this is the right key
                    let keyId: String = tool.getState(forKey: "key_id") ?? ""
                    let lockId: String = obj.getState(forKey: "lock_id") ?? ""

                    if !keyId.isEmpty && keyId == lockId {
                        obj.clearFlag(.isLocked)
                        output("You unlock the \(obj.name) with the \(tool.name) and open it.")
                        obj.setFlag(.isOpen)
                    } else {
                        output("That key doesn't fit the lock.")
                        return
                    }
                } else {
                    output("It's locked.")
                    return
                }
            } else {
                output("It's locked.")
                return
            }
        } else {
            // Open the object
            obj.setFlag(.isOpen)
            output("Opened.")
        }

        // If this is a container and it has contents, describe them
        if obj.hasFlag(.isContainer) {
            let contents = obj.contents
            if !contents.isEmpty {
                output("You see:")
                for item in contents {
                    output("  \(item.name)")
                }
            }
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the PRONOUNS command
    private func handlePronouns() {
        if let lastObj = world.lastMentionedObject {
            output("It: \(lastObj.name)")
        } else {
            output("No pronouns are defined yet.")
        }
    }

    /// Handle the PULL command
    private func handlePull(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.pull(obj)) {
            // The object handled the pull command
            return
        }

        // Default behavior
        output("Nothing happens when you pull the \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the PUSH command
    private func handlePush(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.push(obj)) {
            // The object handled the push command
            return
        }

        // Default behavior
        output("Nothing happens when you push the \(obj.name).")

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
            output("You're not carrying that.")
            return
        }

        // Check if container is accessible
        if !isObjectAccessibleForExamine(container) {
            output("You don't see that here.")
            return
        }

        // Check if the container has a custom handler for this command
        if container.processCommand(.putIn(obj, container: container)) {
            // The container handled the put in command
            return
        }

        // Default behavior
        // Check if destination is a container
        if !container.hasFlag(.isContainer) {
            output("You can't put anything in that.")
            return
        }

        // Check if container is open
        if !container.hasFlag(.isOpen) {
            output("The \(container.name) is closed.")
            return
        }

        // Put the object in the container
        obj.moveTo(container)
        output("You put the \(obj.name) in the \(container.name).")

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
            output("You're not carrying that.")
            return
        }

        // Check if surface is accessible
        if !isObjectAccessibleForExamine(surface) {
            output("You don't see that here.")
            return
        }

        // Check if the surface has a custom handler for this command
        if surface.processCommand(.putOn(obj, surface: surface)) {
            // The surface handled the put on command
            return
        }

        // Default behavior
        // Check if destination is a surface
        if !surface.hasFlag(.isSurface) {
            output("You can't put anything on that.")
            return
        }

        // Put the object on the surface
        obj.moveTo(surface)
        output("You put the \(obj.name) on the \(surface.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the QUIT command
    /// Ends the game
    private func handleQuit() {
        output("Thanks for playing!")
        isRunning = false
    }

    /// Handle READ command
    ///
    /// - Parameters:
    ///   - obj: The object to be read
    ///   - tool: Optional tool used for reading (like glasses)
    private func handleRead(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the tool is accessible
        if let tool = tool, !isObjectAccessibleForExamine(tool) {
            output("You don't have the \(tool.name).")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.read(obj, with: tool)) {
            // The object handled the read command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isReadable) {
            output("There's nothing to read on \(obj.name).")
            return
        }

        // Check if a special reading tool is required
        let needsReadingTool: Bool = obj.getState(forKey: "requires_reading_tool") ?? false
        if needsReadingTool && tool == nil {
            output("You need something to help you read this.")
            return
        }

        if let tool = tool {
            output("Using the \(tool.name), you read the \(obj.name).")
        }

        // Get the text from the object's state or use a default
        if let text: String = obj.getState(forKey: "text") {
            output(text)
        } else {
            output("You read \(obj.name).")
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
    private func handleRestart() throws {
        isGameOver = false
        gameOverMessage = nil

        // Reset the game world
        let newWorld = try recreateWorld()
        world = newWorld
        parser = CommandParser(world: world)

        output("\n--- Game Restarted ---\n")

        // Start with a look at the current room
        try executeCommand(.look)
    }

    /// Handle the RUB command
    ///
    /// - Parameters:
    ///   - obj: The object to be rubbed
    ///   - tool: Optional tool to rub with
    private func handleRub(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the tool is accessible
        if let tool = tool, !isObjectAccessibleForExamine(tool) {
            output("You don't have the \(tool.name).")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.rub(obj, with: tool)) {
            // The object handled the rub command
            return
        }

        // Default behavior
        if let tool = tool {
            output("Rubbing the \(obj.name) with the \(tool.name) doesn't seem to do anything.")
        } else {
            output("Rubbing the \(obj.name) doesn't seem to do anything.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the SEARCH command
    private func handleSearch(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
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
                    output("The \(obj.name) is empty.")
                } else {
                    output("Searching the \(obj.name) reveals:")
                    for item in contents {
                        output("  \(item.name)")
                    }
                }
            } else {
                output("The \(obj.name) is closed.")
            }
        } else {
            output("You find nothing of interest.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the SING command
    private func handleSing() {
        output("You sing a little tune. Your singing voice leaves something to be desired.")
    }

    /// Handle the SMELL command
    private func handleSmell(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.smell(obj)) {
            // The object handled the smell command
            return
        }

        // Default behavior
        output("The \(obj.name) smells normal.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the SWIM command
    private func handleSwim() {
        // Check if current location is water
        if let room = world.player.currentRoom {
            if room.hasFlag(.isWaterLocation) {
                output("You swim around for a while.")
            } else {
                output("There's no water here to swim in.")
            }
        }
    }

    /// Handle the TAKE command
    ///
    /// - Parameter obj: The object to be taken
    private func handleTake(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
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
            output("You're already carrying that.")
            return
        }

        // Check if object is takeable
        if !obj.hasFlag(.isTakable) {
            output("You can't take that.")
            return
        }

        // Take the object
        obj.moveTo(world.player)
        output("Taken.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the TELL command
    private func handleTell(_ person: GameObject, about topic: String) {
        // Check if the person is accessible
        if !isObjectAccessibleForExamine(person) {
            output("You don't see them here.")
            return
        }

        // Check if the person has a custom handler for this command
        if person.processCommand(.tell(person, about: topic)) {
            // The person handled the tell command
            return
        }

        // Default behavior
        if person.hasFlag(.isPerson) {
            output("The \(person.name) doesn't seem interested in your comments about \(topic).")
        } else {
            output("You can't talk to that.")
        }

        // Update last mentioned object
        world.lastMentionedObject = person
    }

    /// Handle the THINK ABOUT command
    private func handleThinkAbout(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't know enough about that to think about it.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.thinkAbout(obj)) {
            // The object handled the think about command
            return
        }

        // Default behavior
        output("You think about the \(obj.name), but don't come to any conclusions.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the THROW AT command
    private func handleThrowAt(_ item: GameObject, target: GameObject) {
        // Check if player has the item
        if item.location !== world.player {
            output("You're not carrying that.")
            return
        }

        // Check if target is accessible
        if !isObjectAccessibleForExamine(target) {
            output("You don't see that here.")
            return
        }

        // Check if the target has a custom handler for this command
        if target.processCommand(.throwAt(item, target: target)) {
            // The target handled the throw at command
            return
        }

        // Default behavior
        output("You throw the \(item.name) at the \(target.name), but nothing interesting happens.")

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
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.turnOff(obj)) {
            // The object handled the turn off command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDevice) {
            output("That's not something you can turn off.")
            return
        }

        if !obj.hasFlag(.isOn) {
            output("That's already off.")
            return
        }

        obj.clearFlag(.isOn)
        output("You turn off \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle TURN ON command
    ///
    /// - Parameter obj: The device to be turned on
    private func handleTurnOn(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.turnOn(obj)) {
            // The object handled the turn on command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDevice) {
            output("That's not something you can turn on.")
            return
        }

        if obj.hasFlag(.isOn) {
            output("That's already on.")
            return
        }

        obj.setFlag(.isOn)
        output("You turn on \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the UNLOCK command
    private func handleUnlock(_ obj: GameObject, with tool: GameObject?) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see that here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.unlock(obj, with: tool)) {
            // The object handled the unlock command
            return
        }

        // Default behavior
        if !obj.hasFlag(.isDoor) && !obj.hasFlag(.isContainer) {
            output("That's not something you can unlock.")
            return
        }

        if !obj.hasFlag(.isLocked) {
            output("That's already unlocked.")
            return
        }

        // Check if we have a tool
        if let tool = tool {
            // Check if player has the tool
            if tool.location !== world.player {
                output("You don't have the \(tool.name).")
                return
            }

            if tool.hasFlag(.isTool) {
                obj.clearFlag(.isLocked)
                output("You unlock the \(obj.name) with the \(tool.name).")
            } else {
                output("You can't unlock anything with that.")
            }
        } else {
            output("You need something to unlock it with.")
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
            output("You're not wearing \(obj.name).")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.unwear(obj)) {
            // The object handled the unwear command
            return
        }

        // Check if the object is worn
        if !obj.hasFlag(.isBeingWorn) {
            output("You're not wearing \(obj.name).")
            return
        }

        // Unwear the object
        obj.clearFlag(.isBeingWorn)
        output("You take off \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle WAIT command
    private func handleWait() {
        output("Time passes...")
    }

    /// Handle the WAKE command
    private func handleWake(_ obj: GameObject) {
        // Check if the object is accessible
        if !isObjectAccessibleForExamine(obj) {
            output("You don't see them here.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.wake(obj)) {
            // The object handled the wake command
            return
        }

        // Default behavior
        if obj.hasFlag(.isPerson) {
            output("The \(obj.name) is already awake.")
        } else {
            output("That doesn't make any sense.")
        }

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the WAVE command
    private func handleWave(_ obj: GameObject) {
        // Check if the object is accessible (needs to be in inventory to wave)
        if obj.location !== world.player {
            output("You need to be holding that to wave it.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.wave(obj)) {
            // The object handled the wave command
            return
        }

        // Default behavior
        output("You wave the \(obj.name) around, but nothing happens.")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the WAVE HANDS command
    private func handleWaveHands() {
        output("You wave your hands in the air, but nothing happens.")
    }

    /// Handle WEAR command
    ///
    /// - Parameter obj: The object to be worn
    private func handleWear(_ obj: GameObject) {
        // Check if the object is in the player's inventory
        if !obj.isIn(world.player) {
            output("You need to be holding \(obj.name) first.")
            return
        }

        // Check if the object has a custom handler for this command
        if obj.processCommand(.wear(obj)) {
            // The object handled the wear command
            return
        }

        // Check if the object is wearable
        if !obj.hasFlag(.isWearable) {
            output("You can't wear \(obj.name).")
            return
        }

        // Check if the object is already worn
        if obj.hasFlag(.isBeingWorn) {
            output("You're already wearing \(obj.name).")
            return
        }

        // Wear the object
        obj.setFlag(.isBeingWorn)
        output("You put on \(obj.name).")

        // Update last mentioned object
        world.lastMentionedObject = obj
    }

    /// Handle the YES command
    private func handleYes() {
        output("Nothing happens.")
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
        output(
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
    private func recreateWorld() throws -> GameWorld {
        if let worldCreator {
            let freshWorld = try worldCreator()

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
