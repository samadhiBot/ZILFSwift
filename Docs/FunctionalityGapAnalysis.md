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
