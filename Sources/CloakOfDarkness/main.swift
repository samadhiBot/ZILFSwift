import Foundation
import ZILFCore

// Initialize the game world
let world = try CloakOfDarkness.create()

// Game banner
let gameBanner = """
Cloak of Darkness
A basic IF demonstration.
Original game by Roger Firth
ZIL conversion by Jesse McGrew with bits and pieces by Jayson Smith
Swift conversion by ZILFSwift team
"""

// Game introduction text from the original ZIL
let introText = """
\(gameBanner)

Hurrying through the rainswept November night, you're glad to see the
bright lights of the Opera House. It's surprising that there aren't more
people about but, hey, what do you expect in a cheap demo game...?
"""

// Game version
let gameVersion = "ZILFSwift Cloak of Darkness v1.0"

// Create output manager based on command line arguments
let outputMode: OutputMode = CommandLine.arguments.contains("--no-ui") ? .standard : .terminal
let outputManager = OutputManagerFactory.create(mode: outputMode)

// Create the game engine
let engine = GameEngine(
    world: world,
    outputManager: outputManager,
    worldCreator: CloakOfDarkness.create,
    welcomeMessage: introText,
    gameVersion: gameVersion
)

// Setup signal handler for terminal resize
if case .terminal = outputMode {
    setupSignalHandler(gameEngine: engine)
}

// Start the game
try engine.start()
