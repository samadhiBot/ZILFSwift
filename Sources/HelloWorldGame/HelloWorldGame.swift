import Foundation
import ZILFCore

/// A simple Hello World game implementing the ZILF framework
struct HelloWorldGame: ZilfGame {
    let welcomeText = """
        ====================================
        Welcome to Hello World Adventure!
        A tiny demonstration game using ZILF
        ====================================
        """

    let versionInfo = "Hello World Game v1.0"

    let output: (String) -> Void

    /// Builder responsible for creating and connecting all game elements
    private let worldBuilder = WorldBuilder()

    init(output: @escaping (String) -> Void) {
        self.output = output
    }

    /// Creates the game world
    func createWorld() throws -> GameWorld {
        // Create player and world
        let player = Player(startingRoom: worldBuilder.entrance)
        let world = try GameWorld(player: player)

        // Build the game world
        try worldBuilder.build(world)

        // Configure events
        configureEvents(in: world)

        return world
    }

    // MARK: - World Components

    /// Configure game events
    private func configureEvents(in world: GameWorld) {
        // Add event examples
        world.queueEvent(name: "lantern-flicker", turns: 8) {
            output("The lantern's flame flickers briefly.")
            return true
        }

        world.queueEvent(name: "ambient-sounds", turns: 4) {
            // This will run every 4 turns
            let sounds = [
                "You hear water dripping somewhere nearby.",
                "A cool breeze rustles through the cave.",
                "There's a distant sound of grinding stone.",
                "You hear a faint whisper echoing off the walls.",
            ]
            if Int.random(in: 1...4) == 1 {  // 25% chance each time
                output(sounds.randomElement()!)
                return true
            }
            return false
        }
    }
}
