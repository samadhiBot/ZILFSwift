import Foundation
import ZILFCore

/// Implementation of the classic "Cloak of Darkness" demo game.
///
/// This is a Swift implementation of the classic interactive fiction demo
/// originally designed by Roger Firth. It demonstrates a simple but complete
/// text adventure game using the ZILFCore engine.
struct CloakOfDarkness: ZilfGame {
    let welcomeText = """
        Cloak of Darkness
        A basic IF demonstration.
        Original game by Roger Firth
        ZIL conversion by Jesse McGrew with bits and pieces by Jayson Smith
        Swift conversion by ZILFSwift team
        
        Hurrying through the rainswept November night, you're glad to see the
        bright lights of the Opera House. It's surprising that there aren't more
        people about but, hey, what do you expect in a cheap demo game...?        
        """

    let versionInfo = "ZILFSwift Cloak of Darkness v1.0"

    let output: (String) -> Void

    /// Builder responsible for creating and connecting all game elements
    private let worldBuilder = WorldBuilder()

    init(output: @escaping (String) -> Void) {
        self.output = output
    }

    /// Creates the game world
    func createWorld() throws -> GameWorld {
        // Create player and world
        let player = Player(startingRoom: worldBuilder.foyer)
        let world = try GameWorld(player: player)

        // Build the game world
        try worldBuilder.build(world)

        return world
    }
}
