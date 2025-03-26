import ZILFCore

struct ToyGame: ZilfGame {
    let output: (String) -> Void
    let versionInfo = "Version 0.1"
    let welcomeText = "Welcome to the Toy Game!"

    init(output: @escaping (String) -> Void) {
        self.output = output
    }

    func createWorld() throws -> GameWorld {
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

        // Add rooms to world
        try gameWorld.add(kitchen)
        try gameWorld.add(livingRoom)

        // Insert objects into world
        let apple = GameObject(
            name: "apple",
            description: "A shiny red apple.",
            location: kitchen,
            flags: .isTakable
        )
        try gameWorld.insert(apple)

        return gameWorld
    }
}
