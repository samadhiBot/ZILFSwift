import Foundation

/// Extended command types for the ZILFCore interpreter
///
/// Based on verbs defined in the ZIL source
extension Command {
    /// Creates a command to repeat the last action
    ///
    /// - Returns: A custom command representing the again action
    public static func again() -> Command {
        return .customCommand("again", [])
    }

    /// Creates a command to attack a target
    ///
    /// - Parameter target: The target to attack
    ///
    /// - Returns: A custom command representing the attack action
    public static func attack(_ target: GameObject) -> Command {
        return .customCommand("attack", [target])
    }

    /// Creates a command to switch to brief room descriptions mode
    ///
    /// - Returns: A custom command representing the brief mode action
    public static func brief() -> Command {
        return .customCommand("brief", [])
    }

    /// Creates a command to burn an object
    ///
    /// - Parameter object: The object to be burned
    ///
    /// - Returns: A custom command representing the burn action
    public static func burn(_ object: GameObject) -> Command {
        return .customCommand("burn", [object])
    }

    /// Creates a command to climb (with no specified object)
    ///
    /// - Returns: A custom command representing the climb action
    public static func climb() -> Command {
        return .customCommand("climb", [])
    }

    /// Creates a command to climb a specific object
    ///
    /// - Parameter object: The object to be climbed
    ///
    /// - Returns: A custom command representing the climb action on a specific object
    public static func climb(_ object: GameObject) -> Command {
        return .customCommand("climb", [object])
    }

    /// Creates a command to dance
    ///
    /// - Returns: A custom command representing the dance action
    public static func dance() -> Command {
        return .customCommand("dance", [])
    }

    /// Creates a command to drink a potable object
    ///
    /// - Parameter object: The object to be drunk
    ///
    /// - Returns: A custom command representing the drink action
    public static func drink(_ object: GameObject) -> Command {
        return .customCommand("drink", [object])
    }

    /// Creates a command to eat an edible object
    ///
    /// - Parameter object: The object to be eaten
    ///
    /// - Returns: A custom command representing the eat action
    public static func eat(_ object: GameObject) -> Command {
        return .customCommand("eat", [object])
    }

    /// Creates a command to empty a container
    ///
    /// - Parameter container: The container to be emptied
    ///
    /// - Returns: A custom command representing the empty action
    public static func empty(_ container: GameObject) -> Command {
        return .customCommand("empty", [container])
    }

    /// Creates a command to fill a container with an implied liquid
    ///
    /// - Parameter container: The container to be filled
    ///
    /// - Returns: A custom command representing the fill action
    public static func fill(_ container: GameObject) -> Command {
        return .customCommand("fill", [container])
    }

    /// Creates a command to flip or toggle a device
    ///
    /// - Parameter object: The device to be flipped
    ///
    /// - Returns: A custom command representing the flip action
    public static func flip(_ object: GameObject) -> Command {
        return .customCommand("flip", [object])
    }

    /// Creates a command to give an object to a recipient
    ///
    /// - Parameters:
    ///   - object: The object to be given
    ///   - recipient: The recipient to receive the object
    ///
    /// - Returns: A custom command representing the give action
    public static func give(_ object: GameObject, recipient: GameObject) -> Command {
        return .customCommand("give", [object, recipient])
    }

    /// Creates a command to jump
    ///
    /// - Returns: A custom command representing the jump action
    public static func jump() -> Command {
        return .customCommand("jump", [])
    }

    /// Creates a command to lock an object using a tool
    ///
    /// - Parameters:
    ///   - object: The object to be locked
    ///   - tool: The tool (e.g., key) used for locking
    ///
    /// - Returns: A custom command representing the lock action
    public static func lock(_ object: GameObject, tool: GameObject) -> Command {
        return .customCommand("lock", [object, tool])
    }

    /// Creates a command to look under an object
    ///
    /// - Parameter object: The object to look under
    ///
    /// - Returns: A custom command representing the look under action
    public static func lookUnder(_ object: GameObject) -> Command {
        return .customCommand("look_under", [object])
    }

    /// Creates a command for a negative response
    ///
    /// - Returns: A custom command representing the no action
    public static func no() -> Command {
        return .customCommand("no", [])
    }

    /// Creates a command to place an object inside a container
    ///
    /// - Parameters:
    ///   - object: The object to be placed
    ///   - container: The container to place the object in
    ///
    /// - Returns: A custom command representing the put in action
    public static func putIn(_ object: GameObject, container: GameObject) -> Command {
        return .customCommand("put_in", [object, container])
    }

    /// Creates a command to place an object on a surface
    ///
    /// - Parameters:
    ///   - object: The object to be placed
    ///   - surface: The surface to place the object on
    ///
    /// - Returns: A custom command representing the put on action
    public static func putOn(_ object: GameObject, surface: GameObject) -> Command {
        return .customCommand("put_on", [object, surface])
    }

    /// Creates a command to pull an object
    ///
    /// - Parameter object: The object to be pulled
    ///
    /// - Returns: A custom command representing the pull action
    public static func pull(_ object: GameObject) -> Command {
        return .customCommand("pull", [object])
    }

    /// Creates a command to push an object
    ///
    /// - Parameter object: The object to be pushed
    ///
    /// - Returns: A custom command representing the push action
    public static func push(_ object: GameObject) -> Command {
        return .customCommand("push", [object])
    }

    /// Creates a command to display current pronoun references
    ///
    /// - Returns: A custom command representing the pronouns action
    public static func pronouns() -> Command {
        return .customCommand("pronouns", [])
    }

    /// Creates a command to read a readable object
    ///
    /// - Parameter object: The object to be read
    ///
    /// - Returns: A custom command representing the read action
    public static func read(_ object: GameObject) -> Command {
        return .customCommand("read", [object])
    }

    /// Creates a command to restart the game from the beginning
    ///
    /// - Returns: A custom command representing the restart action
    public static func restart() -> Command {
        return .customCommand("restart", [])
    }

    /// Creates a command to restore a previously saved game state
    ///
    /// - Returns: A custom command representing the restore action
    public static func restore() -> Command {
        return .customCommand("restore", [])
    }

    /// Creates a command to rub an object
    ///
    /// - Parameter object: The object to be rubbed
    ///
    /// - Returns: A custom command representing the rub action
    public static func rub(_ object: GameObject) -> Command {
        return .customCommand("rub", [object])
    }

    /// Creates a command to save the current game state
    ///
    /// - Returns: A custom command representing the save action
    public static func save() -> Command {
        return .customCommand("save", [])
    }

    /// Creates a command to toggle script recording mode
    ///
    /// - Parameter on: Boolean indicating whether to turn scripting on or off
    ///
    /// - Returns: A custom command representing the script action
    public static func script(_ on: Bool) -> Command {
        return .customCommand("script", [], additionalData: on ? "on" : "off")
    }

    /// Creates a command to search a container
    ///
    /// - Parameter container: The container to be searched
    ///
    /// - Returns: A custom command representing the search action
    public static func search(_ container: GameObject) -> Command {
        return .customCommand("search", [container])
    }

    /// Creates a command to sing
    ///
    /// - Returns: A custom command representing the sing action
    public static func sing() -> Command {
        return .customCommand("sing", [])
    }

    /// Creates a command to smell an object
    ///
    /// - Parameter object: The object to be smelled
    ///
    /// - Returns: A custom command representing the smell action
    public static func smell(_ object: GameObject) -> Command {
        return .customCommand("smell", [object])
    }

    /// Creates a command to switch to superbrief room descriptions mode
    ///
    /// - Returns: A custom command representing the superbrief mode action
    public static func superbrief() -> Command {
        return .customCommand("superbrief", [])
    }

    /// Creates a command to swim
    ///
    /// - Returns: A custom command representing the swim action
    public static func swim() -> Command {
        return .customCommand("swim", [])
    }

    /// Creates a command to tell a person about a topic
    ///
    /// - Parameters:
    ///   - person: The person to speak to
    ///   - topic: The topic to discuss
    ///
    /// - Returns: A custom command representing the tell action
    public static func tell(_ person: GameObject, topic: String) -> Command {
        return .customCommand("tell", [person], additionalData: topic)
    }

    /// Creates a command to throw an object at a target
    ///
    /// - Parameters:
    ///   - object: The object to throw
    ///   - target: The target to throw at
    ///
    /// - Returns: A custom command representing the throw action
    public static func throwAt(_ object: GameObject, target: GameObject) -> Command {
        return .customCommand("throw", [object, target])
    }

    /// Creates a command to turn off a device
    ///
    /// - Parameter object: The device to be turned off
    ///
    /// - Returns: A custom command representing the turn off action
    public static func turnOff(_ object: GameObject) -> Command {
        return .customCommand("turn_off", [object])
    }

    /// Creates a command to turn on a device
    ///
    /// - Parameter object: The device to be turned on
    ///
    /// - Returns: A custom command representing the turn on action
    public static func turnOn(_ object: GameObject) -> Command {
        return .customCommand("turn_on", [object])
    }

    /// Creates a command to undo the last action
    ///
    /// - Returns: A custom command representing the undo action
    public static func undo() -> Command {
        return .customCommand("undo", [])
    }

    /// Creates a command to unlock an object using a tool
    ///
    /// - Parameters:
    ///   - object: The object to be unlocked
    ///   - tool: The tool (e.g., key) used for unlocking
    ///
    /// - Returns: A custom command representing the unlock action
    public static func unlock(_ object: GameObject, tool: GameObject) -> Command {
        return .customCommand("unlock", [object, tool])
    }

    /// Creates a command to unwear a worn object
    ///
    /// - Parameter object: The worn object to be removed
    ///
    /// - Returns: A custom command representing the unwear action
    public static func unwear(_ object: GameObject) -> Command {
        return .customCommand("unwear", [object])
    }

    /// Creates a command to turn off script recording
    ///
    /// - Returns: A custom command representing the unscript action
    public static func unscript() -> Command {
        return .customCommand("unscript", [])
    }

    /// Creates a command to switch to verbose room descriptions mode
    ///
    /// - Returns: A custom command representing the verbose mode action
    public static func verbose() -> Command {
        return .customCommand("verbose", [])
    }

    /// Creates a command to display the game version information
    ///
    /// - Returns: A custom command representing the version action
    public static func version() -> Command {
        return .customCommand("version", [])
    }

    /// Creates a command to wait (do nothing for a turn)
    ///
    /// - Returns: A custom command representing the wait action
    public static func wait() -> Command {
        return .customCommand("wait", [])
    }

    /// Creates a command to wake a person
    ///
    /// - Parameter person: The person to be awakened
    ///
    /// - Returns: A custom command representing the wake action
    public static func wake(_ person: GameObject) -> Command {
        return .customCommand("wake", [person])
    }

    /// Creates a command to wave an object
    ///
    /// - Parameter object: The object to be waved
    ///
    /// - Returns: A custom command representing the wave action
    public static func wave(_ object: GameObject) -> Command {
        return .customCommand("wave", [object])
    }

    /// Creates a command to wave hands (without holding any object)
    ///
    /// - Returns: A custom command representing the wave hands action
    public static func waveHands() -> Command {
        return .customCommand("wave_hands", [])
    }

    /// Creates a command to wear a wearable object
    ///
    /// - Parameter object: The wearable object to be worn
    ///
    /// - Returns: A custom command representing the wear action
    public static func wear(_ object: GameObject) -> Command {
        return .customCommand("wear", [object])
    }

    /// Creates a command for an affirmative response
    ///
    /// - Returns: A custom command representing the yes action
    public static func yes() -> Command {
        return .customCommand("yes", [])
    }
}
