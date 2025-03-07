# Instructions for Claude: Translating ZIL Projects to Swift with ZILFCore

## Introduction

This document serves as a reference guide for translating ZIL (Zork Implementation Language) text adventure games to Swift using the ZILFCore framework. It outlines the architecture of ZILFCore, common patterns for translation, and practical advice for handling the unique aspects of ZIL when implementing them in Swift.

## ZILFCore Architecture Overview

ZILFCore is a Swift framework that implements the core concepts of ZIL, providing a foundation for text adventure games. The main components include:

- **GameObject**: Base class for all game objects (items, rooms, player)
- **Room**: Specialized GameObject for locations with exits and action handlers
- **Player**: Specialized GameObject representing the player character
- **GameWorld**: Contains all game objects, rooms, and state
- **GameEngine**: Handles command processing, turn management, and game flow
- **Command**: Enum representing player commands
- **Direction**: Enum representing movement directions
- **EventManager**: Handles scheduling and executing timed events

## Translating ZIL to Swift: Core Concepts

### Object Flags System

ZIL uses flags for object properties. In ZILFCore, these are implemented as string constants:

```swift
// ZIL:
// <OBJECT APPLE (FLAGS TAKEBIT EDIBLEBIT)>

// Swift:
let apple = GameObject(name: "apple", description: "A juicy apple.")
apple.setFlag(.takeBit)  // or "takebit"
apple.setFlag(.edibleBit)  // or "ediblebit"

// Or using the convenience initializer/method:
let apple = GameObject(name: "apple", description: "A juicy apple.", flags: .takeBit, .edibleBit)
apple.setFlags(.takeBit, .edibleBit)
```

Common flags include:

- `.takeBit`: Object can be picked up
- `.edibleBit`: Object can be eaten
- `.wearBit`: Object can be worn
- `.wornBit`: Object is currently being worn
- `.contBit`: Object is a container
- `.surfaceBit`: Object is a surface (things can be placed on it)
- `.openBit`: Object is open
- `.openableBit`: Object can be opened/closed
- `.lightSource`: Object emits light
- `.lit`: Object is currently emitting light
- `.transBit`: Object is transparent (can see inside when closed)
- `.readBit`: Object can be read
- `.nArticleBit`: Object name has no article ("grime" vs "a grime")
- `.pluralBit`: Object name is plural ("grapes" vs "grape")
- `.personBit`: Object is a person
- `.femaleBit`: Object is female
- `.naturallyLit`: Room is naturally lit

### Room Creation

Rooms in ZILFCore are created with a name and description, and then exits and special behaviors are added:

```swift
// ZIL:
// <ROOM FOYER
//     (DESC "Foyer of the Opera House")
//     (IN ROOMS)
//     (LDESC "You are standing in a spacious hall...")
//     (SOUTH TO BAR)
//     (WEST TO CLOAKROOM)
//     (NORTH SORRY "You've only just arrived...")
//     (FLAGS LIGHTBIT)
//     (ACTION FOYER-R)>

// Swift:
let foyer = Room(name: "Foyer of the Opera House",
                description: "You are standing in a spacious hall...")
foyer.setFlag(.naturallyLit)  // LIGHTBIT in ZIL

// Set exits
foyer.exits = [
    .south: bar,
    .west: cloakroom
]

// Special exit condition (SORRY in ZIL)
foyer.beginCommandAction = { (room, command) in
    if case .move(.north) = command {
        print("You've only just arrived, and besides, the weather outside seems to be getting worse.")
        return true
    }
    return false
}

// Room action (ACTION FOYER-R in ZIL)
foyer.endTurnAction = { (room) -> Bool in
    // Action logic here
    return true // If output was produced
}
```

### Command Handling System

ZILFCore provides a flexible command handling system that maps to ZIL's action routines:

```swift
// ZIL:
// <ROUTINE APPLE-R ()
//     <COND (<VERB? EXAMINE>
//            <TELL "The apple is green and tasty-looking." CR>)
//           (<VERB? EAT>
//            <JIGS-UP "Oh no! It was poisoned!">)>>

// Swift:
// Option 1: Using setCommandHandler
apple.setCommandHandler { (obj, command) in
    if case .examine = command {
        print("The apple is green and tasty-looking.")
        return true
    } else if case .customCommand(let verb, let objects, _) = command,
              verb == "eat",
              objects.contains(where: { $0 === obj }) {
        print("Oh no! It was poisoned!")
        let engine: GameEngine? = obj.location?.getState(forKey: "engine")
        engine?.gameOver(message: "You've been poisoned by the apple.")
        return true
    }
    return false
}

// Option 2: Using specialized handlers
apple.setExamineHandler { (obj) in
    print("The apple is green and tasty-looking.")
    return true
}

apple.setCustomCommandHandler(verb: "eat") { (obj, objects) in
    print("Oh no! It was poisoned!")
    let engine: GameEngine? = obj.location?.getState(forKey: "engine")
    engine?.gameOver(message: "You've been poisoned by the apple.")
    return true
}
```

### Event Scheduling

ZIL's QUEUE system is implemented in ZILFCore:

```swift
// ZIL:
// <QUEUE I-APPLE-FUN 3>

// Swift:
world.queueEvent(name: "I-APPLE-FUN", turns: 3) {
    print("You looked at an apple 2 turns ago!")
    return true
}

// ZIL:
// <DEQUEUE I-TABLE-FUN>

// Swift:
world.dequeueEvent(named: "I-TABLE-FUN")

// Check if an event is scheduled:
if world.isEventScheduled(named: "I-TABLE-FUN") {
    // Do something
}
```

### Room Action Phases

ZIL room actions have different phases that map to ZILFCore:

```swift
// ZIL M-BEG -> Swift beginTurnAction
room.beginTurnAction = { (room) -> Bool in
    // Logic here
    return true // If output produced
}

// ZIL M-END -> Swift endTurnAction
room.endTurnAction = { (room) -> Bool in
    // Logic here
    return true // If output produced
}

// ZIL M-ENTER -> Swift enterAction
room.enterAction = { (room) -> Bool in
    // Logic here
    return true // If output produced
}

// ZIL M-LOOK -> Swift lookAction
room.lookAction = { (room) -> Bool in
    // Logic here
    return true // If custom description provided
}
```

## Common Gotchas and Solutions

### 1. Accessing the Game Engine

ZIL routines often have direct access to game state. In ZILFCore, you need to get a reference to the engine through the object's location:

```swift
let engine: GameEngine? = obj.location?.getState(forKey: "engine")
let world = engine?.world
```

### 2. Game Over Handling

In ZIL, `JIGS-UP` ends the game. In ZILFCore, use:

```swift
// Do NOT call on player (common mistake)
let engine: GameEngine? = obj.location?.getState(forKey: "engine")
engine?.gameOver(message: "Game over message.")
```

### 3. State Management

ZILFCore uses a key-value store for object state:

```swift
// Store state
obj.setState("value", forKey: "key")
room.setState(5, forKey: "counter")

// Retrieve state
let value: String? = obj.getState(forKey: "key")
let counter: Int = room.getState(forKey: "counter") ?? 0
```

### 4. Dark Rooms

ZIL handles dark rooms with the LIGHTBIT flag. In ZILFCore:

```swift
// Naturally lit room
room.setFlag(.naturallyLit)  // Room is always lit

// Dark room unless player has a light source
room.clearFlag(.lit)  // Start as dark

// Check in room.enterAction if player has light source:
if player.inventory.contains(where: { $0.hasFlag(.lightSource) && $0.hasFlag(.lit) }) {
    room.setFlag(.lit)
} else {
    room.clearFlag(.lit)
}
```

### 5. Special Exits

ZIL uses special syntax for conditional exits. In ZILFCore:

```swift
// ZIL: (WEST PER CLOAK-CHECK)
room.beginCommandAction = { (room, command) -> Bool in
    if case .move(.west) = command {
        // Check condition
        if /* condition */ {
            // Allow movement to destination
            return false
        } else {
            print("You can't go that way because...")
            return true
        }
    }
    return false
}
```

## Translation Workflow Tips

1. **Start with rooms**: Create the room structure first, as everything else depends on it.

2. **Add essential objects**: Create the player and key objects next.

3. **Implement special actions**: Handle special room behaviors and conditional exits.

4. **Add objects with their handlers**: Create and register all game objects with their command handlers.

5. **Implement events**: Add timed events and special behaviors.

6. **Test incrementally**: Test each component as you implement it to catch issues early.

7. **Use state management**: Take advantage of ZILFCore's state management for complex behaviors.

8. **Leverage closures**: Use Swift closures to create elegant command handlers and room actions.

## Command Types in ZILFCore

Common command types in ZILFCore include:

```swift
case examine  // Look at an object
case look     // Look around room
case inventory  // Check inventory
case take(GameObject)  // Take object
case drop(GameObject)  // Drop object
case move(Direction)  // Move in direction
case customCommand(String, [GameObject], [String])  // Custom verb with objects
```

## Flag Constants

Common flag constants in ZILFCore:

```swift
public extension String {
    static let takeBit = "takebit"
    static let edibleBit = "ediblebit"
    static let wearBit = "wearbit"
    static let wornBit = "wornbit"
    static let contBit = "contbit"
    static let surfaceBit = "surfacebit"
    static let openBit = "openbit"
    static let openableBit = "openablebit"
    static let lightSource = "lightsource"
    static let lit = "lit"
    static let transBit = "transbit"
    static let readBit = "readbit"
    static let nArticleBit = "narticlebit"
    static let pluralBit = "pluralbit"
    static let personBit = "personbit"
    static let femaleBit = "femalebit"
    static let naturallyLit = "naturallylit"
    static let vowelBit = "vowelbit"
    static let deviceBit = "devicebit"
    static let onBit = "onbit"
}
```

## Conclusion

This guide should provide a solid foundation for translating ZIL projects to Swift using ZILFCore. Remember that ZILFCore is designed to capture the essence of ZIL while leveraging Swift's modern features like strong typing, closures, and optionals. When translating, focus on preserving the original game's behavior while taking advantage of Swift's strengths.
