# Special Exit Types

The ZILFSwift engine includes a powerful special exit system that allows for complex connections between rooms beyond simple directional exits.

## Key Features

### Conditional Exits

- **Visibility control**: Exits can be hidden from room descriptions
- **Custom conditions**: Exits can require specific conditions to be available
- **Success/failure messages**: Display messages when exits are used or unavailable
- **Custom actions**: Execute custom code when exits are traversed

### Common Exit Types

- **Hidden exits**: Secret passages that aren't listed in room descriptions
- **Locked exits**: Doors that require specific keys or items
- **One-way exits**: Passages that only work in one direction
- **Scripted exits**: Exits that trigger custom code when used
- **Conditional exits**: Passages that require specific game states

## Example Usage

### Basic Special Exit

```swift
// Create a special exit with a custom condition
let specialExit = SpecialExit(
    destination: secretRoom,
    world: gameWorld,
    condition: { world in
        // Only available if player has the magic amulet
        return world.player.contents.contains { $0.name == "magic amulet" }
    },
    successMessage: "The wall shimmers and you pass through!",
    failureMessage: "The wall feels solid."
)

// Add it to a room
startRoom.setSpecialExit(direction: .north, specialExit: specialExit, world: gameWorld)
```

### Hidden Exit

```swift
// Create a hidden exit that's revealed after a specific action
var exitRevealed = false

room.setHiddenExit(
    direction: .east,
    destination: secretPassage,
    world: gameWorld,
    condition: { _ in exitRevealed },
    revealMessage: "You've discovered a hidden passage to the east!"
)

// Then elsewhere in your code:
room.beginCommandAction = { room, command in
    if case .examine(let obj) = command, obj.name == "bookshelf" {
        exitRevealed = true
        print("As you examine the bookshelf, you notice a loose book. Pulling it reveals a secret passage!")
        return true
    }
    return false
}
```

### Locked Exit

```swift
// Create a key item
let goldKey = GameObject(name: "gold key", description: "An ornate gold key")
goldKey.setFlag("takeable")

// Create a locked door that requires the key
room.setLockedExit(
    direction: .north,
    destination: treasureVault,
    world: gameWorld,
    key: goldKey,
    lockedMessage: "The door is locked. You need a key.",
    unlockedMessage: "You unlock the door with the gold key and push it open."
)
```

### One-Way Exit

```swift
// Create a chute or slide that goes down but can't be climbed back up
upperRoom.setOneWayExit(
    direction: .down,
    destination: lowerRoom,
    world: gameWorld,
    message: "You slide down the chute and land in the room below."
)
```

### Scripted Exit

```swift
// Create an exit that triggers a special effect
room.setScriptedExit(
    direction: .west,
    destination: magicRoom,
    world: gameWorld,
    script: { world in
        print("Sparkles of magic energy surround you as you pass through the portal!")

        // Maybe update game state
        world.player.setState(true, forKey: "visited_magic_realm")

        // Or add effects
        world.queueEvent(name: "magic_aftereffect", turns: 3) {
            print("You feel the residual magic tingling on your skin.")
            return true
        }
    }
)
```

### Conditional Exit

```swift
// Create an exit that's only available during certain times
var isNight = false

room.setConditionalExit(
    direction: .up,
    destination: stargazingDeck,
    world: gameWorld,
    condition: { _ in isNight },
    failureMessage: "The door to the observation deck is closed during daylight hours."
)
```

This special exit system allows you to create complex puzzles and game flow mechanics in your text adventures, including secret passages, locked doors, magical portals, and other conditional movement.
