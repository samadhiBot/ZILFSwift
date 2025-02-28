# ZILFSwift Project Analysis

Your project to port the ZIL (Zork Implementation Language) standard library to Swift is an interesting and ambitious endeavor. Creating a modern implementation that maintains compatibility with classic text adventure games while leveraging Swift's strengths is a worthwhile goal.

## Overall Assessment

The approach of focusing on functional fidelity rather than low-level memory management details is appropriate. Swift's modern features will allow you to implement the core concepts of ZIL while making the code more maintainable and safer.

## Strengths of the Current Plan

1. **Starting with a CLI application**: This is a pragmatic first step that lets you focus on the core functionality before adding UI complexities.

2. **Comprehensive reference material**: You have a substantial collection of ZIL reference files that provide a solid foundation for understanding the original system.

3. **Clear separation of core library and executable**: Your package structure with ZILFCore and ZILFSwift shows good architectural organization.

## Recommendations for the Project Plan

### 1. Implementation Strategy

- **Incremental implementation**: Start with the basic parser and object model, then add the more complex features like the event system.

- **Test-driven development**: Create small test games that exercise specific features of the library as you implement them.

- **Modular architecture**: Design the system with clear interfaces between components (parser, object model, event system, etc.) to make it easier to maintain and extend.

### 2. Core Components to Focus On

- **Object model**: Implement the hierarchical object system that models rooms, items, and their relationships.

- **Parser**: Create a robust parser that can handle the complex command syntax of ZIL games.

- **Action system**: Implement the verb-noun-indirect object pattern that drives game actions.

- **Event system**: Support for scheduled events (like the lantern running out of batteries in Zork).

### 3. Swift-Specific Improvements

- **Type safety**: Use Swift's strong type system to catch errors at compile time that would be runtime errors in ZIL.

- **Protocol-oriented design**: Use Swift protocols to define behaviors for game objects.

- **Value semantics**: Consider where immutable value types might be more appropriate than reference types.

- **Property wrappers**: Could be useful for implementing object properties with special behaviors.

### 4. User Interface Considerations

- **Text rendering**: Even in a CLI app, consider how to handle text styling and formatting.

- **Input handling**: Create a flexible input system that can be adapted to different interfaces later.

- **State persistence**: Implement save/restore functionality from the beginning.

### 5. Future Extensions

- **macOS app**: As planned, with a more graphical interface.

- **iOS app**: Consider mobile platforms as well.

- **Game editor**: A visual tool for creating new games could be a valuable companion.

- **Web interface**: A WebAssembly version could allow games to be played in browsers.

## Potential Challenges

1. **ZIL's dynamic nature**: ZIL was designed with flexibility in mind, which might be challenging to map to Swift's more static type system.

2. **Complex parsing logic**: The natural language parsing in text adventures is complex and will require careful implementation.

3. **State management**: Managing game state for save/restore will need careful design.

4. **Compatibility with existing games**: Ensuring that existing ZIL games can be ported with minimal changes.

## Conclusion

Your project has a solid foundation with the comprehensive ZIL reference files you've collected. The plan to start with a CLI application and focus on functional fidelity is sound.

I would recommend starting with a simple "hello world" style game that exercises basic movement and object interaction, then incrementally add features as you implement more of the standard library. This will give you quick feedback on your design decisions and help you discover edge cases early.

The ultimate goal of being able to port games like Zork with high fidelity is achievable, but will require careful attention to the semantics of the original ZIL system. Swift's modern features should make it possible to create a more robust and maintainable implementation while preserving the gameplay experience of classic text adventures.

---

Question: Looking in the Cloak of Darkness main file, what functionality are we missing now that exists in this demo game?

# Functionality Gap Analysis: ZILFSwift vs. Cloak of Darkness

Looking at the Cloak of Darkness ZIL file, there are several key features and mechanics that our ZILFSwift implementation is still missing. Let's analyze what we need to add:

## 1. Event System

The ZIL game has a robust event system with:

- **Timed events**: `<QUEUE I-APPLE-FUN 3>` schedules an event to happen 3 turns later
- **Recurring events**: `<QUEUE I-TABLE-FUN -1>` schedules an event to run every turn
- **Event cancellation**: `<DEQUEUE I-TABLE-FUN>` removes a scheduled event
- **Event detection**: `<RUNNING? I-APPLE-FUN>` checks if an event is scheduled for this turn

We need to implement this entire event system.

## 2. Light/Darkness Mechanics

The ZIL game has sophisticated light/darkness handling:

- Rooms can be lit or dark (`LIGHTBIT` flag)
- Objects can provide light (`LIGHTBIT` flag on objects)
- Light status can change dynamically (`<FCLEAR ,BAR ,LIGHTBIT>`)
- Behavior changes in darkness (`<NOT <FSET? ,BAR ,LIGHTBIT>>`)
- Functions to handle light changes: `NOW-LIT?` and `NOW-DARK?`

We have basic support but need to expand it.

## 3. Room Action Handlers with Different Phases

The ZIL game uses different action phases for rooms:

- `M-ENTER`: Called when entering a room
- `M-END`: Called at the end of each turn while in the room
- `M-BEG`: Called at the beginning of processing a command

We need to implement this multi-phase room handler system.

## 4. Special Exit Types

The ZIL game has various types of exits:

- Standard exits (`NORTH TO FOYER`)
- Conditional exits using a function (`WEST PER CLOAK-CHECK`)
- Message for blocked exits (`NORTH SORRY "You've only just arrived..."`)

We need to implement these special exit types.

## 5. Global Objects

The ZIL game has global objects that can appear in multiple locations:

- `GLOBAL-OBJECTS`: Objects accessible from anywhere
- `LOCAL-GLOBALS`: Objects accessible from specific rooms
- `GLOBAL-IN?`: Function to check if a global object is present in a room

We should implement this global object system.

## 6. Special Object Properties and Flags

The ZIL game uses special properties and flags:

- `VOWELBIT`: For choosing "a" vs "an" articles
- `PLURALBIT`: For pluralized objects
- `NARTICLEBIT`: For objects with no article
- `WEARBIT`/`WORNBIT`: For wearable items
- `DEVICEBIT`/`ONBIT`: For devices that can be turned on/off
- `FEMALEBIT`: For pronouns
- `PERSONBIT`: For characters/NPCs
- `READBIT`: For objects with readable text

We've implemented some of these but need to complete the set.

## 7. Special Text Properties

The ZIL game has different text properties:

- `LDESC`: Long description (for room or examined object)
- `FDESC`: First description (only shown first time)
- `TEXT`: Text for readable objects
- `TEXT-HELD`: Special text only shown when player is holding the object

We need to implement these different text property types.

## 8. Random Text Selection

The ZIL game has functions for random text:

- `<PICK-ONE ,SIGN-DESCRIPS>`: Returns a random element, cycling through all options
- `<PICK-ONE-R ,SIGN-READS>`: Returns a completely random element (with possible repeats)

We need to implement these random text selection functions.

## 9. Special Verb Handling

The ZIL game has special verb behavior:

- `THINK-ABOUT`: Custom verb with special handling
- `PUT-ON`: Verb for putting things on surfaces
- `FLIP`: Alternative to TURN-ON/TURN-OFF for devices

We need to implement more verbs beyond the basics.

## 10. Game Over Mechanics

The ZIL game has game-over functionality:

- `<JIGS-UP>`: Ends the game with a message
- `<V-QUIT>`: Quits the game

We should implement proper game ending mechanics.

## Implementation Priority

Based on what would give us the most functionality and make our engine more closely match ZIL capabilities, here's a suggested priority order:

1. **Event System**: This is the most complex missing piece and enables many dynamic behaviors
2. **Room Action Phases**: This enables room-specific behaviors at different times
3. **Light/Darkness Mechanics**: This is a core feature of many text adventures
4. **Special Exit Types**: These enable more complex puzzles and game flow control
5. **Special Text Properties**: This allows for more varied object descriptions
6. **Global Objects**: This enables more realistic world modeling
7. **Random Text Selection**: This adds variety to the game
8. **Additional Verbs and Flags**: These add more interaction possibilities
9. **Game Over Mechanics**: These provide proper game flow

Let's start by implementing the event system, which is the most significant missing feature. Would you like me to provide a detailed implementation for that component first?

# ZILFSwift - Room Action Phases System

A Swift implementation of a text adventure game engine, inspired by the original ZIL (Zork Implementation Language) used to create classic text adventures like Zork.

## Room Action Phase System

The Room Action Phase system allows rooms to respond to different events that occur during gameplay. It's modeled after ZIL's traditional room action phases while adding modern Swift capabilities like composition and prioritization.

### Available Action Phases

- **Enter Action**: Triggered when the player enters the room
- **Look Action**: Triggered when the player looks at the room
- **Begin Turn Action**: Triggered at the beginning of a turn, before command processing
- **End Turn Action**: Triggered at the end of each turn
- **Flash Action**: Triggered when important information should be shown even in brief mode
- **Command Action**: Triggered when a command is being processed

### Prioritized Actions

Actions can be assigned a priority level which determines their execution order:

- **Critical**: Highest priority, runs first
- **High**: Runs before normal actions
- **Normal**: Standard priority (default)
- **Low**: Lowest priority, runs last

When multiple actions are registered for the same phase, they execute in order of priority (highest first). If an action returns `true`, no further actions for that phase will be executed.

### Example Usage

```swift
let kitchen = Room(name: "Kitchen", description: "A well-equipped kitchen.")
let kettle = GameObject(name: "kettle", description: "A copper kettle")
kitchen.addToContainer(kettle)

// Track state
var kettleBoiling = false

// Add a high priority enter action
kitchen.addEnterAction(Room.PrioritizedAction(priority: .high) { room in
    print("You enter the kitchen.")
    return false // Allow other actions to run
})

// Intercept examining the kettle
kitchen.addCommandAction(Room.PrioritizedCommandAction { _, command in
    if case .examine(let obj) = command, obj === kettle {
        kettleBoiling = true
        print("You examine the kettle closely. It starts to boil.")
        return true // Stop other command processing
    }
    return false
})
```

### Common Room Patterns

The system includes several built-in room action patterns:

- **Dynamic Lighting**: Creates rooms that get lighting from another source
- **Random Atmosphere**: Displays random atmospheric messages
- **Visit Counter**: Tracks visit counts and shows different messages based on visits
- **Command Interceptor**: Allows rooms to handle specific commands
- **Scheduled Events**: Triggers events at specific turns

## Event System

The game also includes an event system that allows scheduling actions to occur after a specific number of turns. Events can be:

- One-time or recurring
- Priority-based
- Canceled or rescheduled

## Game Engine

The game engine ties everything together, handling:

- Command parsing and execution
- Player movement
- Object manipulation
- Time management

## Getting Started

```swift
// Create some rooms
let startRoom = Room(name: "Starting Room", description: "You are in a small room.")
let hallway = Room(name: "Hallway", description: "A long hallway stretches before you.")

// Connect the rooms
startRoom.setExit(direction: .north, room: hallway)
hallway.setExit(direction: .south, room: startRoom)

// Add some objects
let lamp = GameObject(name: "lamp", description: "A brass lamp.")
lamp.setFlag("takeable")
startRoom.addToContainer(lamp)

// Create a player and world
let player = Player(startingRoom: startRoom)
let world = GameWorld(player: player)

// Start the game
let engine = GameEngine(world: world)
engine.start()
```

## License

This project is released under the MIT License.

# Light/Darkness System

The ZILFSwift engine includes a comprehensive lighting system that models how light works in text adventures, inspired by ZIL's approach but with modern Swift capabilities.

## Key Features

### Room and Object Lighting

- **Naturally lit rooms**: Rooms can be naturally lit and don't require a light source
- **Light sources**: Objects can provide light when turned on
- **Transparent containers**: Light can pass through containers marked as transparent
- **Dynamic lighting**: Rooms can respond to changes in lighting conditions

### Light Status Tracking

- **Current lighting**: Check if rooms are currently lit
- **Light transitions**: Detect when rooms become lit or dark
- **Light source management**: Turn lights on/off individually or all at once

### Room Patterns for Lighting

- **Dynamic lighting pattern**: Creates rooms that respond to external light sources
- **Light change handler**: Responds when rooms change from lit to dark or vice versa
- **Light switch pattern**: Creates interactive light switches in rooms

## Example Usage

### Basic Room Lighting

```swift
// Create a lit room (e.g., outdoors)
let garden = Room(name: "Garden", description: "A beautiful garden")
garden.makeNaturallyLit()  // Always lit, no light source needed

// Create a dark room (e.g., cellar)
let cellar = Room(name: "Cellar", description: "A dark cellar")
cellar.makeDark()  // Requires a light source
```

### Light Sources

```swift
// Create a light source
let lantern = GameObject(name: "lantern", description: "A brass lantern")
lantern.makeLightSource(initiallyLit: false)  // Off by default

// Turn it on
lantern.turnLightOn()

// Or toggle it
lantern.toggleLight()
```

### Checking Lighting in Game Logic

```swift
// Check if a room is currently lit
if world.isRoomLit(room) {
    // Handle lit room
} else {
    // Handle darkened room
}

// React to lighting changes
if world.didRoomBecomeLit(room) {
    print("The room is suddenly illuminated!")
}

if world.didRoomBecomeDark(room) {
    print("The room is plunged into darkness!")
}
```

### Room Patterns

```swift
// Create a room with dynamic lighting based on a light source
let (enterAction, lookAction) = RoomActionPatterns.dynamicLighting(
    lightSource: { lantern.hasFlag(.lit) },
    enterDarkMessage: "You enter a pitch-black room.",
    enterLitMessage: "You enter a dimly lit room."
)

room.enterAction = enterAction
room.lookAction = lookAction

// Create a room with a light switch
let (switchAction, lightSource) = RoomActionPatterns.lightSwitch(
    switchName: "light switch",
    initiallyOn: false
)

room.beginCommandAction = switchAction

// React to lighting changes in a room
let lightChangeAction = RoomActionPatterns.lightingChangeHandler(
    world: world,
    onLitChange: { room in
        print("The room brightens as light fills it.")
        return true
    },
    onDarkChange: { room in
        print("The light fades, leaving the room in darkness.")
        return true
    }
)

room.beginTurnAction = lightChangeAction
```

This lighting system allows for realistic light modeling in your text adventures, including dark areas that require light sources, transparent objects that pass light, and dynamic light changes during gameplay.
