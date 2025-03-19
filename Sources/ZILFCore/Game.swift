import Foundation

/// A base class for interactive fiction games using the ZILF framework
@MainActor open class Game {
    /// Welcome text displayed when the game starts
    public let welcomeText: String

    /// Version information for the game
    public let versionInfo: String

    public let engine: GameEngine
    public var world: GameWorld {
        engine.world
    }
    public let outputManager: OutputManager

    /// Creates a new game instance
    /// - Parameters:
    ///   - outputManager: The output manager (defaults to standard console output)
    ///   - welcomeText: Welcome message to display at game start
    ///   - versionInfo: Version information to display
    public init(
        outputManager: OutputManager = StandardOutputManager(),
        welcomeText: String,
        versionInfo: String
    ) {
        self.outputManager = outputManager
        self.welcomeText = welcomeText
        self.versionInfo = versionInfo

        // Create the engine without a world initially
        engine = GameEngine(
            outputHandler: { [weak outputManager] message in
                outputManager?.output(message)
            },
            inputHandler: { [weak outputManager] prompt in
                return outputManager?.getInput(prompt: prompt)
            },
            statusLineHandler: { [weak outputManager] location, score, moves in
                outputManager?.updateStatusLine(location: location, score: score, moves: moves)
            }
        )

        // Set the world creator function
        engine.setWorldCreator { [weak self] in
            try type(of: self!).create()
        }
    }

    /// Outputs a message to the game's display mechanism
    public func output(_ message: String) {
        outputManager.output(message)
    }

    /// Gets input from the player with an optional prompt
    public func getInput(prompt: String = "> ") -> String? {
        return outputManager.getInput(prompt: prompt)
    }

    /// Creates the game world - must be implemented by subclasses
    open class func create() throws -> GameWorld {
        fatalError("Subclasses must implement create()")
    }

//    /// Runs a single command from text input
//    /// - Parameter input: The command text to process
//    /// - Returns: True if the game is still running
//    @discardableResult
//    public func runCommand(_ input: String) throws -> Bool {
//        return try engine.executeGameLoop(input: input)
//    }

    /// Starts the game and runs until completion
    open func start() throws {
        // Display welcome text and version info
        output(welcomeText)
        output("\n\(versionInfo)\n")
        output("Type 'help' for a list of commands.\n")

        // Start with a look at the current room
        try engine.executeCommand(.look)

        // Run the game loop through the engine
        try engine.start()

        // Handle shutdown
        outputManager.shutdown()
    }

    /// Perform game-specific setup after world creation
    /// Override this in subclasses to add custom initialization
    open func setupGame() {
        // Default implementation does nothing
    }

    /// Saves the current game state to a file
    /// - Parameter filename: The file to save to
    open func saveGame(to filename: String) throws {
        // Default implementation - override with actual save functionality
        output("Save game functionality not implemented.")
    }

    /// Loads a game state from a file
    /// - Parameter filename: The file to load from
    open func loadGame(from filename: String) throws {
        // Default implementation - override with actual load functionality
        output("Load game functionality not implemented.")
    }

    /// Returns a description of how the score was earned
    open func getScoreExplanation() -> String {
        return "Score: \(engine.score) out of \(engine.maximumScore) points."
    }

    /// Handles terminal resize events
    public func handleTerminalResize() {
        if let termManager = outputManager as? TerminalOutputManager {
            termManager.handleResize()

            // Update status line
            let locationName = world.player.currentRoom?.name ?? "Unknown"
            outputManager
                .updateStatusLine(
                    location: locationName,
                    score: engine.score,
                    moves: engine.moveCount
                )
        }
    }
}
