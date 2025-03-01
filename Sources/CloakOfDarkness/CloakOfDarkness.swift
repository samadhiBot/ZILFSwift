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
            // Use our new helper method to find the player
            if let player = obj.findPlayer() {
                player.engine.gameOver(message: "You've been poisoned by the apple.")
            }
            return true
        }
    }
    return false
}

private func handleMessageCommands(_ obj: GameObject, _ command: Command) -> Bool {
    if case .examine = command {
        let room = obj.location as? Room
        let disturbed = (room?.disturbed as Int?) ?? 0

        if disturbed > 1 {
            print("The message simply reads: \"You lose.\"")
            // Use our new findPlayer helper method
            if let player = obj.findPlayer() {
                player.engine.gameOver(message: "You lose", isVictory: false)
            }
        } else {
            print("The message simply reads: \"You win.\"")
            // Use our new findPlayer helper method
            if let player = obj.findPlayer() {
                player.engine.gameOver(message: "You win", isVictory: true)
            }
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

        // We no longer need to store the world in every object since we can access it through player
        // However, we'll temporarily keep setting these states until we update all our object handlers
        // This is a transitional solution while upgrading the API
        foyer.gameWorld = world
        bar.gameWorld = world
        cloakroom.gameWorld = world
        hallToStudy.gameWorld = world
        study.gameWorld = world
        closet.gameWorld = world

        // Register rooms with the world
        world.registerRoom(foyer)
        world.registerRoom(bar)
        world.registerRoom(cloakroom)
        world.registerRoom(hallToStudy)
        world.registerRoom(study)
        world.registerRoom(closet)

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
            // Access the world directly rather than through the player
            if let world = room.gameWorld {
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

    private static func createBar() -> Room {
        let bar = Room(
            name: "Foyer Bar",
            description: "The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty."
        )

        // Bar enter action - handle lighting based on cloak
        bar.enterAction = { (room: Room) -> Bool in
            // Use findPlayer helper to get the player
            let player = room.findPlayer()

            // Check if player has cloak in inventory
            let hasCloak = player?.contents.contains { $0.name == "cloak" } ?? false

            if hasCloak {
                // Player has cloak - set room to dark
                room.clearFlag(.lit)
                print("You enter the dimly lit bar. It's hard to see anything.")
                return true
            } else {
                // Player doesn't have cloak - set room to lit
                room.setFlag(.lit)
                print("You enter the bar. It's empty but well-lit now.")
                return true
            }
        }

        // Bar begin-turn action - handle stumbling in dark
        bar.beginTurnAction = { (room: Room) -> Bool in
            if !room.hasFlag(.lit) {
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
                if let command = command {
                    switch command {
                    case .look:
                        print("It's too dark to see.")
                        return true
                    case .move(let direction) where direction == .north:
                        return false
                    case .examine(let obj) where obj.name == "message":
                        // Allow examining the message even in the dark
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
                let disturbed: Int = room.disturbed ?? 0
                room?.disturbed = disturbed + 1

                return true
            }
            return false
        }

        // Override look handler for bar to make the description match test expectations
        bar.lookHandler = { (room: Room) -> Bool in
            if room.hasFlag(.lit) {
                print("The bar, much rougher than you'd have guessed after the opulence of the foyer to the north, is completely empty. You can see a message scrawled in the sawdust on the floor.")
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

    private static func createCloakroom() -> Room {
        let cloakroom = Room(
            name: "Cloakroom",
            description: "The walls of this small room were clearly once lined with hooks, though now only one remains. The exit is a door to the east, but there is also a cramped opening to the west."
        )
        cloakroom.setFlag(.naturallyLit)

        // Handle the special exit west
        cloakroom.beginCommandAction = { (room: Room, command: Command) -> Bool in
            guard case .move(.west) = command else { return false }

            // Find the player using the findPlayer helper
            let player = room.findPlayer()

            // Check if player is wearing/carrying the cloak
            let hasCloak = player?.contents.contains { $0.name == "cloak" } ?? false

            if hasCloak {
                print("You cannot enter the opening to the west while in possession of your cloak.")
                return true
            } else {
                // Try to access the world from our room's stored state
                let world = room.gameWorld

                // Try to find the hallway
                if let world = world, let hallToStudy = world.rooms.first(where: { $0.name == "Hallway to Study" }) {
                    if let player = player, let currentRoom = player.currentRoom {
                        // Remove from current room
                        if let index = currentRoom.contents.firstIndex(where: { $0 === player }) {
                            currentRoom.contents.remove(at: index)
                        }

                        // Add to hallToStudy
                        hallToStudy.contents.append(player)
                        player.location = hallToStudy

                        // Execute enter actions in the new room
                        _ = hallToStudy.executeEnterAction()

                        print("Oof - it's cramped in here.")
                        return true
                    }
                }

                print("You can't go that way.")
                return true
            }
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
            // Access the game world directly
            let world = room.gameWorld

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
        createGlobalObjects(world: world)
    }

    private static func createFoyerObjects(world: GameWorld, foyer: Room) {
        // Create an apple in the foyer
        let apple = GameObject(name: "apple", description: "A shiny red apple.")
        apple.location = foyer
        apple.setFlag(.takeBit)
        apple.setFlag(.edibleBit)

        apple.setExamineHandler { obj in
            print("The apple is red and looks delicious.")
            return true
        }

        apple.setCustomCommandHandler(verb: "eat") { obj, objects in
            print("You eat the apple. It's delicious!")
            // Remove the apple from the game world
            if let location = obj.location {
                if let index = location.contents.firstIndex(where: { $0 === obj }) {
                    location.contents.remove(at: index)
                }
            }
            return true
        }

        world.registerObject(apple)

        // Create some grime in the foyer
        let grime = GameObject(name: "grime", description: "Years of dirt and grime cover the floor.")
        grime.location = foyer

        grime.setExamineHandler { obj in
            print("The floor is covered in years of accumulated dirt and grime.")
            return true
        }

        world.registerObject(grime)
    }

    private static func createBarObjects(world: GameWorld, bar: Room) {
        // Message
        let message = GameObject(name: "message", description: "A message scrawled in the sawdust.")
        message.location = bar
        message.firstDescription = "There seems to be some sort of message scrawled in the sawdust on the floor."
        world.registerObject(message)

        // Store the world directly in the message for closure access
        message.gameWorld = world

        message.setExamineHandler { obj in
            let room = obj.location as? Room
            let disturbed = (room?.disturbed as Int?) ?? 0

            // Find the player using our helper method
            if let player = obj.findPlayer() {
                if disturbed > 1 {
                    print("The message simply reads: \"You lose.\"")
                    player.engine.gameOver(message: "You lose", isVictory: false)
                } else {
                    print("The message simply reads: \"You win.\"")
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

    private static func createCloakroomObjects(world: GameWorld, cloakroom: Room) {
        // Hook
        let hook = GameObject(name: "small brass hook", description: "A small brass hook is on the wall.")
        hook.location = cloakroom
        hook.setFlag(.contBit)
        hook.setFlag(.surfaceBit)
        world.registerObject(hook)

        hook.setExamineHandler { obj in
            print("Test: Normal examine replaced by a dequeue of the Table event.")
            // Access the world directly rather than through the player
            if let room = obj.location as? Room,
               let world = room.gameWorld {
                _ = world.dequeueEvent(named: "I-TABLE-FUN")
            }
            return true
        }
    }

    private static func createHallwayObjects(world: GameWorld, hallToStudy: Room) {
        // Sign
        let sign = GameObject(name: "sign", description: "It's a block of grey wood bearing hastily-painted words.")
        sign.location = hallToStudy
        sign.setFlag(.readBit)
        sign.firstDescription = "A crude wooden sign hangs above the western exit."
        sign.text = "It reads, 'Welcome to the Study'"
        world.registerObject(sign)
    }

    private static func createStudyObjects(world: GameWorld, study: Room) {
        // Light switch
        let lightSwitch = GameObject(name: "light switch", description: "An ordinary light switch.")
        lightSwitch.location = study
        lightSwitch.setFlag(.deviceBit)
        world.registerObject(lightSwitch)

        lightSwitch.setExamineHandler { obj in
            print("An ordinary light switch set in the wall to the left of the entrance to the closet. It is currently ", terminator: "")
            if obj.hasFlag(.onBit) {
                print("on.")
            } else {
                print("off.")
            }
            return true
        }

        lightSwitch.setCustomCommandHandler(verb: "turn-on") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                obj.setFlag(.onBit)

                // Find the player using the findPlayer helper
                if let room = obj.location as? Room,
                   let player = room.findPlayer(),
                   let currentRoom = player.currentRoom,
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

                // Find the player using the findPlayer helper
                if let room = obj.location as? Room,
                   let player = room.findPlayer(),
                   let currentRoom = player.currentRoom,
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

                    // Find the player using the findPlayer helper
                    if let room = obj.location as? Room,
                       let player = room.findPlayer(),
                       let currentRoom = player.currentRoom,
                       currentRoom.name == "Closet" {
                        currentRoom.clearFlag(.lit)
                        print("The closet goes dark!")
                    }

                    print("You switch off the light switch.")
                } else {
                    // Turn it on
                    obj.setFlag(.onBit)

                    // Find the player using the findPlayer helper
                    if let room = obj.location as? Room,
                       let player = room.findPlayer(),
                       let currentRoom = player.currentRoom,
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

                    // Find the player using the findPlayer helper
                    if let room = obj.location as? Room,
                       let player = room.findPlayer(),
                       let currentRoom = player.currentRoom,
                       !currentRoom.hasFlag(.lit) && !currentRoom.hasFlag(.naturallyLit) {
                        currentRoom.setFlag(.lit)
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

                    // Find the player using the findPlayer helper
                    if let room = obj.location as? Room,
                       let player = room.findPlayer(),
                       let currentRoom = player.currentRoom,
                       !currentRoom.hasFlag(.naturallyLit) {
                        // Check if room should now be dark
                        let hasOtherLight = player.contents.contains {
                            $0.hasFlag(.lightSource) && $0.hasFlag(.lit) && $0 !== obj
                        }
                        if !hasOtherLight {
                            currentRoom.clearFlag(.lit)
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
                if obj.hasFlag(.onBit) {
                    // Turn it off
                    obj.clearFlag(.onBit)
                    obj.clearFlag(.lit)
                    print("You switch off the flashlight.")

                    // Find the player using the findPlayer helper
                    if let room = obj.location as? Room,
                       let player = room.findPlayer(),
                       let currentRoom = player.currentRoom,
                       !currentRoom.hasFlag(.naturallyLit) {
                        // Check if room should now be dark
                        let hasOtherLight = player.contents.contains {
                            $0.hasFlag(.lightSource) && $0.hasFlag(.lit) && $0 !== obj
                        }
                        if !hasOtherLight {
                            currentRoom.clearFlag(.lit)
                            print("The area goes dark!")
                        }
                    }
                } else {
                    // Turn it on
                    obj.setFlag(.onBit)
                    obj.setFlag(.lightSource)
                    obj.setFlag(.lit)
                    print("You switch on the flashlight.")

                    // Find the player using the findPlayer helper
                    if let room = obj.location as? Room,
                       let player = room.findPlayer(),
                       let currentRoom = player.currentRoom,
                       !currentRoom.hasFlag(.lit) && !currentRoom.hasFlag(.naturallyLit) {
                        currentRoom.setFlag(.lit)
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
        book.text = "It tells of an adventurer who was tasked with testing out a library that was old and new at the same time."
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

    private static func createClosetObjects(world: GameWorld, closet: Room) {
        // Create a broom in the closet
        let broom = GameObject(name: "broom", description: "An old wooden broom with straw bristles.")
        broom.location = closet
        broom.setFlag(.takeBit)

        broom.setExamineHandler { obj in
            print("An old wooden broom with straw bristles. It looks like it hasn't been used in years.")
            return true
        }

        world.registerObject(broom)

        // Create a dusty shelf
        let shelf = GameObject(name: "shelf", description: "A dusty wooden shelf attached to the wall.")
        shelf.location = closet
        shelf.setFlag(.contBit)
        shelf.setFlag(.surfaceBit)

        shelf.setExamineHandler { obj in
            print("A dusty wooden shelf attached to the wall.")
            return true
        }

        world.registerObject(shelf)
    }

    private static func createGlobalObjects(world: GameWorld) {
        // Ceiling (global object)
        let ceiling = GameObject(name: "ceiling", description: "Nothing really noticeable about the ceiling.")
        world.globalObjects.append(ceiling)

        ceiling.setExamineHandler { obj in
            print("Nothing really noticeable about the ceiling.")
            return true
        }

        // Darkness (global object)
        let darkness = GameObject(name: "darkness", description: "It's too dark to see anything.")
        darkness.setFlag(.nArticleBit)
        world.globalObjects.append(darkness)

        darkness.setCustomCommandHandler(verb: "think-about") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                print("Light, darkness. Your favorite cloak has something to do with them, yes?")
                return true
            }
            return false
        }

        // Rug (local global object)
        let rug = GameObject(name: "rug", description: "A tatty old rug.")

        rug.setCustomCommandHandler(verb: "put-on") { obj, objects in
            if objects.contains(where: { $0 === obj }) {
                print("You don't want to place anything on that tatty rug.")
                return true
            }
            return false
        }

        if let foyer = world.rooms.first(where: { $0.name == "Foyer of the Opera House" }),
           let bar = world.rooms.first(where: { $0.name == "Foyer Bar" }) {
            foyer.addLocalGlobal(rug)
            bar.addLocalGlobal(rug)
        }
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

        cloak.setExamineHandler { obj in
            print("The cloak is unnaturally dark.")
            return true
        }
    }
}
