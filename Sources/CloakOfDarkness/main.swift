import Foundation
import ZILFCore

// Initialize the game world
let world = try CloakOfDarkness.create()

// Set up output handler that displays the game banner first
let outputHandler: (String) -> Void = { message in
    print(message)
}

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

// Create the game engine
let engine = GameEngine(
    world: world,
    outputHandler: outputHandler,
    worldCreator: CloakOfDarkness.create,
    welcomeMessage: introText,
    gameVersion: gameVersion
)

// Start the game
try engine.start()
