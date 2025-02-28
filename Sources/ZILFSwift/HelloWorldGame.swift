//
//  HelloWorldGame.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation
import ZILFCore

struct HelloWorldGame {
    static func create() -> GameWorld {
        // Create rooms
        let entrance = Room(name: "Entrance", description: "You are standing at the entrance to a small cave. Sunlight streams in from outside.")
        entrance.makeNaturallyLit()

        let mainCavern = Room(name: "Main Cavern", description: "This spacious cavern has smooth walls that glisten with moisture. A strange glow emanates from deeper in the cave.")
        mainCavern.makeNaturallyLit()

        let treasureRoom = Room(name: "Treasure Room", description: "This small chamber is filled with a soft, magical light. The walls are adorned with ancient markings.")
        treasureRoom.makeNaturallyLit()

        // Connect rooms with exits
        entrance.setExit(direction: .north, room: mainCavern)
        mainCavern.setExit(direction: .south, room: entrance)
        mainCavern.setExit(direction: .east, room: treasureRoom)
        treasureRoom.setExit(direction: .west, room: mainCavern)

        // Create player
        let player = Player(startingRoom: entrance)

        // Create game world
        let world = GameWorld(player: player)
        world.registerRoom(entrance)
        world.registerRoom(mainCavern)
        world.registerRoom(treasureRoom)

        // Create objects
        let lantern = GameObject(name: "lantern", description: "A brass lantern that provides warm light.", location: entrance)
        lantern.setFlag("takeable")
        lantern.makeLightSource(initiallyLit: false)

        let coin = GameObject(name: "gold coin", description: "A shiny gold coin with strange markings.", location: mainCavern)
        coin.setFlag("takeable")

        let chest = GameObject(name: "treasure chest", description: "An ornate wooden chest with intricate carvings.", location: treasureRoom)
        chest.setFlag("container")
        chest.setFlag("openable")
        // Chest is not takeable

        // Maybe add a treasure inside the chest
        let treasure = GameObject(name: "golden amulet", description: "An exquisite golden amulet that gleams with an inner light.", location: chest)
        treasure.setFlag("takeable")
        treasure.makeLightSource(initiallyLit: true)

        // Make sure to close the chest
        chest.clearFlag("open")

        world.registerObject(lantern)
        world.registerObject(coin)
        world.registerObject(chest)
        world.registerObject(treasure)

        // Add event examples
        world.queueEvent(name: "lantern-flicker", turns: 3) {
            print("The lantern's flame flickers briefly.")
            return true
        }

        world.queueEvent(name: "ambient-sounds", turns: -1) {
            // This will run every turn
            let sounds = [
                "You hear water dripping somewhere nearby.",
                "A cool breeze rustles through the cave.",
                "There's a distant sound of grinding stone.",
                "You hear a faint whisper echoing off the walls."
            ]
            if Int.random(in: 1...4) == 1 {  // 25% chance each turn
                print(sounds.randomElement()!)
                return true
            }
            return false
        }

        // Add room action handlers
        mainCavern.endTurnAction = { room in
            if world.isEventRunning(named: "lantern-flicker") {
                print("The cavern walls seem to shimmer in the flickering light.")
                return true // Output was produced
            }
            return false // No output
        }

        treasureRoom.enterAction = { room in
            print("You feel a sense of awe as you enter this ancient chamber.")
            return true // Output was produced
        }

        return world
    }
}
