import Foundation
import ZILFCore

// MARK: - Command Handler Functions
private func handleAppleCommands(_ obj: GameObject, _ command: Command) -> Bool {
    if case .examine = command {
        print("A bright red apple. It looks delicious.")
        return true
    } else if case .customCommand(let verb, let objects, _) = command, verb == "eat" {
        if objects.contains(where: { $0 === obj }) {
            print("Oh no! It was actually a poison apple (mostly so we could test JIGS-UP).")
            let engine: GameEngine? = obj.location?.getState(forKey: "engine")
            engine?.gameOver(message: "You've been poisoned by the apple.")
            return true
        }
    }
    return false
}

private func handleMessageCommands(_ obj: GameObject, _ command: Command) -> Bool {
    if case .examine = command {
        let room = obj.location as? Room
        let disturbed: Int = room?.getState(forKey: "disturbed") ?? 0

        if disturbed > 1 {
            print("The message simply reads: \"You lose.\"")
            let engine: GameEngine? = obj.location?.getState(forKey: "engine")
            engine?.gameOver(message: "You lose", isVictory: false)
        } else {
            print("The message simply reads: \"You win.\"")
            let engine: GameEngine? = obj.location?.getState(forKey: "engine")
            engine?.gameOver(message: "You win", isVictory: true)
        }
        return true
    }
    return false
}

// MARK: - Command Verbs
public extension String {
    static let examine = "examine"
    static let eat = "eat"
    static let read = "read"
    static let thinkAbout = "think-about"
    static let putOn = "put-on"
    static let turnOn = "turn-on"
    static let turnOff = "turn-off"
    static let flip = "flip"
}

// MARK: - Directions
public extension String {
    static let north = "north"
    static let south = "south"
    static let east = "east"
    static let west = "west"
}

/// Implementation of the classic "Cloak of Darkness" demo game.
/// Converted from the ZIL implementation to Swift using ZILFCore.
public enum CloakOfDarkness {
    /// Creates and returns the game world with all rooms, objects, and game logic
    public static func create() -> GameWorld {
        // First create rooms since we need a starting room for the player
        let foyer = createFoyer()
        let bar = createBar()
        let cloakroom = createCloakroom()
        let hallToStudy = createHallToStudy()
        let study = createStudy()
        let closet = createCloset()

        // Create player and world (player needs a starting room)
        let player = Player(startingRoom: foyer)
        let world = GameWorld(player: player)

        // Set up exits
        foyer.exits = [
            .south: bar,
            .west: cloakroom
        ]

        bar.exits = [
            .north: foyer
        ]

        cloakroom.exits = [
            .east: foyer
        ]

        hallToStudy.exits = [
            .east: cloakroom,
            .west: study
        ]

        study.exits = [
            .east: hallToStudy,
            .west: closet
        ]

        closet.exits = [
            .east: study
        ]

        // Register rooms with the world
        world.registerRoom(foyer)
        world.registerRoom(bar)
        world.registerRoom(cloakroom)
        world.registerRoom(hallToStudy)
        world.registerRoom(study)
        world.registerRoom(closet)

        // Create objects and populate the world
        createObjects(world: world, foyer: foyer, bar: bar, cloakroom: cloakroom,
                     hallToStudy: hallToStudy, study: study, closet: closet)

        return world
    }

    // MARK: - Room Creation

    private static func createFoyer() -> Room {
        let foyer = Room(
            name: "Foyer of the Opera House",
            description: "You are standing in a spacious hall, splendidly decorated in red and gold, with glittering chandeliers overhead. The entrance from the street is to the north, and there are doorways south and west."
        )

        foyer.setFlag(.naturallyLit)

        // Foyer end-turn action
        foyer.endTurnAction = { (room: Room) -> Bool in
            // For the end-turn action, we'll check for the named events
            // We access the engine through the player object
            let engine: GameEngine? = room.location?.getState(forKey: "engine")
            let world = engine?.world

            // Return true if any of these events are in progress
            if world?.isEventScheduled(named: "I-APPLE-FUN") == true {
                print("The Foyer routine detects that the Apple event will run this turn!")
                return true
            }
            if world?.isEventScheduled(named: "I-TABLE-FUN") == true {
                print("The Foyer routine detects that the Table event will run this turn!")
                return true
            }
            return false
        }

        return foyer
    }

    private static func createBar() -> Room {
        let bar = Room(
            name: "Foyer Bar",
            description: "The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty."
        )

        // Bar enter action - handle lighting based on cloak
        bar.enterAction = { (room: Room) -> Bool in
            let engine: GameEngine? = room.location?.getState(forKey: "engine")
            let world = engine?.world
            let player = world?.player

            // Check if player has cloak in inventory (worn or carried)
            let hasCloak = player?.contents.contains { $0.name == "cloak" } ?? false

            // Always set initial lighting state when entering
            if hasCloak {
                // If player has cloak, room should be dark
                room.clearFlag(.lit)
                print("You enter the dimly lit bar. It's hard to see anything.")
                return true
            } else {
                // If player doesn't have cloak, room should be lit
                room.setFlag(.lit)
                print("You enter the bar. It's empty but well-lit now.")
                return true
            }
        }

        // Bar begin-turn action - handle stumbling in dark
        bar.beginTurnAction = { (room: Room) -> Bool in
            if !room.hasFlag(.lit) {
                let engine: GameEngine? = room.location?.getState(forKey: "engine")
                let command: Command? = engine?.getState(forKey: "currentCommand")

                // Skip this effect for certain commands
                if let command = command {
                    switch command {
                    case .look:
                        print("It's pitch black here. You can't see anything.")
                        return true
                    case .move(let direction) where direction == .north:
                        return false
                    case .customCommand(let verb, _, _) where verb == "think-about":
                        return false
                    default:
                        // Continue with the dark room handling
                        break
                    }
                }

                print("You grope around clumsily in the dark. Better be careful.")

                // Update disturbed counter
                let disturbed: Int = room.getState(forKey: "disturbed") ?? 0
                room.setState(disturbed + 1, forKey: "disturbed")

                return true
            }
            return false
        }

        // Initialize disturbed counter
        bar.setState(0, forKey: "disturbed")

        return bar
    }

    private static func createCloakroom() -> Room {
        let cloakroom = Room(
            name: "Cloakroom",
            description: "The walls of this small room were clearly once lined with hooks, though now only one remains. The exit is a door to the east, but there is also a cramped opening to the west."
        )
        cloakroom.setFlag(.naturallyLit)

        // We'll use beginCommandAction to handle the special exit
        cloakroom.beginCommandAction = { (room: Room, command: Command) -> Bool in
            guard case .move(.west) = command else { return false }

            let engine: GameEngine? = room.location?.getState(forKey: "engine")
            let world = engine?.world
            let player = world?.player

            // Check if the player is wearing/carrying the cloak
            let hasCloak = player?.contents.contains { $0.name == "cloak" } ?? false

            if hasCloak {
                print("You cannot enter the opening to the west while in possession of your cloak.")
                return true
            } else {
                if let hallToStudy = world?.rooms.first(where: { $0.name == "Hallway to Study" }) {
                    // This is critical - the test expects this specific message
                    print("Oof - it's cramped in here.")

                    // Move the player to the hallway
                    if let player = player, let currentRoom = player.currentRoom {
                        // Remove player from current room
                        if let index = currentRoom.contents.firstIndex(where: { $0 === player }) {
                            currentRoom.contents.remove(at: index)
                        }

                        // Add player to hallway
                        player.location = hallToStudy
                        hallToStudy.contents.append(player)
                    }

                    return true
                }
            }

            return false
        }

        return cloakroom
    }

    private static func createHallToStudy() -> Room {
        let hallToStudy = Room(
            name: "Hallway to Study",
            description: "The hallway leads to a Study to the west, and back to the Cloakroom to the east."
        )
        hallToStudy.setFlag(.naturallyLit)

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

    private static func createStudy() -> Room {
        let study = Room(
            name: "Study",
            description: "A small room with a worn stand in the middle. A hallway lies east of here, a closet off to the west."
        )
        study.setFlag(.naturallyLit)

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

    private static func createCloset() -> Room {
        let closet = Room(
            name: "Closet",
            description: "A cramped excuse of a closet."
        )

        // Closet enter action - update lighting based on switch
        closet.enterAction = { (room: Room) -> Bool in
            let engine: GameEngine? = room.location?.getState(forKey: "engine")
            let world = engine?.world

            if let study = world?.rooms.first(where: { $0.name == "Study" }),
               let lightSwitch = study.contents.first(where: { $0.name == "light switch" }) {
                if lightSwitch.hasFlag(.onBit) {
                    room.setFlag(.lit)
                } else {
                    room.clearFlag(.lit)
                }
            }
            return false
        }

        return closet
    }

    // MARK: - Object Creation

    private static func createObjects(world: GameWorld, foyer: Room, bar: Room, cloakroom: Room,
                                     hallToStudy: Room, study: Room, closet: Room) {
        // Create all game objects and register them with the world

        // Create foyer objects
        createFoyerObjects(world: world, foyer: foyer)

        // Create bar objects
        createBarObjects(world: world, bar: bar)

        // Create cloakroom objects
        createCloakroomObjects(world: world, cloakroom: cloakroom)

        // Create hallway objects
        createHallwayObjects(world: world, hallToStudy: hallToStudy)

        // Create study objects
        createStudyObjects(world: world, study: study)

        // Create global objects
        createGlobalObjects(world: world, foyer: foyer, bar: bar)

        // Create starting inventory (cloak)
        createPlayerInventory(world: world)
    }

    private static func createFoyerObjects(world: GameWorld, foyer: Room) {
        // Apple
        let apple = GameObject(name: "apple", description: "The apple is green and tasty-looking.")
        apple.location = foyer
        apple.setFlag(.takeBit)
        apple.setFlag(.edibleBit)
        apple.setFlag(.vowelBit)
        world.registerObject(apple)

        // Apple command handlers
        apple.setExamineHandler { obj in
            print("A bright red apple. It looks delicious.")
            return true
        }

        apple.setCustomCommandHandler(verb: "eat") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                print("Oh no! It was actually a poison apple (mostly so we could test JIGS-UP).")
                let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                engine?.gameOver(message: "You've been poisoned by the apple.")
                return true
            }
            return false
        }

        // Grime
        let grime = GameObject(name: "grime", description: "A small but disgusting collection of crud.")
        grime.location = foyer
        grime.setFlag(.takeBit)
        grime.setFlag(.nArticleBit)
        world.registerObject(grime)

        // Grime command handler
        grime.setExamineHandler { obj in
            print("A small but disgusting collection of crud.")
            let engine: GameEngine? = obj.location?.getState(forKey: "engine")
            let world = engine?.world
            _ = world?.queueEvent(name: "I-GRIME-FUN", turns: 2) {
                print("You looked at grime 1 turn ago!")
                return true
            }
            return true
        }

        // Cube
        let cube = GameObject(name: "cube", description: "A plain-looking cube.")
        cube.location = foyer
        cube.setFlag(.takeBit)
        world.registerObject(cube)

        // Cube command handler
        cube.setExamineHandler { obj in
            print("As you inspected the cube you realized time around you speeds by.")
            let engine: GameEngine? = obj.location?.getState(forKey: "engine")
            let world = engine?.world
            _ = world?.waitTurns(10)
            return true
        }

        // Table
        let table = GameObject(name: "table", description: "Tatty but functional.")
        table.location = foyer
        table.setFlag(.contBit)
        table.setFlag(.surfaceBit)
        world.registerObject(table)

        // Table command handler
        table.setExamineHandler { obj in
            print("Tatty but functional.")
            if obj.contents.count > 0 {
                print("On the table you can see:")
                for item in obj.contents {
                    print("  \(item.name)")
                }
            }
            let engine: GameEngine? = obj.location?.getState(forKey: "engine")
            let world = engine?.world
            _ = world?.queueEvent(name: "I-TABLE-FUN", turns: -1) {
                print("You examined a table and now this event will run every turn, until you examined the brass hook, which will dequeue it.")
                return true
            }
            return true
        }

        // Changing Painting
        let changingPainting = GameObject(name: "painting", description: "A peculiar painting that seems to change.")
        changingPainting.location = foyer
        world.registerObject(changingPainting)

        // Painting command handlers
        changingPainting.setExamineHandler { obj in
            let descriptions = [
                "It shows a dancing bear.",
                "It displays a clown walking on its hands.",
                "It shows a horse eating a shoe.",
                "It shows a man hunting for a copy of Zork.",
                "It displays a cat that is laughing.",
                "It displays a machine marked with a Z."
            ]
            print(descriptions.randomElement()!)
            return true
        }

        changingPainting.setCustomCommandHandler(verb: "read") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                let signatures = ["Micheangelo.", "Phil Collins.", "The Dude."]
                print("The signature at the bottom rearranges itself to read \(signatures.randomElement()!)")
                return true
            }
            return false
        }

        // Playing Card
        let card = GameObject(name: "card", description: "A playing card.")
        card.location = table
        card.setFlag(.takeBit)
        world.registerObject(card)

        // Card command handler
        card.setExamineHandler { obj in
            let cardDescriptions = ["Ace of Spades.", "The Hermit.", "The Weeping Joker."]
            print(cardDescriptions.randomElement()!)
            return true
        }

        // Grapes
        let grapes = GameObject(name: "grapes", description: "A bunch of grapes.")
        grapes.location = table
        grapes.setFlag(.takeBit)
        grapes.setFlag(.edibleBit)
        grapes.setFlag(.pluralBit)
        grapes.setFlag(.nArticleBit)
        world.registerObject(grapes)

        // Pets
        let bentley = GameObject(name: "Bentley", description: "Bentley is a gray striped cat. He is in a deep sleep.")
        bentley.location = foyer
        bentley.setFlag(.personBit)
        bentley.setFlag(.nArticleBit)
        world.registerObject(bentley)

        let stella = GameObject(name: "Stella", description: "Stella is a brown corgi. She is in a deep sleep.")
        stella.location = foyer
        stella.setFlag(.personBit)
        stella.setFlag(.nArticleBit)
        stella.setFlag(.femaleBit)
        world.registerObject(stella)
    }

    private static func createBarObjects(world: GameWorld, bar: Room) {
        // Message
        let message = GameObject(name: "message", description: "A message scrawled in the sawdust.")
        message.location = bar
        message.setState("There seems to be some sort of message scrawled in the sawdust on the floor.", forKey: "firstDescription")
        world.registerObject(message)

        // Message command handler
        message.setExamineHandler { obj in
            let room = obj.location as? Room
            let disturbed: Int = room?.getState(forKey: "disturbed") ?? 0
            let engine: GameEngine? = obj.location?.getState(forKey: "engine")

            if disturbed > 1 {
                print("The message simply reads: \"You lose.\"")
                // Make sure this is called last, as it may terminate execution
                if let engine = engine {
                    engine.gameOver(message: "You lose", isVictory: false)
                }
            } else {
                print("The message simply reads: \"You win.\"")
                // Make sure this is called last, as it may terminate execution
                if let engine = engine {
                    engine.gameOver(message: "You win", isVictory: true)
                }
            }

            return true
        }
    }

    private static func createCloakroomObjects(world: GameWorld, cloakroom: Room) {
        // Hook
        let hook = GameObject(name: "small brass hook", description: "A small brass hook is on the wall.")
        hook.location = cloakroom
        hook.setFlag(.contBit)
        hook.setFlag(.surfaceBit)
        world.registerObject(hook)

        // Hook command handler
        hook.setExamineHandler { obj in
            print("Test: Normal examine replaced by a dequeue of the Table event.")
            let engine: GameEngine? = obj.location?.getState(forKey: "engine")
            let world = engine?.world
            _ = world?.dequeueEvent(named: "I-TABLE-FUN")
            return true
        }
    }

    private static func createHallwayObjects(world: GameWorld, hallToStudy: Room) {
        // Sign
        let sign = GameObject(name: "sign", description: "It's a block of grey wood bearing hastily-painted words.")
        sign.location = hallToStudy
        sign.setFlag(.readBit)
        sign.setState("A crude wooden sign hangs above the western exit.", forKey: "firstDescription")
        sign.setState("It reads, 'Welcome to the Study'", forKey: "text")
        world.registerObject(sign)
    }

    private static func createStudyObjects(world: GameWorld, study: Room) {
        // Light switch
        let lightSwitch = GameObject(name: "light switch", description: "An ordinary light switch.")
        lightSwitch.location = study
        lightSwitch.setFlag(.deviceBit)
        world.registerObject(lightSwitch)

        // Light switch command handlers
        lightSwitch.setCommandHandlers(handlers: [
            "examine": { obj in
                print("An ordinary light switch set in the wall to the left of the entrance to the closet. It is currently ", terminator: "")
                if obj.hasFlag(.onBit) {
                    print("on.")
                } else {
                    print("off.")
                }
                return true
            }
        ])

        lightSwitch.setCustomCommandHandler(verb: "turn-on") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                obj.setFlag(.onBit)

                // If player is in the closet, update lighting
                let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                let world = engine?.world
                if let currentRoom = world?.player.currentRoom,
                   currentRoom.name == "Closet" {
                    currentRoom.setFlag(.lit)
                    print("The closet lights up!")
                }

                print("You switch on the light switch.")
                return true
            }
            return false
        }

        lightSwitch.setCustomCommandHandler(verb: "turn-off") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                obj.clearFlag(.onBit)

                // If player is in the closet, update lighting
                let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                let world = engine?.world
                if let currentRoom = world?.player.currentRoom,
                   currentRoom.name == "Closet" {
                    currentRoom.clearFlag(.lit)
                    print("The closet goes dark!")
                }

                print("You switch off the light switch.")
                return true
            }
            return false
        }

        lightSwitch.setCustomCommandHandler(verb: "flip") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                if obj.hasFlag(.onBit) {
                    // Turn it off
                    obj.clearFlag(.onBit)

                    // If player is in the closet, update lighting
                    let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                    let world = engine?.world
                    if let currentRoom = world?.player.currentRoom,
                       currentRoom.name == "Closet" {
                        currentRoom.clearFlag(.lit)
                        print("The closet goes dark!")
                    }

                    print("You switch off the light switch.")
                } else {
                    // Turn it on
                    obj.setFlag(.onBit)

                    // If player is in the closet, update lighting
                    let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                    let world = engine?.world
                    if let currentRoom = world?.player.currentRoom,
                       currentRoom.name == "Closet" {
                        currentRoom.setFlag(.lit)
                        print("The closet lights up!")
                    }

                    print("You switch on the light switch.")
                }
                return true
            }
            return false
        }

        // Flashlight
        let flashlight = GameObject(name: "flashlight", description: "A cheap plastic flashlight.")
        flashlight.location = study
        flashlight.setFlag(.deviceBit)
        flashlight.setFlag(.takeBit)
        world.registerObject(flashlight)

        // Flashlight command handler
        flashlight.setExamineHandler { obj in
            print("A cheap plastic flashlight. It is currently ", terminator: "")
            if obj.hasFlag(.onBit) {
                print("on.")
            } else {
                print("off.")
            }
            return true
        }

        flashlight.setCustomCommandHandler(verb: "turn-on") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                if obj.hasFlag(.onBit) {
                    print("It's already on.")
                } else {
                    obj.setFlag(.onBit)
                    obj.setFlag(.lightSource)
                    obj.setFlag(.lit)
                    print("You switch on the flashlight.")

                    // Update room lighting if needed
                    let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                    let world = engine?.world
                    if let room = world?.player.currentRoom,
                       !room.hasFlag(.lit) && !room.hasFlag(.naturallyLit) {
                        room.setFlag(.lit)
                        print("The flashlight illuminates the area!")
                    }
                }
                return true
            }
            return false
        }

        flashlight.setCustomCommandHandler(verb: "turn-off") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                if !obj.hasFlag(.onBit) {
                    print("It's already off.")
                } else {
                    obj.clearFlag(.onBit)
                    obj.clearFlag(.lit)
                    print("You switch off the flashlight.")

                    // Update room lighting if needed
                    let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                    let world = engine?.world
                    if let room = world?.player.currentRoom,
                       !room.hasFlag(.naturallyLit) {
                        // Check if room should now be dark
                        if let player = world?.player {
                            let hasOtherLight = player.contents.contains {
                                $0.hasFlag(.lightSource) && $0.hasFlag(.lit) && $0 !== obj
                            }
                            if !hasOtherLight {
                                room.clearFlag(.lit)
                                print("The area goes dark!")
                            }
                        }
                    }
                }
                return true
            }
            return false
        }

        flashlight.setCustomCommandHandler(verb: "flip") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                if obj.hasFlag(.onBit) {
                    // Turn it off
                    obj.clearFlag(.onBit)
                    obj.clearFlag(.lit)
                    print("You switch off the flashlight.")

                    // Update room lighting if needed
                    let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                    let world = engine?.world
                    if let room = world?.player.currentRoom,
                       !room.hasFlag(.naturallyLit) {
                        // Check if room should now be dark
                        if let player = world?.player {
                            let hasOtherLight = player.contents.contains {
                                $0.hasFlag(.lightSource) && $0.hasFlag(.lit) && $0 !== obj
                            }
                            if !hasOtherLight {
                                room.clearFlag(.lit)
                                print("The area goes dark!")
                            }
                        }
                    }
                } else {
                    // Turn it on
                    obj.setFlag(.onBit)
                    obj.setFlag(.lightSource)
                    obj.setFlag(.lit)
                    print("You switch on the flashlight.")

                    // Update room lighting if needed
                    let engine: GameEngine? = obj.location?.getState(forKey: "engine")
                    let world = engine?.world
                    if let room = world?.player.currentRoom,
                       !room.hasFlag(.lit) && !room.hasFlag(.naturallyLit) {
                        room.setFlag(.lit)
                        print("The flashlight illuminates the area!")
                    }
                }
                return true
            }
            return false
        }

        // Stand
        let stand = GameObject(name: "stand", description: "A worn wooden stand.")
        stand.location = study
        stand.setFlag(.contBit)
        stand.setFlag(.surfaceBit)
        stand.capacity = 15
        world.registerObject(stand)

        // Book
        let book = GameObject(name: "book", description: "A tattered hard-cover book with a red binding.")
        book.location = stand
        book.setFlag(.takeBit)
        book.setFlag(.readBit)
        book.setState("It tells of an adventurer who was tasked with testing out a library that was old and new at the same time.", forKey: "text")
        world.registerObject(book)

        // Other study objects
        let safe = GameObject(name: "safe", description: "A small wall safe.")
        safe.location = study
        safe.setFlag(.contBit)
        safe.setFlag(.openableBit)
        world.registerObject(safe)

        let bill = GameObject(name: "dollar", description: "A crisp one-dollar bill.")
        bill.location = safe
        bill.setFlag(.takeBit)
        world.registerObject(bill)

        let glassCase = GameObject(name: "case", description: "A large glass case.")
        glassCase.location = study
        glassCase.setFlag(.contBit)
        glassCase.setFlag(.transBit)
        world.registerObject(glassCase)

        let muffin = GameObject(name: "muffin", description: "A tasty-looking muffin.")
        muffin.location = glassCase
        muffin.setFlag(.takeBit)
        muffin.setFlag(.edibleBit)
        world.registerObject(muffin)

        let sphere = GameObject(name: "sphere", description: "A glass sphere.")
        sphere.location = study
        sphere.setFlag(.takeBit)
        sphere.setFlag(.transBit)
        sphere.setFlag(.contBit)
        world.registerObject(sphere)

        let firefly = GameObject(name: "firefly", description: "A tiny but brightly glowing firefly.")
        firefly.location = sphere
        firefly.setFlag(.takeBit)
        firefly.setFlag(.lightSource)
        firefly.setFlag(.lit)
        world.registerObject(firefly)

        let wallet = GameObject(name: "wallet", description: "A leather wallet.")
        wallet.location = study
        wallet.setFlag(.contBit)
        wallet.setFlag(.takeBit)
        wallet.setFlag(.openableBit)
        wallet.capacity = 2
        world.registerObject(wallet)

        let jar = GameObject(name: "jar", description: "A glass jar.")
        jar.location = stand
        jar.setFlag(.contBit)
        jar.setFlag(.openBit)
        jar.setFlag(.takeBit)
        jar.capacity = 6
        world.registerObject(jar)

        let plum = GameObject(name: "plum", description: "A ripe purple plum.")
        plum.location = jar
        plum.setFlag(.takeBit)
        plum.setFlag(.edibleBit)
        world.registerObject(plum)

        let crate = GameObject(name: "crate", description: "A wooden crate.")
        crate.location = study
        crate.setFlag(.contBit)
        crate.capacity = 15
        world.registerObject(crate)

        let tray = GameObject(name: "tray", description: "A serving tray.")
        tray.location = stand
        tray.setFlag(.contBit)
        tray.setFlag(.takeBit)
        tray.setFlag(.surfaceBit)
        tray.capacity = 11
        world.registerObject(tray)
    }

    private static func createGlobalObjects(world: GameWorld, foyer: Room, bar: Room) {
        // Ceiling (global object)
        let ceiling = GameObject(name: "ceiling", description: "Nothing really noticeable about the ceiling.")
        world.globalObjects.append(ceiling)

        // Ceiling command handler
        ceiling.setExamineHandler { obj in
            print("Nothing really noticeable about the ceiling.")
            return true
        }

        // Darkness (global object)
        let darkness = GameObject(name: "darkness", description: "It's too dark to see anything.")
        darkness.setFlag(.nArticleBit)
        world.globalObjects.append(darkness)

        // Darkness command handler
        darkness.setCustomCommandHandler(verb: "think-about") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                print("Light, darkness. Your favorite cloak has something to do with them, yes?")
                return true
            }
            return false
        }

        // Rug (local global object)
        let rug = GameObject(name: "rug", description: "A tatty old rug.")

        // Rug command handler
        rug.setCustomCommandHandler(verb: "put-on") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                print("You don't want to place anything on that tatty rug.")
                return true
            }
            return false
        }

        // Add rug to foyer and bar locations only
        foyer.addLocalGlobal(rug)
        bar.addLocalGlobal(rug)
        world.registerObject(rug)
    }

    private static func createPlayerInventory(world: GameWorld) {
        // Cloak
        let cloak = GameObject(name: "cloak", description: "The cloak is unnaturally dark.")
        // We need to explicitly add it to the player's contents
        world.player.contents.append(cloak)
        // Then set the location afterwards
        cloak.location = world.player
        cloak.setFlag(.takeBit)
        cloak.setFlag(.wearBit)
        cloak.setFlag(.wornBit)
        world.registerObject(cloak)

        // Cloak command handler
        cloak.setExamineHandler { obj in
            print("The cloak is unnaturally dark.")
            return true
        }
    }
}
