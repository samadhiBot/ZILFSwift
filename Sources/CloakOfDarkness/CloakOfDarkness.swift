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
    func createWorld() -> GameWorld {
        // Create player and world
        let player = Player(startingRoom: worldBuilder.foyer)
        let world = GameWorld(player: player)

        // Build the game world
        worldBuilder.buildWorld(world)

        // Configure events
//        configureEvents(in: world)

        return world
    }


//    override public func setupGame() {
//        // Setup signal handler for terminal resize if using terminal mode
//        if outputManager is TerminalConsole {
//            setupSignalHandler(game: self)
//        }
//    }

//    /// Creates and initializes the complete game world.
//    ///
//    /// This method sets up all rooms, objects, and connections for the Cloak of Darkness game.
//    ///
//    /// - Returns: A fully configured game world ready to be played.
//    override public class func create() throws -> GameWorld {
//        // Create the rooms
//        let foyer = createFoyer()
//        let bar = createBar()
//        let cloakroom = createCloakroom()
//        let hallToStudy = createHallToStudy()
//        let study = createStudy()
//        let closet = createCloset()
//
//        // Create player and world (player needs a starting room)
//        let player = Player(startingRoom: foyer)
//        let world = GameWorld(player: player)
//
//        // Register rooms with the world
//        world.register(foyer)
//        world.register(bar)
//        world.register(cloakroom)
//        world.register(hallToStudy)
//        world.register(study)
//        world.register(closet)
//
//        // Set up exits
//        foyer.exits[.south] = bar
//        foyer.exits[.west] = cloakroom
//        bar.exits[.north] = foyer
//        cloakroom.exits[.east] = foyer
//        hallToStudy.exits[.east] = study
//        study.exits[.west] = hallToStudy
//        study.exits[.north] = closet
//        closet.exits[.south] = study
//
//        // Create objects and populate the world
//        // Create player inventory
//        createPlayerInventory(world: world)
//
//        // Create room-specific objects
//        createFoyerObjects(world: world, foyer: foyer)
//        createBarObjects(world: world, bar: bar)
//        createCloakroomObjects(world: world, cloakroom: cloakroom)
//        createHallwayObjects(world: world, hallToStudy: hallToStudy)
//        createStudyObjects(world: world, study: study)
//        createClosetObjects(world: world, closet: closet)
//
//        // Create global objects
//        try createGlobalObjects(
//            world: world,
//            hallToStudy: hallToStudy
//        )
//
//        return world
//    }


    // MARK: - Command Handler Functions

    func handleAppleCommands(_ obj: GameObject, _ command: Command) -> Bool {
        switch command {
        case .examine(let target, _) where target === obj:
            output("The apple is green and tasty-looking.")
            obj.world?.eventManager.scheduleEvent(
                name: "I-APPLE-FUN",
                turns: 3,
                action: { true }
            )
            return true
        case .eat(let target) where target === obj:
            output("Oh no! It was actually a poison apple (mostly so we could test JIGS-UP).")
            if let engine = obj.findPlayer()?.engine {
                engine.gameOver(with: .defeat("You've been poisoned by the apple."))
            }
            return true
        default:
            break
        }
        return false
    }

    func handleMessageCommands(_ obj: GameObject, _ command: Command) -> Bool {
        switch command {
        case .examine(let target, _) where target === obj:
            let room = obj.location as? Room
            let disturbed = (room?.disturbed as Int?) ?? 0

            guard let engine = obj.findPlayer()?.engine else { return false }

            if disturbed > 1 {
                output("The message simply reads: \"You lose.\"")
                engine.gameOver(with: .defeat("You lose"))
            } else {
                output("The message simply reads: \"You win.\"")
                engine.gameOver(with: .victory("You win"))
            }
            return true
        default:
            break
        }
        return false
    }
}
