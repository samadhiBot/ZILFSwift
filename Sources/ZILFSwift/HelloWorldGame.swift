import Foundation
import ZILFCore

struct HelloWorldGame {
    static func create() -> GameWorld {
        // Create rooms
        let entrance = Room(
            name: "Entrance",
            description:
                "You are standing at the entrance to a small cave. Sunlight streams in from outside."
        )
        entrance.setFlag(.isNaturallyLit)

        let mainCavern = Room(
            name: "Main Cavern",
            description:
                "This spacious cavern has smooth walls that glisten with moisture. A strange glow emanates from deeper in the cave."
        )
        mainCavern.setFlag(.isNaturallyLit)

        let treasureRoom = Room(
            name: "Treasure Room",
            description:
                "This small chamber is filled with a soft, magical light. The walls are adorned with ancient markings."
        )
        treasureRoom.setFlag(.isNaturallyLit)

        // New secret room
        let secretRoom = Room(
            name: "Secret Chamber",
            description:
                "This hidden chamber appears to have been untouched for centuries. Mysterious symbols cover the walls."
        )
        secretRoom.setFlag(.isNaturallyLit)

        // New locked room
        let vaultRoom = Room(
            name: "Ancient Vault",
            description:
                "An impressive stone vault with ornate carvings. It looks like it once held great treasures."
        )
        vaultRoom.setFlag(.isNaturallyLit)

        // Connect rooms with exits
        entrance.setExit(direction: .north, room: mainCavern)
        mainCavern.setExit(direction: .south, room: entrance)
        mainCavern.setExit(direction: .east, room: treasureRoom)
        treasureRoom.setExit(direction: .west, room: mainCavern)

        // Create player
        let player = Player(startingRoom: entrance)

        // Create game world
        let world = GameWorld(player: player)
        world.register(room: entrance)
        world.register(room: mainCavern)
        world.register(room: treasureRoom)
        world.register(room: secretRoom)
        world.register(room: vaultRoom)

        // Create objects
        let lantern = GameObject(
            name: "lantern",
            description: "A brass lantern that provides warm light.",
            location: entrance,
            flags: .isTakable
        )
        lantern.setFlag(.isLightSource)

        let coin = GameObject(
            name: "gold coin",
            description: "A shiny gold coin with strange markings.",
            location: mainCavern,
            flags: .isTakable
        )

        let chest = GameObject(
            name: "treasure chest",
            description: "An ornate wooden chest with intricate carvings.",
            location: treasureRoom,
            flags: .isContainer, .isOpenable
        )
        // Chest is not takeable

        // Maybe add a treasure inside the chest
        let treasure = GameObject(
            name: "golden amulet",
            description: "An exquisite golden amulet that gleams with an inner light.",
            location: chest,
            flags: .isTakable
        )
        treasure.setFlags(.isLightSource, .isOn)

        // Make sure to close the chest
        chest.clearFlag(.isOpen)

        // Create a key for the vault
        let ancientKey = GameObject(
            name: "ancient key",
            description: "A weathered bronze key with strange symbols.",
            location: secretRoom,
            flags: .isTakable, .isTool
        )

        world.register(lantern)
        world.register(coin)
        world.register(chest)
        world.register(treasure)
        world.register(ancientKey)

        // Add event examples
        world.queueEvent(name: "lantern-flicker", turns: 3) {
            print("The lantern's flame flickers briefly.")
            return true
        }

        world.queueEvent(name: "ambient-sounds", turns: -1) {
            // This will run every turn
            let sounds = [
                "You hear water dripping somewhere nearby.",
                "A cool breeze rustles through the cave.",
                "There's a distant sound of grinding stone.",
                "You hear a faint whisper echoing off the walls.",
            ]
            if Int.random(in: 1...4) == 1 {  // 25% chance each turn
                print(sounds.randomElement()!)
                return true
            }
            return false
        }

        // Add room action handlers
        mainCavern.endTurnAction = { room in
            if world.isEventRunning(named: "lantern-flicker") {
                print("The cavern walls seem to shimmer in the flickering light.")
                return true  // Output was produced
            }
            return false  // No output
        }

        treasureRoom.enterAction = { room in
            print("You feel a sense of awe as you enter this ancient chamber.")
            return true  // Output was produced
        }

        // Add a hidden exit from the treasure room to the secret chamber
        var treasureExamined = false
        treasureRoom.setHiddenExit(
            direction: .down,
            destination: secretRoom,
            world: world,
            condition: { _ in treasureExamined },
            revealMessage:
                "As you move around the room, you discover a hidden trapdoor in the floor!"
        )

        // Make the hidden exit appear when examining the treasure room walls
        treasureRoom.addCommandAction(Room.PrioritizedCommandAction { room, command in
            if case .examine(let obj, _) = command, obj === treasureRoom {
                treasureExamined = true
                print("You carefully examine the walls of the treasure room and notice subtle markings that suggest a hidden passage somewhere in the floor.")
                return true
            }
            return false
        })

        // Add a locked exit from the secret room to the vault
        secretRoom.setLockedExit(
            direction: .north,
            destination: vaultRoom,
            world: world,
            key: ancientKey,
            lockedMessage:
                "A heavy stone door blocks the way north. There appears to be a keyhole.",
            unlockedMessage:
                "You insert the ancient key into the lock. With a grinding sound, the stone door swings open."
        )

        // Add a one-way exit from the vault back to the main cavern
        vaultRoom.setOneWayExit(
            direction: .down,
            destination: mainCavern,
            world: world,
            message: "You slide down a smooth stone chute and land back in the main cavern!"
        )

        // Add a dangerous pit with a deadly exit
        let pitRoom = Room(
            name: "Unstable Ledge",
            description:
                "You stand at the edge of a crumbling ledge above a bottomless pit. The ground feels very unstable."
        )
        pitRoom.setFlag(.isNaturallyLit)

        // Connect the pit room
        treasureRoom.setExit(direction: .south, room: pitRoom)
        pitRoom.setExit(direction: .north, room: treasureRoom)

        // Add the deadly pit exit
        pitRoom.setDeadlyExit(
            direction: .down,
            deathMessage:
                "You step forward and the ledge gives way beneath you. You fall into darkness, tumbling endlessly into the abyss...",
            world: world
        )

        // Add a victory exit that requires the golden amulet
        mainCavern.setVictoryExit(
            direction: .west,
            victoryMessage:
                "As you move west with the golden amulet in your possession, it begins to glow brightly. The cave wall shimmers and dissolves, revealing a hidden passage. You step through and find yourself in a magical realm beyond the cave. Congratulations, you've completed the adventure!",
            world: world,
            condition: { room in
                // Check if the player has the golden amulet
                return world.player.inventory.contains { $0.name == "golden amulet" }
            }
        )

        // Register the new room
        world.register(room: pitRoom)

        // Create a magnifying glass for examining small details
        let magnifyingGlass = GameObject(
            name: "magnifying glass",
            description: "A magnifying glass with an ornate bronze handle.",
            location: entrance,
            flags: .isTakable, .isTool
        )

        // When examining the coin with the magnifying glass, reveal extra details
        coin.setCommandHandler { obj, command in
            if case .examine(let target, let tool) = command,
               target === coin,
               tool?.name == "magnifying glass" {
                print("Using the magnifying glass, you can see tiny inscriptions on the coin that tell the story of an ancient civilization that once inhabited this cave.")
                return true
            }
            return false
        }

        // Create a small dagger to demonstrate attack with tool
        let dagger = GameObject(
            name: "dagger",
            description: "A small but sharp dagger with a jeweled hilt.",
            location: mainCavern,
            flags: .isTakable, .isWeapon, .isTool
        )

        // Create a locked box that needs to be broken open
        let lockedBox = GameObject(
            name: "locked box",
            description: "A small iron box with no visible keyhole. It seems to be sealed shut.",
            location: treasureRoom,
            flags: .isContainer, .isLocked
        )

        // The box can be attacked with the dagger to open it
        lockedBox.setCommandHandler { obj, command in
            if case .attack(let target, let weapon) = command,
               target === lockedBox {
                if weapon?.name == "dagger" {
                    print("You use the dagger to pry open the locked box. The lid pops open with a satisfying crack!")
                    lockedBox.clearFlag(.isLocked)
                    lockedBox.setFlag(.isOpen)
                    lockedBox.setFlag(.isOpenable) // Now it can be opened and closed normally
                    return true
                } else {
                    print("You need something sharp to break open this box.")
                    return true
                }
            }
            return false
        }

        // Add a small gem inside the locked box
        let gem = GameObject(
            name: "sparkling gem",
            description: "A brilliant blue gem that seems to capture the light.",
            location: lockedBox,
            flags: .isTakable
        )

        // Add the new objects to the world
        world.register(magnifyingGlass)
        world.register(dagger)
        world.register(lockedBox)
        world.register(gem)

        return world
    }
}
