//
//  ExtendedCommands.swift
//  ZILFSwift
//
//  Created on current date
//

import Foundation

/// Extended command types for the ZILFCore interpreter
/// Based on verbs defined in the ZIL source
public extension Command {
    /// Extended command cases to supplement the basic commands
    static func wear(_ object: GameObject) -> Command {
        return .customCommand("wear", [object])
    }

    static func unwear(_ object: GameObject) -> Command {
        return .customCommand("unwear", [object])
    }

    static func putOn(_ object: GameObject, surface: GameObject) -> Command {
        return .customCommand("put_on", [object, surface])
    }

    static func putIn(_ object: GameObject, container: GameObject) -> Command {
        return .customCommand("put_in", [object, container])
    }

    static func lock(_ object: GameObject, tool: GameObject) -> Command {
        return .customCommand("lock", [object, tool])
    }

    static func unlock(_ object: GameObject, tool: GameObject) -> Command {
        return .customCommand("unlock", [object, tool])
    }

    static func turnOn(_ object: GameObject) -> Command {
        return .customCommand("turn_on", [object])
    }

    static func turnOff(_ object: GameObject) -> Command {
        return .customCommand("turn_off", [object])
    }

    static func flip(_ object: GameObject) -> Command {
        return .customCommand("flip", [object])
    }

    static func wait() -> Command {
        return .customCommand("wait", [])
    }

    static func again() -> Command {
        return .customCommand("again", [])
    }

    static func read(_ object: GameObject) -> Command {
        return .customCommand("read", [object])
    }

    static func eat(_ object: GameObject) -> Command {
        return .customCommand("eat", [object])
    }

    static func drink(_ object: GameObject) -> Command {
        return .customCommand("drink", [object])
    }

    static func smell(_ object: GameObject) -> Command {
        return .customCommand("smell", [object])
    }

    static func push(_ object: GameObject) -> Command {
        return .customCommand("push", [object])
    }

    static func pull(_ object: GameObject) -> Command {
        return .customCommand("pull", [object])
    }

    static func fill(_ container: GameObject) -> Command {
        return .customCommand("fill", [container])
    }

    static func empty(_ container: GameObject) -> Command {
        return .customCommand("empty", [container])
    }

    static func attack(_ target: GameObject) -> Command {
        return .customCommand("attack", [target])
    }

    static func give(_ object: GameObject, recipient: GameObject) -> Command {
        return .customCommand("give", [object, recipient])
    }

    static func tell(_ person: GameObject, topic: String) -> Command {
        return .customCommand("tell", [person], additionalData: topic)
    }

    static func wave(_ object: GameObject) -> Command {
        return .customCommand("wave", [object])
    }

    static func waveHands() -> Command {
        return .customCommand("wave_hands", [])
    }

    static func throwAt(_ object: GameObject, target: GameObject) -> Command {
        return .customCommand("throw", [object, target])
    }

    static func burn(_ object: GameObject) -> Command {
        return .customCommand("burn", [object])
    }

    static func rub(_ object: GameObject) -> Command {
        return .customCommand("rub", [object])
    }

    static func lookUnder(_ object: GameObject) -> Command {
        return .customCommand("look_under", [object])
    }

    static func search(_ container: GameObject) -> Command {
        return .customCommand("search", [container])
    }

    static func wake(_ person: GameObject) -> Command {
        return .customCommand("wake", [person])
    }

    static func jump() -> Command {
        return .customCommand("jump", [])
    }

    static func swim() -> Command {
        return .customCommand("swim", [])
    }

    static func climb() -> Command {
        return .customCommand("climb", [])
    }

    static func climb(_ object: GameObject) -> Command {
        return .customCommand("climb", [object])
    }

    static func sing() -> Command {
        return .customCommand("sing", [])
    }

    static func dance() -> Command {
        return .customCommand("dance", [])
    }

    static func yes() -> Command {
        return .customCommand("yes", [])
    }

    static func no() -> Command {
        return .customCommand("no", [])
    }

    // Game system commands
    static func version() -> Command {
        return .customCommand("version", [])
    }

    static func undo() -> Command {
        return .customCommand("undo", [])
    }

    static func save() -> Command {
        return .customCommand("save", [])
    }

    static func restore() -> Command {
        return .customCommand("restore", [])
    }

    static func restart() -> Command {
        return .customCommand("restart", [])
    }

    static func brief() -> Command {
        return .customCommand("brief", [])
    }

    static func superbrief() -> Command {
        return .customCommand("superbrief", [])
    }

    static func verbose() -> Command {
        return .customCommand("verbose", [])
    }

    static func script(_ on: Bool) -> Command {
        return .customCommand("script", [], additionalData: on ? "on" : "off")
    }

    static func unscript() -> Command {
        return .customCommand("unscript", [])
    }

    static func pronouns() -> Command {
        return .customCommand("pronouns", [])
    }
}
