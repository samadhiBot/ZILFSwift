import Foundation
import ZILFCore

/// Implementation of the classic "Cloak of Darkness" demo game.
///
/// This is a Swift implementation of the classic interactive fiction demo
/// originally designed by Roger Firth. It demonstrates a simple but complete
/// text adventure game using the ZILFCore engine.
public enum CloakOfDarkness {

    /// Creates and initializes the complete game world.
    ///
    /// This method sets up all rooms, objects, and connections for the Cloak of Darkness game.
    ///
    /// - Returns: A fully configured game world ready to be played.
    public static func create() throws -> GameWorld {
        // Create the rooms
        let foyer = createFoyer()
        let bar = createBar()
        let cloakroom = createCloakroom()
        let hallToStudy = createHallToStudy()
        let study = createStudy()
        let closet = createCloset()

        // Create player and world (player needs a starting room)
        let player = Player(startingRoom: foyer)
        let world = GameWorld(player: player)

        // Register rooms with the world
        world.register(room: foyer)
        world.register(room: bar)
        world.register(room: cloakroom)
        world.register(room: hallToStudy)
        world.register(room: study)
        world.register(room: closet)

        // Set up exits
        foyer.exits[.south] = bar
        foyer.exits[.west] = cloakroom
        bar.exits[.north] = foyer
        cloakroom.exits[.east] = foyer
        hallToStudy.exits[.east] = study
        study.exits[.west] = hallToStudy
        study.exits[.north] = closet
        closet.exits[.south] = study

        // Create objects and populate the world
        // Create player inventory
        createPlayerInventory(world: world)

        // Create room-specific objects
        createFoyerObjects(world: world, foyer: foyer)
        createBarObjects(world: world, bar: bar)
        createCloakroomObjects(world: world, cloakroom: cloakroom)
        createHallwayObjects(world: world, hallToStudy: hallToStudy)
        createStudyObjects(world: world, study: study)
        createClosetObjects(world: world, closet: closet)

        // Create global objects
        try createGlobalObjects(
            world: world,
            hallToStudy: hallToStudy
        )

        return world
    }

    // MARK: - Room Creation Methods

    /// Creates and configures the bar room.
    ///
    /// - Returns: A configured bar room.
    private static func createBar() -> Room {
        let bar = Room(
            name: "Foyer Bar",
            description:
                "The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty."
        )

        // Bar enter action - handle lighting based on cloak
        bar.enterAction = { (room: Room) -> Bool in
            // Use findPlayer helper to get the player
            let player = room.findPlayer()

            // Check if player has cloak and it's being worn
            let hasCloak = player?.inventory.contains {
                $0.name == "cloak" && $0.hasFlag(.isBeingWorn)
            } ?? false

            if hasCloak {
                // Player has cloak - set room to dark
                room.clearFlag(.isOn)
                return false
            } else {
                // Player doesn't have cloak - set room to lit
                room.setFlag(.isOn)
                return false
            }
        }

        // Bar begin-turn action - handle stumbling in dark
        bar.beginTurnAction = { (room: Room) -> Bool in
            if !room.hasFlag(.isOn) {
                // Get the command through the engine from game world directly
                var command: Command? = nil
                if let player = room.findPlayer() {
                    // Look for the last command which is what we need here
                    // Note: The GameEngine API doesn't expose currentCommand directly,
                    // but we can access lastCommand through custom handling in our test
                    if let engine = player.engine {
                        // In a real implementation, we would have a proper API for this
                        // For now, we'll just assume the command we want is available
                    }
                }

                // Skip this effect for certain commands
                if let command {
                    switch command {
                    case .look:
                        return false
                    case .move(let direction) where direction == .north:
                        return false
                    case .examine(let obj, _) where obj?.name == "message":
                        // Allow examining the message even in the dark
                        return false
                    case .thinkAbout:
                        return false
                    default:
                        // Continue with the dark room handling
                        break
                    }
                }

                print("You grope around clumsily in the dark. Better be careful.")

                // Update disturbed counter
                room.disturbed = (room.disturbed ?? 0) + 1

                return true
            }
            return false
        }

        // Override look handler for bar to make the description match test expectations
        bar.lookAction = { (room: Room) -> Bool in
            if room.hasFlag(.isOn) {
                print(
                    "The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty. You can see a message scrawled in the sawdust on the floor."
                )
                return true
            } else {
                print("It's too dark to see.")
                return true
            }
        }

        // Initialize disturbed counter
        bar.disturbed = 0

        return bar
    }

    /// Creates and configures the closet room.
    ///
    /// - Returns: A configured closet room.
    private static func createCloset() -> Room {
        let closet = Room(
            name: "Closet",
            description: "A cramped excuse of a closet."
        )

        // Closet enter action - update lighting based on switch
        closet.enterAction = { (room: Room) -> Bool in
            // Access the game world directly
            let world = room.findWorld()

            if let study = try? world?.find(room: "Study" ),
                let lightSwitch = study.contents.first(where: { $0.name == "light switch" })
            {
                if lightSwitch.hasFlag(.isOn) {
                    room.setFlag(.isOn)
                } else {
                    room.clearFlag(.isOn)
                }
            }
            return false
        }

        return closet
    }

    /// Creates and configures the cloakroom.
    ///
    /// - Returns: A configured cloakroom.
    private static func createCloakroom() -> Room {
        let cloakroom = Room(
            name: "Cloakroom",
            description:
                "The walls of this small room were clearly once lined with hooks, though now only one remains. The exit is a door to the east, but there is also a cramped opening to the west.",
            flags: .isOn
        )

        // Custom enter action for the cloakroom
        cloakroom.enterAction = { (room: Room) -> Bool in
            // Check if rug is a local-global in foyer
            if let world = room.findWorld(),
               let foyer = try? world.find(room: "Foyer of the Opera House" ),
                let rug = world.globalObjects.first(where: { $0.name == "rug" })
            {
                if foyer.getAccessibleLocalGlobals().contains(where: { $0 === rug }) {
                    print(
                        "Did you know that the rug is a local-global object in the Foyer and the Bar?"
                    )
                    return true
                }
            }
            return false
        }

        // Handle the special exit west
        cloakroom.beginCommandAction = { (room: Room, command: Command) -> Bool in
            guard case .move(.west) = command else { return false }

            // Find the player using the findPlayer helper
            let player = room.findPlayer()

            // Check if player is wearing the cloak
            let hasCloak = player?.inventory.contains {
                $0.name == "cloak" && $0.hasFlag(.isBeingWorn)
            } ?? false

            if hasCloak {
                print("You cannot enter the opening to the west while in possession of your cloak.")
                return true
            } else {
                // Try to access the world from our room's stored state
                let world = room.findWorld()

                // Try to find the hallway
                if let world,
                   let hallToStudy = try? world.find(room: "Hallway to Study")
                {
                    if let player, let currentRoom = player.currentRoom {
                        // Remove from current room
                        currentRoom.remove(player)

                        // Use setLocation which handles adding to the destination's contents
                        player.moveTo(hallToStudy)

                        // Execute enter actions in the new room
                        _ = hallToStudy.executeEnterAction()

                        return true
                    }
                }

                print("You can't go that way.")
                return true
            }
        }

        return cloakroom
    }

    /// Creates and configures the main foyer.
    ///
    /// - Returns: A configured foyer room.
    private static func createFoyer() -> Room {
        let foyer = Room(
            name: "Foyer of the Opera House",
            description:
                "You are standing in a spacious hall, splendidly decorated in red and gold, with glittering chandeliers overhead. The entrance from the street is to the north, and there are doorways south and west."
        )

        foyer.setFlag(.isOn)

        // Foyer end-turn action
        foyer.endTurnAction = { (room: Room) -> Bool in
            // For the end-turn action, we'll check for the named events
            // Access the world directly rather than through the player
            if let world = room.findWorld() {
                // Return true if any of these events are in progress
                if world.isEventScheduled(named: "I-APPLE-FUN") {
                    print("The Foyer routine detects that the Apple event will run this turn!")
                    return true
                }
                if world.isEventScheduled(named: "I-TABLE-FUN") {
                    print("The Foyer routine detects that the Table event will run this turn!")
                    return true
                }
            }
            return false
        }

        return foyer
    }

    /// Creates and configures the hallway to the study.
    ///
    /// - Returns: A configured hallway room.
    private static func createHallToStudy() -> Room {
        let hallToStudy = Room(
            name: "Hallway to Study",
            description:
                "The hallway leads to a Study to the west, and back to the Cloakroom to the east."
        )
        hallToStudy.setFlag(.isOn)

        // Hall enter action
        hallToStudy.enterAction = { (room: Room) -> Bool in
            print("Oof - it's cramped in here.")
            return true
        }

        // Hall end-turn action
        hallToStudy.endTurnAction = { (room: Room) -> Bool in
            print("A spider scuttles across your feet and then disappears into a crack.")
            return true
        }

        return hallToStudy
    }

    /// Creates and configures the study room.
    ///
    /// - Returns: A configured study room.
    private static func createStudy() -> Room {
        let study = Room(
            name: "Study",
            description:
                "A small room with a worn stand in the middle. A hallway lies east of here, a closet off to the west."
        )
        study.setFlag(.isOn)

        // End-turn action for study
        study.endTurnAction = { (room: Room) -> Bool in
            let random = Int.random(in: 1...4)
            if random == 1 {
                print("A mouse zips across the floor and into a hole.")
                return true
            } else if random == 2 {
                print("A faint scratching sound can be heard from the ceiling.")
                return true
            }
            return false
        }

        return study
    }

    // MARK: - Object Creation Methods

    /// Creates objects for the bar room.
    /// - Parameters:
    ///   - world: The game world.
    ///   - bar: The bar room.
    private static func createBarObjects(world: GameWorld, bar: Room) {
        // Message
        let message = GameObject(
            name: "message",
            description: "The message reads: \"No loitering in the bar without a drink.\"",
            location: bar
        )
        message.firstDescription =
            "There seems to be some sort of message scrawled in the sawdust on the floor."
        world.register(message)

        message.setExamineHandler { obj in
            let room = obj.location as? Room
            let disturbed = (room?.disturbed as Int?) ?? 0

            // Find the player using our helper method
            if let player = obj.findPlayer() {
                print("The message simply reads: \"You ", terminator: "")
                if disturbed > 1 {
                    print("lose.\"")
                    player.engine.gameOver(message: "You lose", isVictory: false)
                } else {
                    print("win.\"")
                    player.engine.gameOver(message: "You win", isVictory: true)
                }
            }
            return true
        }

        message.setTakeHandler { obj in
            print("The message is just sawdust on the floor, you can't take it.")

            // Disturb the floor
            let room = obj.location as? Room
            let disturbed = (room?.disturbed as Int?) ?? 0
            room?.disturbed = disturbed + 1

            return true
        }
    }

    /// Creates objects for the closet room.
    /// - Parameters:
    ///   - world: The game world.
    ///   - closet: The closet room.
    private static func createClosetObjects(world: GameWorld, closet: Room) {
        // Create a broom in the closet
        let broom = GameObject(
            name: "broom",
            description: "A plain wooden broom for sweeping.",
            location: closet,
            flags: .isTakable
        )
        world.register(broom)

        broom.setExamineHandler { obj in
            print(
                "A plain wooden broom for sweeping."
            )
            return true
        }

        // Create a dusty shelf
        let shelf = GameObject(
            name: "shelf",
            description: "A narrow utility shelf.",
            location: closet,
            flags: .isContainer, .isSurface
        )
        world.register(shelf)

        shelf.setExamineHandler { obj in
            print("A dusty wooden shelf attached to the wall.")
            return true
        }
    }

    /// Creates objects for the cloakroom.
    /// - Parameters:
    ///   - world: The game world.
    ///   - cloakroom: The cloakroom.
    private static func createCloakroomObjects(world: GameWorld, cloakroom: Room) {
        // Hook
        let hook = GameObject(
            name: "small brass hook",
            description: "A small brass hook mounted on the wall.",
            location: cloakroom,
            flags: .isContainer, .isSurface,
            synonyms: "peg"
        )
        hook.firstDescription = "A small brass hook is on the wall."
        world.register(hook)

        hook.setExamineHandler { obj in
            print("Test: Normal examine replaced by a dequeue of the Table event.")
            // Access the world directly rather than through the player
            if let world = obj.findWorld() {
                _ = world.dequeueEvent(named: "I-TABLE-FUN")
            }
            return true
        }
    }

    /// Creates objects for the foyer room.
    /// - Parameters:
    ///   - world: The game world.
    ///   - foyer: The foyer room.
    private static func createFoyerObjects(world: GameWorld, foyer: Room) {
        // Create an apple in the foyer
        let apple = GameObject(
            name: "apple",
            description: "A shiny red apple.",
            location: foyer,
            flags: .isTakable, .isEdible, .beginsWithVowel
        )

        apple.setExamineHandler { obj in
            print("The apple is green and tasty-looking.")
            // Queue the apple event
            if let world = obj.findWorld() {
                world.eventManager.scheduleEvent(
                    name: "I-APPLE-FUN",
                    turns: 3,
                    action: {
                        true
                    }
                )
            }
            return true
        }

        apple.setCustomCommandHandler(verb: "eat") { obj, objects in
            print("Oh no! It was actually a poison apple (mostly so we could test JIGS-UP).")
            // Find the player
            if let player = obj.findPlayer() {
                player.engine.gameOver(message: "You've been poisoned by the apple.")
            }
            return true
        }

        world.register(apple)

        // Table in the foyer
        let table = GameObject(
            name: "table",
            description: "Tatty but functional.",
            location: foyer,
            flags: .isContainer, .isSurface,
            synonyms: "furniture"
        )
        world.register(table)

        table.setExamineHandler { obj in
            print("Tatty but functional.")
            // Show contents if any
            if !obj.contents.isEmpty {
                // Describe contents (implementation would depend on the API)
                print("On the table you see:")
                for item in obj.contents {
                    print("  \(item.name)")
                }
            }

            // Queue table event
            if let world = obj.findWorld() {
                world.eventManager.scheduleEvent(
                    name: "I-TABLE-FUN",
                    turns: -1, // -1 means every turn
                    action: {
                        true
                    }
                )
            }
            return true
        }

        // Grapes on the table
        let grapes = GameObject(
            name: "grapes",
            description: "A bunch of grapes.",
            location: table,
            flags: .isTakable, .isEdible, .isPlural, .omitArticle
        )
        world.register(grapes)

        // Playing card on the table
        let card = GameObject(
            name: "card",
            description: "A playing card.",
            location: table,
            flags: .isTakable
        )
        world.register(card)

        card.setExamineHandler { obj in
            // Pick a random description
            let descriptions = ["Ace of Spades.", "The Hermit.", "The Weeping Joker."]
            print(descriptions.randomElement() ?? "A playing card.")
            return true
        }

        // Time cube
        let cube = GameObject(
            name: "cube",
            description: "A mysterious cube.",
            location: foyer,
            flags: .isTakable
        )
        world.register(cube)

        cube.setExamineHandler { obj in
            print("As you inspected the cube you realized time around you speeds by.")
            // In a full implementation, this would trigger waiting for 10 turns
            if let player = obj.findPlayer(), let engine = player.engine {
                // This would be something like engine.waitTurns(10)
            }
            return true
        }

        // Changing painting
        let painting = GameObject(
            name: "painting",
            description: "An unusual painting that seems to change.",
            location: foyer,
            synonyms: "picture", "art"
        )
        world.register(painting)

        painting.setExamineHandler { obj in
            // Pick a random description
            let descriptions = [
                "It shows a dancing bear.",
                "It displays a clown walking on its hands.",
                "It shows a horse eating a shoe.",
                "It shows a man hunting for a copy of Zork.",
                "It displays a cat that is laughing.",
                "It displays a machine marked with a Z.",
            ]
            print(descriptions.randomElement() ?? "A strange painting.")
            return true
        }

        painting.setCustomCommandHandler(verb: "read") { obj, _ in
            // Pick a random signature
            let signatures = ["Micheangelo.", "Phil Collins.", "The Dude."]
            print(
                "The signature at the bottom rearranges itself to read \(signatures.randomElement() ?? "unknown")"
            )
            return true
        }

        // Some grime on the floor
        let grime = GameObject(
            name: "grime",
            description: "Just some dirty spots on the marble floor.",
            location: foyer,
            flags: .isTakable, .omitArticle
        )
        world.register(grime)

        grime.setExamineHandler { obj in
            print("A small but disgusting collection of crud.")
            // Queue grime event
            if let world = obj.findWorld() {
                world.eventManager.scheduleEvent(
                    name: "I-GRIME-FUN",
                    turns: 2,
                    action: {
                        true
                    }
                )
            }
            return true
        }
    }

    /// Creates global objects available throughout the game.
    /// - Parameter world: The game world.
    private static func createGlobalObjects(
        world: GameWorld,
        hallToStudy: GameObject
    ) throws {
        // Ceiling with cobwebs
        let ceiling = GameObject(
            name: "ceiling",
            description: "Nothing really noticeable about the ceiling."
        )
        world.globalObjects.append(ceiling)

        ceiling.setExamineHandler { obj in
            print("Nothing really noticeable about the ceiling.")
            return true
        }

        // Darkness
        let darkness = GameObject(
            name: "darkness",
            description: "It's too dark to see anything.",
            flags: .omitArticle,
            synonyms: "dark"
        )
        world.globalObjects.append(darkness)

        darkness.setCustomCommandHandler(verb: "think-about") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                print("Light, darkness. Your favorite cloak has something to do with them, yes?")
                return true
            }
            return false
        }

        // Rug - as a local-global object
        let rug = GameObject(
            name: "rug",
            description: "A tatty old rug."
        )

        rug.setCustomCommandHandler(verb: "put-on") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                print("You don't want to place anything on that tatty rug.")
                return true
            }
            return false
        }

        let foyer = try world.find(room: "Foyer of the Opera House")
        foyer.addLocalGlobal(rug)

        let bar = try world.find(room: "Foyer Bar")
        bar.addLocalGlobal(rug)

        world.register(rug)

        // Sign in hallway
        let sign = GameObject(
            name: "sign",
            description: "It's a block of grey wood bearing hastily-painted words.",
            location: hallToStudy,
            flags: .isReadable
        )
        sign.firstDescription = "A crude wooden sign hangs above the western exit."
        sign.text = "It reads, 'Welcome to the Study'"
        world.register(sign)
    }

    /// Creates objects for the hallway to study.
    /// - Parameters:
    ///   - world: The game world.
    ///   - hallToStudy: The hallway to study.
    private static func createHallwayObjects(world: GameWorld, hallToStudy: Room) {
        // Sign is created in globalObjects since it's referenced there
    }

    /// Creates the player's initial inventory.
    /// - Parameter world: The game world.
    private static func createPlayerInventory(world: GameWorld) {
        // Cloak
        let cloak = GameObject(
            name: "cloak",
            description: "The cloak is unnaturally dark.",
            location: world.player,
            flags: .isTakable, .isWearable, .isBeingWorn,
            synonyms: "garment", "cloth"
        )
        world.register(cloak)

        cloak.setExamineHandler { obj in
            print("The cloak is unnaturally dark.")
            return true
        }
    }

    /// Creates objects for the study room.
    /// - Parameters:
    ///   - world: The game world.
    ///   - study: The study room.
    private static func createStudyObjects(world: GameWorld, study: Room) {
        // Light switch
        let lightSwitch = GameObject(
            name: "light switch",
            description: "An ordinary light switch.",
            location: study,
            flags: .isDevice,
            synonyms: "switch"
        )
        world.register(lightSwitch)

        lightSwitch.setExamineHandler { obj in
            print(
                "An ordinary light switch set in the wall to the left of the entrance to the closet. It is currently ",
                terminator: "")
            if obj.hasFlag(.isOn) {
                print("on.")
            } else {
                print("off.")
            }
            return true
        }

        lightSwitch.setCustomCommandHandler(verb: "turn-on") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                obj.setFlag(.isOn)

                // Find the player using the findPlayer helper
                if let room = obj.location as? Room,
                    let player = room.findPlayer(),
                    let currentRoom = player.currentRoom,
                    currentRoom.name == "Closet"
                {
                    currentRoom.setFlag(.isOn)
                    print("The closet lights up!")
                }

                print("You switch on the light switch.")
                return true
            }
            return false
        }

        lightSwitch.setCustomCommandHandler(verb: "turn-off") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                obj.clearFlag(.isOn)

                // Find the player using the findPlayer helper
                if let room = obj.location as? Room,
                    let player = room.findPlayer(),
                    let currentRoom = player.currentRoom,
                    currentRoom.name == "Closet"
                {
                    currentRoom.clearFlag(.isOn)
                    print("The closet goes dark!")
                }

                print("You switch off the light switch.")
                return true
            }
            return false
        }

        lightSwitch.setCustomCommandHandler(verb: "flip") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                if obj.hasFlag(.isOn) {
                    // Turn it off
                    obj.clearFlag(.isOn)

                    // Find the player using the findPlayer helper
                    if let room = obj.location as? Room,
                        let player = room.findPlayer(),
                        let currentRoom = player.currentRoom,
                        currentRoom.name == "Closet"
                    {
                        currentRoom.clearFlag(.isOn)
                        print("The closet goes dark!")
                    }

                    print("You switch off the light switch.")
                } else {
                    // Turn it on
                    obj.setFlag(.isOn)

                    // Find the player using the findPlayer helper
                    if let room = obj.location as? Room,
                        let player = room.findPlayer(),
                        let currentRoom = player.currentRoom,
                        currentRoom.name == "Closet"
                    {
                        currentRoom.setFlag(.isOn)
                        print("The closet lights up!")
                    }

                    print("You switch on the light switch.")
                }
                return true
            }
            return false
        }

        // Flashlight
        let flashlight = GameObject(
            name: "flashlight",
            description: "A cheap plastic flashlight.",
            location: study,
            flags: .isDevice, .isTakable,
            synonyms: "torch", "light"
        )
        world.register(flashlight)

        flashlight.setExamineHandler { obj in
            print("A cheap plastic flashlight. It is currently ", terminator: "")
            if obj.hasFlag(.isOn) {
                print("on.")
            } else {
                print("off.")
            }
            return true
        }

        flashlight.setCustomCommandHandler(verb: "turn-on") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                if obj.hasFlag(.isOn) {
                    print("It's already on.")
                } else {
                    obj.setFlag(.isOn)
                    obj.setFlag(.isLightSource)
                    obj.setFlag(.isOn)
                    print("You switch on the flashlight.")

                    // Find the player using the findPlayer helper
                    if let player = obj.findPlayer(),
                        let currentRoom = player.currentRoom,
                        !currentRoom.hasFlag(.isOn) && !currentRoom.hasFlag(.isNaturallyLit)
                    {
                        currentRoom.setFlag(.isOn)
                        print("The flashlight illuminates the area!")
                    }
                }
                return true
            }
            return false
        }

        flashlight.setCustomCommandHandler(verb: "turn-off") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                if !obj.hasFlag(.isOn) {
                    print("It's already off.")
                } else {
                    obj.clearFlag(.isOn)
                    obj.clearFlag(.isOn)
                    print("You switch off the flashlight.")

                    // Find the player using the findPlayer helper
                    if let player = obj.findPlayer(),
                        let currentRoom = player.currentRoom,
                        !currentRoom.hasFlag(.isNaturallyLit)
                    {
                        // Check if room should now be dark
                        let hasOtherLight = player.inventory.contains {
                            $0.hasFlag(.isLightSource) && $0.hasFlag(.isOn) && $0 !== obj
                        }
                        if !hasOtherLight {
                            currentRoom.clearFlag(.isOn)
                            print("The area goes dark!")
                        }
                    }
                }
                return true
            }
            return false
        }

        flashlight.setCustomCommandHandler(verb: "flip") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                if obj.hasFlag(.isOn) {
                    // Turn it off
                    obj.clearFlag(.isOn)
                    obj.clearFlag(.isOn)
                    print("You switch off the flashlight.")

                    // Find the player using the findPlayer helper
                    if let player = obj.findPlayer(),
                        let currentRoom = player.currentRoom,
                        !currentRoom.hasFlag(.isNaturallyLit)
                    {
                        // Check if room should now be dark
                        let hasOtherLight = player.inventory.contains {
                            $0.hasFlag(.isLightSource) && $0.hasFlag(.isOn) && $0 !== obj
                        }
                        if !hasOtherLight {
                            currentRoom.clearFlag(.isOn)
                            print("The area goes dark!")
                        }
                    }
                } else {
                    // Turn it on
                    obj.setFlag(.isOn)
                    obj.setFlag(.isLightSource)
                    obj.setFlag(.isOn)
                    print("You switch on the flashlight.")

                    // Find the player using the findPlayer helper
                    if let player = obj.findPlayer(),
                        let currentRoom = player.currentRoom,
                        !currentRoom.hasFlag(.isOn) && !currentRoom.hasFlag(.isNaturallyLit)
                    {
                        currentRoom.setFlag(.isOn)
                        print("The flashlight illuminates the area!")
                    }
                }
                return true
            }
            return false
        }

        // Stand
        let stand = GameObject(
            name: "stand",
            description: "A worn wooden stand.",
            location: study,
            flags: .isContainer, .isSurface
        )
        stand.setCapacity(to: 15)
        world.register(stand)

        // Book
        let book = GameObject(
            name: "book",
            description: "A tattered hard-cover book with a red binding.",
            location: stand,
            flags: .isTakable, .isReadable,
            synonyms: "tome", "volume"
        )
        book.text =
            "It tells of an adventurer who was tasked with testing out a library that was old and new at the same time."
        world.register(book)

        // Other study objects
        let safe = GameObject(
            name: "safe",
            description: "A small wall safe.",
            location: study,
            flags: .isContainer, .isOpenable
        )
        world.register(safe)

        let bill = GameObject(
            name: "dollar",
            description: "A crisp one-dollar bill.",
            location: safe,
            flags: .isTakable,
            synonyms: "bill"
        )
        world.register(bill)

        let glassCase = GameObject(
            name: "case",
            description: "A large glass case.",
            location: study,
            flags: .isContainer, .isTransparent,
            synonyms: "display", "container"
        )
        world.register(glassCase)

        let muffin = GameObject(
            name: "muffin",
            description: "A tasty-looking muffin.",
            location: glassCase,
            flags: .isTakable, .isEdible
        )
        world.register(muffin)

        let sphere = GameObject(
            name: "sphere",
            description: "A glass sphere.",
            location: study,
            flags: .isTakable, .isTransparent, .isContainer
        )
        world.register(sphere)

        let firefly = GameObject(
            name: "firefly",
            description: "A tiny but brightly glowing firefly.",
            location: sphere,
            flags: .isTakable, .isOn
        )
        world.register(firefly)

        let wallet = GameObject(
            name: "wallet",
            description: "A leather wallet.",
            location: study,
            flags: .isContainer, .isTakable, .isOpenable
        )
        wallet.setCapacity(to: 2)
        world.register(wallet)

        let jar = GameObject(
            name: "jar",
            description: "A glass jar.",
            location: stand,
            flags: .isContainer, .isOpen, .isTakable
        )
        jar.setCapacity(to: 6)
        world.register(jar)

        let plum = GameObject(
            name: "plum",
            description: "A ripe purple plum.",
            location: jar,
            flags: .isTakable, .isEdible
        )
        world.register(plum)

        let crate = GameObject(
            name: "crate",
            description: "A wooden crate.",
            location: study,
            flags: .isContainer
        )
        crate.setCapacity(to: 15)
        world.register(crate)

        let tray = GameObject(
            name: "tray",
            description: "A serving tray.",
            location: stand,
            flags: .isContainer, .isTakable, .isSurface
        )
        tray.setCapacity(to: 11)
        world.register(tray)
    }

    // MARK: - Command Handler Functions

    static func handleAppleCommands(_ obj: GameObject, _ command: Command) -> Bool {
        switch command {
        case .examine(let target, _) where target === obj:
            print("The apple is green and tasty-looking.")
            if let world = obj.findWorld() {
                world.eventManager.scheduleEvent(
                    name: "I-APPLE-FUN",
                    turns: 3,
                    action: { true }
                )
            }
            return true
        case .eat(let target) where target === obj:
            print("Oh no! It was actually a poison apple (mostly so we could test JIGS-UP).")
            if let player = obj.findPlayer() {
                player.engine.gameOver(message: "You've been poisoned by the apple.")
            }
            return true
        default:
            break
        }
        return false
    }

    static func handleMessageCommands(_ obj: GameObject, _ command: Command) -> Bool {
        switch command {
        case .examine(let target, _) where target === obj:
            let room = obj.location as? Room
            let disturbed = (room?.disturbed as Int?) ?? 0

            print("The message simply reads: \"You ", terminator: "")
            if disturbed > 1 {
                print("lose.\"")
                if let player = obj.findPlayer() {
                    player.engine.gameOver(message: "You lose", isVictory: false)
                }
            } else {
                print("win.\"")
                if let player = obj.findPlayer() {
                    player.engine.gameOver(message: "You win", isVictory: true)
                }
            }
            return true
        default:
            break
        }
        return false
    }
}
