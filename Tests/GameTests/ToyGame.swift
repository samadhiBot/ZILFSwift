import ZILFCore

struct ToyGame: ZilfGame {
    let output: (String) -> Void
    let versionInfo = "Version 0.1"
    let welcomeText = "Welcome to the Toy Game!"

    init(output: @escaping (String) -> Void) {
        self.output = output
    }

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
        gameWorld.register(kitchen)
        gameWorld.register(livingRoom)

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
