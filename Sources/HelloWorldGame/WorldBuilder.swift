import ZILFCore

/// Responsible for building the game world, including all rooms and objects
struct WorldBuilder {
    // MARK: - Rooms

    /// Game entrance
    let entrance = Room(
        name: "Entrance",
        description: """
            You are standing at the entrance to a small cave. Sunlight streams in from outside.
            """,
        flags: .isNaturallyLit
    )

    let mainCavern = Room(
        name: "Main Cavern",
        description: """
            This spacious cavern has smooth walls that glisten with moisture. A strange glow \
            emanates from deeper in the cave.
            """,
        flags: .isNaturallyLit
    )

    // New secret room
    let secretRoom = Room(
        name: "Secret Chamber",
        description: """
            This hidden chamber appears to have been untouched for centuries. Mysterious \
            symbols cover the walls.
            """,
        flags: .isNaturallyLit
    )

    let treasureRoom = Room(
        name: "Treasure Room",
        description: """
            This small chamber is filled with a soft, magical light. The walls are adorned \
            with ancient markings.
            """,
        flags: .isNaturallyLit
    )

    // New locked room
    let vaultRoom = Room(
        name: "Ancient Vault",
        description: """
            An impressive stone vault with ornate carvings. It looks like it once held \
            great treasures.
            """,
        flags: .isNaturallyLit
    )

    // Dangerous room
    let pitRoom = Room(
        name: "Unstable Ledge",
        description: """
            You stand at the edge of a crumbling ledge above a bottomless pit. \
            The ground feels very unstable.
            """
    )

    // MARK: - Objects

    // Create objects
    let lantern = GameObject(
        name: "lantern",
        description: "A brass lantern that provides warm light.",
        flags: .isTakable, .isLightSource
    )

    let coin = GameObject(
        name: "gold coin",
        description: "A shiny gold coin with strange markings.",
        flags: .isTakable
    )

    // Chest is not takeable
    let chest = GameObject(
        name: "treasure chest",
        description: "An ornate wooden chest with intricate carvings.",
        flags: .isContainer, .isOpenable
    )

    // Maybe add a treasure inside the chest
    let treasure = GameObject(
        name: "golden amulet",
        description: "An exquisite golden amulet that gleams with an inner light.",
        flags: .isTakable, .isLightSource, .isOn
    )

    let ancientKey = GameObject(
        name: "ancient key",
        description: "A weathered bronze key with strange symbols.",
        flags: .isTakable, .isTool
    )

    let magnifyingGlass = GameObject(
        name: "magnifying glass",
        description: "A magnifying glass with an ornate bronze handle.",
        flags: .isTakable, .isTool
    )

    let dagger = GameObject(
        name: "dagger",
        description: "A small but sharp dagger with a jeweled hilt.",
        flags: .isTakable, .isWeapon, .isTool
    )

    let lockedBox = GameObject(
        name: "locked box",
        description: "A small iron box with no visible keyhole. It seems to be sealed shut.",
        flags: .isContainer, .isLocked
    )

    let gem = GameObject(
        name: "sparkling gem",
        description: "A brilliant blue gem that seems to capture the light.",
        flags: .isTakable
    )

    // MARK: - World Building

    /// Builds the complete game world with all rooms and objects
    func build(_ world: GameWorld) throws {
        // Register all rooms
        try registerRooms(in: world)

        // Connect rooms with exits
        connectRooms()

        // Place objects in their initial locations
        placeObjects()

        // Register all objects
        try registerObjects(in: world)

        // Configure special object behaviors
        configureObjectBehaviors(in: world)

        // Configure special room behaviors
        configureRoomBehaviors(in: world)
    }

    /// Register all rooms with the game world
    private func registerRooms(in world: GameWorld) throws {
        try world.add(
            entrance,
            mainCavern,
            treasureRoom,
            secretRoom,
            vaultRoom,
            pitRoom
        )
    }

    /// Connect all rooms with exits
    private func connectRooms() {
        // Standard exits
        entrance.setExit(.north, to: mainCavern)
        mainCavern.setExit(.south, to: entrance)
        mainCavern.setExit(.east, to: treasureRoom)
        treasureRoom.setExit(.west, to: mainCavern)
        treasureRoom.setExit(.south, to: pitRoom)
        pitRoom.setExit(.north, to: treasureRoom)
    }

    /// Place all objects in their initial locations
    private func placeObjects() {
        // Place objects in rooms
        lantern.moveTo(entrance)
        coin.moveTo(mainCavern)
        chest.moveTo(treasureRoom)
        treasure.moveTo(chest)
        ancientKey.moveTo(secretRoom)
        magnifyingGlass.moveTo(entrance)
        dagger.moveTo(mainCavern)
        lockedBox.moveTo(treasureRoom)
        gem.moveTo(lockedBox)

        // Make sure the chest is closed
        chest.clearFlag(.isOpen)
    }

    /// Register all objects with the game world
    private func registerObjects(in world: GameWorld) throws {
        try world.insert(
            lantern,
            coin,
            chest,
            treasure,
            ancientKey,
            magnifyingGlass,
            dagger,
            lockedBox,
            gem
        )
    }

    /// Configure special object behaviors
    private func configureObjectBehaviors(in world: GameWorld) {
        // When examining the coin with the magnifying glass, reveal extra details
        coin.setCommandHandler { obj, command in
            if case .examine(let target, let tool) = command,
                target === coin,
                tool?.name == "magnifying glass"
            {
                world.output(
                    "Using the magnifying glass, you can see tiny inscriptions on the coin that tell the story of an ancient civilization that once inhabited this cave."
                )
                return true
            }
            return false
        }

        // The box can be attacked with the dagger to open it
        lockedBox.setCommandHandler { obj, command in
            if case .attack(let target, let weapon) = command,
                target === lockedBox
            {
                if weapon?.name == "dagger" {
                    world.output(
                        "You use the dagger to pry open the locked box. The lid pops open with a satisfying crack!"
                    )
                    lockedBox.clearFlag(.isLocked)
                    lockedBox.setFlag(.isOpen)
                    lockedBox.setFlag(.isOpenable)  // Now it can be opened and closed normally
                    return true
                } else {
                    world.output("You need something sharp to break open this box.")
                    return true
                }
            }
            return false
        }
    }

    /// Configure special room behaviors
    private func configureRoomBehaviors(in world: GameWorld) {
        setupMainCavernBehaviors(in: world)
        setupTreasureRoomBehaviors(in: world)
        setupSecretRoomBehaviors(in: world)
        setupVaultRoomBehaviors(in: world)
        setupPitRoomBehaviors(in: world)
    }

    /// Configure main cavern behaviors
    private func setupMainCavernBehaviors(in world: GameWorld) {
        // Ambient effects in the main cavern
        mainCavern.endTurnAction = { room in
            if world.isEventRunning(named: "lantern-flicker") {
                world.output(
                    "The cavern walls seem to shimmer in the flickering light.")
                return true  // Output was produced
            }
            return false  // No output
        }

        // Add a victory exit that requires the golden amulet
        mainCavern.setVictoryExit(
            direction: .west,
            victoryMessage:
                "As you move west with the golden amulet in your possession, it begins to glow brightly. The cave wall shimmers and dissolves, revealing a hidden passage. You step through and find yourself in a magical realm beyond the cave. Congratulations, you've completed the adventure!",
            condition: { room in
                // Check if the player has the golden amulet
                return world.player.inventory.contains { $0.name == "golden amulet" }
            }
        )
    }

    /// Configure treasure room behaviors
    private func setupTreasureRoomBehaviors(in world: GameWorld) {
        // Add entrance message
        treasureRoom.enterAction = { room in
            world.output("You feel a sense of awe as you enter this ancient chamber.")
            return true  // Output was produced
        }

        // Hidden exit functionality
        var treasureExamined = false
        treasureRoom.setHiddenExit(
            direction: .down,
            destination: secretRoom,
            condition: { _ in treasureExamined },
            revealMessage:
                "As you move around the room, you discover a hidden trapdoor in the floor!"
        )

        // Make the hidden exit appear when examining the treasure room walls
        treasureRoom.addCommandAction(
            Room.PrioritizedCommandAction { room, command in
                if case .examine(let obj, _) = command, obj === treasureRoom {
                    treasureExamined = true
                    world.output(
                        "You carefully examine the walls of the treasure room and notice subtle markings that suggest a hidden passage somewhere in the floor."
                    )
                    return true
                }
                return false
            })
    }

    /// Configure secret room behaviors
    private func setupSecretRoomBehaviors(in world: GameWorld) {
        // Add a locked exit from the secret room to the vault
        secretRoom.setLockedExit(
            direction: .north,
            destination: vaultRoom,
            key: ancientKey,
            lockedMessage:
                "A heavy stone door blocks the way north. There appears to be a keyhole.",
            unlockedMessage:
                "You insert the ancient key into the lock. With a grinding sound, the stone door swings open."
        )
    }

    /// Configure vault room behaviors
    private func setupVaultRoomBehaviors(in world: GameWorld) {
        // Add a one-way exit from the vault back to the main cavern
        vaultRoom.setOneWayExit(
            direction: .down,
            destination: mainCavern,
            message: "You slide down a smooth stone chute and land back in the main cavern!"
        )
    }

    /// Configure pit room behaviors
    private func setupPitRoomBehaviors(in world: GameWorld) {
        // Set naturally lit flag
        pitRoom.setFlag(.isNaturallyLit)

        // Add the deadly pit exit
        pitRoom.setDeadlyExit(
            direction: .down,
            deathMessage: """
                You step forward and the ledge gives way beneath you. You fall into darkness, \
                tumbling endlessly into the abyss...
                """
        )
    }
}
