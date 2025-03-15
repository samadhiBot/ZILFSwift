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

// MARK: - Synonyms

extension Command {
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

// MARK: - Conveniences

extension Command {
    static func attack(_ gameObject: GameObject?) -> Command {
        .attack(gameObject, with: nil)
    }

    static func burn(_ gameObject: GameObject?) -> Command {
        .burn(gameObject, with: nil)
    }
    
    static func examine(_ gameObject: GameObject?) -> Command {
        .examine(gameObject, with: nil)
    }

    static func lock(_ gameObject: GameObject?) -> Command {
        .lock(gameObject, with: nil)
    }

    static func open(_ gameObject: GameObject?) -> Command {
        .open(gameObject, with: nil)
    }

    static func read(_ gameObject: GameObject?) -> Command {
        .read(gameObject, with: nil)
    }

    static func rub(_ gameObject: GameObject?) -> Command {
        .rub(gameObject, with: nil)
    }

    static func unlock(_ gameObject: GameObject?) -> Command {
        .unlock(gameObject, with: nil)
    }
}

// MARK: - CustomStringConvertible

extension Command: CustomStringConvertible {
    public var description: String {
        synonyms[0]
    }
}
