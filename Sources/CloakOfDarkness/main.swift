import Foundation
import ZILFCore

// Initialize the game world
let world = try CloakOfDarkness.create()

// Set up output handler that displays the game banner first
let outputHandler: (String) -> Void = { message in
    print(message)
}

// Create the game engine
let engine = GameEngine(
    world: world,
    outputHandler: outputHandler,
    worldCreator: CloakOfDarkness.create
)

// Start the game with a banner
print("""
Cloak of Darkness
A basic IF demonstration.
Original game by Roger Firth
ZIL conversion by Jesse McGrew with bits and pieces by Jayson Smith
Swift conversion by ZILFSwift team
""")

// Start the game
try engine.start()
