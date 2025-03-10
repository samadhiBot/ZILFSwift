import Foundation

/// Represents a game command with a primary name and optional synonyms.
public enum Command {
    // MARK: Custom commands

    /// Defines a game-specific custom command.
    case custom([String])

    /// Defines a fallback command when the input is not understood.
    case unknown(String)

    // MARK: Interaction commands

    /// Attack an object, optionally with a tool.
    case attack(GameObject?, with: GameObject?)

    /// Burn an object, optionally with a tool.
    case burn(GameObject?, with: GameObject?)

    /// Climb a specific object.
    case climb(GameObject?)

    /// Close an object.
    case close(GameObject?)

    /// Dance.
    case dance

    /// Drink a potable object.
    case drink(GameObject?)

    /// Drop an object.
    case drop(GameObject?)

    /// Consume an edible object.
    case eat(GameObject?)

    /// Empty a container.
    case empty(GameObject?)

    /// Examine an object to get more information about it, optionally with a tool.
    case examine(GameObject?, with: GameObject?)

    /// Fill a container with an implied liquid.
    case fill(GameObject?)

    /// Flip or toggle a device.
    case flip(GameObject?)

    /// Give an object to a recipient.
    case give(GameObject?, to: GameObject?)

    /// Check the player's inventory.
    case inventory

    /// Jump.
    case jump

    /// Lock an object using a tool.
    case lock(GameObject?, with: GameObject?)

    /// Look at an object.
    case look

    /// Look under an object.
    case lookUnder(GameObject?)

    /// Move the player in some direction.
    case move(Direction?)

    /// Creates a command for a negative response.
    case no

    /// Open an object, optionally with a tool.
    case open(GameObject?, with: GameObject?)

    /// Display current pronoun references.
    case pronouns

    /// Pull an object.
    case pull(GameObject?)

    /// Push an object.
    case push(GameObject?)

    /// Place an object inside a container.
    case putIn(GameObject?, container: GameObject?)

    /// Place an object on a surface.
    case putOn(GameObject?, surface: GameObject?)

    /// Read a readable object, optionally with a tool.
    case read(GameObject?, with: GameObject?)

    /// Remove an object.
    case remove(GameObject?)

    /// Rub an object, optionally with a tool.
    case rub(GameObject?, with: GameObject?)

    /// Search a container.
    case search(GameObject?)

    /// Sing.
    case sing

    /// Smell an object.
    case smell(GameObject?)

    /// Swim.
    case swim

    /// Take an object.
    case take(GameObject?)

    /// Tell a person about a topic.
    case tell(GameObject?, about: String?)

    /// Consider or contemplate an object or concept.
    case thinkAbout(GameObject?)

    /// Throw an object at an object.
    case throwAt(GameObject?, target: GameObject?)

    /// Deactivate a device.
    case turnOff(GameObject?)

    /// Activate a device.
    case turnOn(GameObject?)

    /// Unlock an object using a tool.
    case unlock(GameObject?, with: GameObject?)

    /// Unwear a worn object.
    case unwear(GameObject?)

    /// Wait (do nothing for a turn).
    case wait

    /// Wake a person.
    case wake(GameObject?)

    /// Wave an object.
    case wave(GameObject?)

    /// Wave hands (without holding any object).
    case waveHands

    /// Wear a wearable object.
    case wear(GameObject?)

    /// Creates a command for an affirmative response.
    case yes

    // MARK: Meta commands

    /// Repeat the last action.
    case again

    /// Switch to brief room descriptions mode.
    case brief

    /// Show the help screen.
    case help

    /// Quit the game.
    case quit

    /// Restart the game from the beginning.
    case restart

    /// Restore a previously saved game state.
    case restore

    /// Save the current game state.
    case save

    /// Turn on script recording mode.
    case script

    /// Switch to superbrief room descriptions mode.
    case superbrief

    /// Undo the last action.
    case undo

    /// Turn off script recording.
    case unscript

    /// Switch to verbose room descriptions mode.
    case verbose

    /// Display the game version information.
    case version
}

extension Command {
//    /// Returns a command that matches the user input.
//    ///
//    /// - Parameter input: User input expressed as an array of strings.
//    init(from input: [String]) {
//        guard let command = input.first else {
//            self = .unknown("No command given")
//            return
//        }
//        switch command {
//        case "attack", "kill", "destroy": self = .attack
//        case "burn", "light": self = .burn
//        case "climb": self = .climb
//        case "close", "shut": self = .close
//        case "dance": self = .dance
//        case "drink", "sip", "quaff": self = .drink
//        case "drop", "put-down": self = .drop
//        case "eat", "consume", "devour": self = .eat
//        case "empty": self = .empty
//        case "examine", "x", "look-at", "inspect": self = .examine
//        case "fill": self = .fill
//        case "flip", "switch", "toggle": self = .flip
//        case "give": self = .give
//        case "inventory", "i", "inv": self = .inventory
//        case "jump": self = .jump
//        case "lock": self = .lock
//        case "look", "l", "look-around": self = .look
//        case "look-under": self = .lookUnder
//        case "move", "go", "walk", "run": self = .move
//        case "no": self = .no
//        case "open": self = .open
//        case "pronouns": self = .pronouns
//        case "pull": self = .pull
//        case "push": self = .push
//        case "put-in": self = .putIn
//        case "put-on", "place-on", "set-on": self = .putOn
//        case "read", "peruse": self = .read
//        case "remove", "doff", "take-off": self = .remove
//        case "rub": self = .rub
//        case "search": self = .search
//        case "sing": self = .sing
//        case "smell": self = .smell
//        case "swim": self = .swim
//        case "take", "get", "pick-up": self = .take
//        case "tell": self = .tell
//        case "think-about", "ponder", "contemplate": self = .thinkAbout
//        case "throw": self = .throwAt
//        case "turn-off", "deactivate", "switch-off": self = .turnOff
//        case "turn-on", "activate", "switch-on": self = .turnOn
//        case "unlock": self = .unlock
//        case "unwear": self = .unwear
//        case "wait": self = .wait
//        case "wake": self = .wake
//        case "wave": self = .wave
//        case "wave-hands": self = .waveHands
//        case "wear", "don", "put-on": self = .wear
//        case "yes": self = .yes
//
//        case "again", "g", "repeat": self = .again
//        case "brief": self = .brief
//        case "help", "?", "info": self = .help
//        case "quit", "q", "exit": self = .quit
//        case "restart": self = .restart
//        case "restore", "load": self = .restore
//        case "save": self = .save
//        case "script": self = .script
//        case "superbrief": self = .superbrief
//        case "undo": self = .undo
//        case "unscript": self = .unscript
//        case "verbose": self = .verbose
//        case "version": self = .version
//
//        }
//        if let command = Self.allCases.first(where: {
//            $0.synonyms.contains(input[0])
//        }) {
//            self = command
//        }
//        self = .custom(input)
//    }

    /// Alternative string representations that resolve to this command.
    public var synonyms: [String] {
        switch self {
        case .custom(let synonyms): Array(synonyms)
        case .unknown: []

        case .attack: ["attack", "kill", "destroy"]
        case .burn: ["burn", "light"]
        case .climb: ["climb"]
        case .close: ["close", "shut"]
        case .dance: ["dance"]
        case .drink: ["drink", "sip", "quaff"]
        case .drop: ["drop", "put-down"]
        case .eat: ["eat", "consume", "devour"]
        case .empty: ["empty"]
        case .examine: ["examine", "x", "look-at", "inspect"]
        case .fill: ["fill"]
        case .flip: ["flip", "switch", "toggle"]
        case .give: ["give"]
        case .inventory: ["inventory", "i", "inv"]
        case .jump: ["jump"]
        case .lock: ["lock"]
        case .look: ["look", "l", "look-around"]
        case .lookUnder: ["look-under"]
        case .move: ["move", "go", "walk", "run"]
        case .no: ["no"]
        case .open: ["open"]
        case .pronouns: ["pronouns"]
        case .pull: ["pull"]
        case .push: ["push"]
        case .putIn: ["put-in"]
        case .putOn: ["put-on", "place-on", "set-on"]
        case .read: ["read", "peruse"]
        case .remove: ["remove", "doff", "take-off"]
        case .rub: ["rub"]
        case .search: ["search"]
        case .sing: ["sing"]
        case .smell: ["smell"]
        case .swim: ["swim"]
        case .take: ["take", "get", "pick-up"]
        case .tell: ["tell"]
        case .thinkAbout: ["think-about", "ponder", "contemplate"]
        case .throwAt: ["throw"]
        case .turnOff: ["turn-off", "deactivate", "switch-off"]
        case .turnOn: ["turn-on", "activate", "switch-on"]
        case .unlock: ["unlock"]
        case .unwear: ["unwear"]
        case .wait: ["wait"]
        case .wake: ["wake"]
        case .wave: ["wave"]
        case .waveHands: ["wave-hands"]
        case .wear: ["wear", "don", "put-on"]
        case .yes: ["yes"]

        case .again: ["again", "g", "repeat"]
        case .brief: ["brief"]
        case .help: ["help", "?", "info"]
        case .quit: ["quit", "q", "exit"]
        case .restart: ["restart"]
        case .restore: ["restore", "load"]
        case .save: ["save"]
        case .script: ["script"]
        case .superbrief: ["superbrief"]
        case .undo: ["undo"]
        case .unscript: ["unscript"]
        case .verbose: ["verbose"]
        case .version: ["version"]
        }
    }
}

// MARK: - CustomStringConvertible

extension Command: CustomStringConvertible {
    public var description: String {
        synonyms[0]
    }
}
