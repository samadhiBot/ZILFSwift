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
    if case .examine(let obj, _) = command, obj === kettle {
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
lamp.setFlag(.isTakable)
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
