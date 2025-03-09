import Foundation

/// Represents a game command with a primary name and optional synonyms
public enum Command: Equatable, Hashable, Sendable {
    // MARK: Custom commands

    /// Defines a game-specific custom command.
    case custom([String])

    /// Defines a fallback command when the input is not understood.
    case unknown(String)

    // MARK: Interaction commands

    /// Attack an object.
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

    /// Move the player in some direction.
    case move

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

    /// Throw an object at an object.
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
    /// Returns a command that matches the user input.
    ///
    /// - Parameter strings: User input expressed as an array of strings.
    init(from strings: [String]) {
        if let command = Self.allCases.first(where: {
            $0.synonyms.contains(strings[0])
        }) {
            self = command
        }
        self = .custom(strings)
    }

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

extension Command: CaseIterable {
    public static var allCases: [Command] {
        [
            .again,
            .attack,
            .brief,
            .burn,
            .climb,
            .close,
            .dance,
            .drink,
            .drop,
            .eat,
            .empty,
            .examine,
            .fill,
            .flip,
            .give,
            .help,
            .inventory,
            .jump,
            .lock,
            .look,
            .lookUnder,
            .move,
            .no,
            .open,
            .pronouns,
            .pull,
            .push,
            .putIn,
            .putOn,
            .quit,
            .read,
            .remove,
            .restart,
            .restore,
            .rub,
            .save,
            .script,
            .search,
            .sing,
            .smell,
            .superbrief,
            .swim,
            .take,
            .tell,
            .thinkAbout,
            .throwAt,
            .turnOff,
            .turnOn,
            .undo,
            .unlock,
            .unscript,
            .unwear,
            .verbose,
            .version,
            .wait,
            .wake,
            .wave,
            .waveHands,
            .wear,
            .yes,
        ]
    }
}

