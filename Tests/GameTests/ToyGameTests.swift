import Foundation
import Testing
import ZILFCore
import ZILFTestSupport

struct ToyGameTests {
    let game: ToyGame
    let engine: GameEngine
    let outputCapture = OutputCapture()
    var outputs: [String] = []

    init() {
        game = ToyGame(output: outputCapture.output)
        engine = GameEngine(game: game)
        engine.start()
    }

    @Test
    func example() {
        #expect(outputs.isEmpty)
    }
}

struct ToyGame: ZilfGame {
    let output: (String) -> Void
    let versionInfo: String = "Version 0.1"
    let welcomeText: String = "Welcome to the Toy Game!"

    init(output: @escaping (String) -> Void) {
        self.output = output
    }

    // Core game implementation methods
    func createWorld() -> GameWorld {
        // Create rooms
        let kitchen = Room(
            name: "Kitchen",
            description: "A cozy kitchen with modern appliances.",
            flags: .isNaturallyLit
        )
        let livingRoom = Room(
            name: "Living Room",
            description: "A comfortable living room with a fireplace.",
            flags: .isNaturallyLit
        )

        // Create player and world
        let player = Player(startingRoom: kitchen)
        let gameWorld = GameWorld(player: player)

        // Connect rooms
        kitchen.exits[.south] = livingRoom
        livingRoom.exits[.north] = kitchen

        // Register rooms
        gameWorld.register(room: kitchen)
        gameWorld.register(room: livingRoom)

        // Add objects
        let apple = GameObject(
            name: "apple",
            description: "A shiny red apple.",
            location: kitchen,
            flags: .isTakable
        )
        gameWorld.register(apple)

        return gameWorld
    }
}
