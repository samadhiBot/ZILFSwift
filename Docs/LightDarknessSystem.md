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
