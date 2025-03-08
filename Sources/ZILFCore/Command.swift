import Foundation

/// Represents a game command with a primary name and optional synonyms
public enum Command: Equatable, Hashable, Sendable {
    // MARK: Custom commands

    /// Defines a game-specific custom command.
    case custom(Set<String>)

    // MARK: Directional commands

    /// Move in the northern direction.
    case north

    /// Move in the northeastern direction.
    case northeast

    /// Move in the northwestern direction.
    case northwest

    /// Move in the southern direction.
    case south

    /// Move in the southeastern direction.
    case southeast

    /// Move in the southwestern direction.
    case southwest

    /// Move in the eastern direction.
    case east

    /// Move in the western direction.
    case west

    /// Move in the upward direction.
    case up

    /// Move in the downward direction.
    case down

    /// Move in the inward direction.
    case inward

    /// Move in the outward direction.
    case outward

    // MARK: Interaction commands

    /// Attack a target.
    case attack

    /// Burn an object.
    case burn

    /// Climb a specific object.
    case climb

    /// Close an object.
    case close

    /// Dance.
    case dance

    /// Drink a potable object.
    case drink

    /// Drop an object.
    case drop

    /// Consume an edible object.
    case eat

    /// Empty a container.
    case empty

    /// Examine an object to get more information about it.
    case examine

    /// Fill a container with an implied liquid.
    case fill

    /// Flip or toggle a device.
    case flip

    /// Give an object to a recipient.
    case give

    /// Check the player's inventory.
    case inventory

    /// Jump.
    case jump

    /// Lock an object using a tool.
    case lock

    /// Look at an object.
    case look

    /// Look under an object.
    case lookUnder

    /// Creates a command for a negative response.
    case no

    /// Open an object.
    case open

    /// Display current pronoun references.
    case pronouns

    /// Pull an object.
    case pull

    /// Push an object.
    case push

    /// Place an object inside a container.
    case putIn

    /// Place an object on a surface.
    case putOn

    /// Read a readable object.
    case read

    /// Remove an object.
    case remove

    /// Rub an object.
    case rub

    /// Search a container.
    case search

    /// Sing.
    case sing

    /// Smell an object.
    case smell

    /// Swim.
    case swim

    /// Take an object.
    case take

    /// Tell a person about a topic.
    case tell

    /// Consider or contemplate an object or concept.
    case thinkAbout

    /// Throw an object at a target.
    case throwAt

    /// Deactivate a device.
    case turnOff

    /// Activate a device.
    case turnOn

    /// Unlock an object using a tool.
    case unlock

    /// Unwear a worn object.
    case unwear

    /// Wait (do nothing for a turn).
    case wait

    /// Wake a person.
    case wake

    /// Wave an object.
    case wave

    /// Wave hands (without holding any object).
    case waveHands

    /// Wear a wearable object.
    case wear

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
    /// Checks whether a string matches a command.
    ///
    /// - Returns: Whether the string matches a command.
    public func matches(_ string: String) -> Bool {
        synonyms.contains(string.lowercased())
    }

    /// Alternative string representations that resolve to this command.
    public var synonyms: [String] {
        switch self {
        case .custom(let synonyms): Array(synonyms)
        case .north: ["north", "n", "go-north"]
        case .northeast: ["northeast", "ne", "go-northeast"]
        case .northwest: ["northwest", "nw", "go-northwest"]
        case .south: ["south", "s", "go-south"]
        case .southeast: ["southeast", "se", "go-southeast"]
        case .southwest: ["southwest", "sw", "go-southwest"]
        case .east: ["east", "e", "go-east"]
        case .west: ["west", "w", "go-west"]
        case .up: ["up", "u", "go-up", "climb"]
        case .down: ["down", "d", "go-down", "descend"]
        case .in: ["in"]
        case .out: ["out"]
        case .attack: ["attack", "kill", "destroy"]
        case .burn: ["burn", "light"]
        case .climb: ["climb"]
        case .close: ["close", "shut"]
        case .dance: ["dance"]
        case .drink: ["drink", "sip", "quaff"]
        case .drop: ["drop", "put down"]
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
        case .no: ["no"]
        case .open: ["open"]
        case .pronouns: ["pronouns"]
        case .pull: ["pull"]
        case .push: ["push"]
        case .putIn: ["put-in"]
        case .putOn: ["put on", "place-on", "set-on"]
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
