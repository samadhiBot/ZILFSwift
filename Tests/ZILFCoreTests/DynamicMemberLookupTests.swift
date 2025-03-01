//
//  DynamicMemberLookupTests.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 8/1/25.
//

import Foundation
import Testing
@testable import ZILFCore

// Extension to demonstrate computed properties as an alternative to dynamic member lookup
extension GameObject {
    var healthPoints: Int {
        get { getState(forKey: "healthPoints") as Int? ?? 0 }
        set { setState(newValue, forKey: "healthPoints") }
    }

    var hasKey: Bool {
        get { getState(forKey: "hasKey") as Bool? ?? false }
        set { setState(newValue, forKey: "hasKey") }
    }
}

@Suite("Dynamic Member Lookup Tests")
struct DynamicMemberLookupTests {

    @Test("Understanding dynamic member lookup implementation challenges")
    func testDynamicMemberLookupChallenges() {
        let object = GameObject(name: "test object", description: "A test object")

        // Set up some state values using the traditional API
        object.setState(100, forKey: "score")
        object.setState(true, forKey: "isActive")
        object.setState("novice", forKey: "rank")

        // When using dynamic member lookup with generics, we need type information
        // So we use explicit type annotations with the 'as' operator:
        let dynamicScore = object.score as Int?
        let dynamicActive = object.isActive as Bool?
        let dynamicRank = object.rank as String?

        // Verify retrieval works
        #expect(dynamicScore == 100)
        #expect(dynamicActive == true)
        #expect(dynamicRank == "novice")
    }

    @Test("Practical usage patterns with getState/setState")
    func testUsagePatterns() {
        let object = GameObject(name: "character", description: "A game character")

        // Set some properties
        object.setState(100, forKey: "health")
        object.setState(50, forKey: "mana")
        object.setState(["sword", "shield"], forKey: "inventory")

        // Different ways to access state:

        // 1. Traditional way with explicit casting
        let health: Int? = object.getState(forKey: "health")
        #expect(health == 100)

        // 2. Checking and casting manually
        if let manaValue: Any = object.getState(forKey: "mana") {
            if let mana = manaValue as? Int {
                #expect(mana == 50)
            }
        }

        // 3. For collections:
        if let inventory: [String] = object.getState(forKey: "inventory") {
            #expect(inventory.count == 2)
            #expect(inventory.contains("sword"))
            #expect(inventory.contains("shield"))
        }

        // 4. Default values with nil coalescing
        let stamina: Int? = object.getState(forKey: "stamina")
        #expect(stamina == nil)
        let safeStamina = stamina ?? 0
        #expect(safeStamina == 0)
    }

    @Test("Improving ergonomics with computed properties")
    func testComputedProperties() {
        let object = GameObject(name: "player", description: "The player character")

        // Setting values using the computed properties
        object.healthPoints = 50
        object.hasKey = false

        // Reading using computed properties
        #expect(object.healthPoints == 50)
        #expect(object.hasKey == false)

        // Update the values
        object.healthPoints = 65
        object.hasKey = true

        // And we can verify the underlying mechanism still works
        #expect(object.getState(forKey: "healthPoints") as Int? == 65)
        #expect(object.getState(forKey: "hasKey") as Bool? == true)
    }

    @Test("Creating properties dynamically")
    func testDynamicPropertyCreation() {
        let object = GameObject(name: "quest-tracker", description: "Tracks quest progress")

        // Create some quest tracking properties at runtime
        object.setState("completed", forKey: "quest_dragon")
        object.setState("in-progress", forKey: "quest_treasure")
        object.setState(true, forKey: "quest_princess_available")

        // Access properties using getState with proper casting
        let dragonQuest: String? = object.getState(forKey: "quest_dragon")
        let treasureQuest: String? = object.getState(forKey: "quest_treasure")
        let princessAvailable: Bool? = object.getState(forKey: "quest_princess_available")

        #expect(dragonQuest == "completed")
        #expect(treasureQuest == "in-progress")
        #expect(princessAvailable == true)

        // Add some timestamps for completed quests
        let now = Date()
        for questKey in ["quest_dragon", "quest_treasure"] {
            if let quest: String = object.getState(forKey: questKey), quest == "completed" {
                object.setState(now, forKey: "\(questKey)_last_updated")
            }
        }

        // Check our new dynamically generated properties
        #expect(object.getState(forKey: "quest_dragon_last_updated") as Date? != nil)
        #expect(object.getState(forKey: "quest_treasure_last_updated") == nil) // Quest is in-progress
        #expect(object.getState(forKey: "quest_princess_last_updated") == nil) // Not created
    }

    @Test("Testing new simplified dynamic member lookup implementation")
    func testSimplifiedDynamicMemberLookup() {
        let object = GameObject(name: "test object", description: "A test object for dynamic member lookup")

        // Set values using the traditional API
        object.setState(100, forKey: "health")
        object.setState("warrior", forKey: "role")
        object.setState(true, forKey: "active")

        // Get values using dynamic member lookup with explicit type annotations
        let health = object.health as Int?
        let role = object.role as String?
        let active = object.active as Bool?

        // Verify the values are correct
        #expect(health == 100)
        #expect(role == "warrior")
        #expect(active == true)

        // Update values using dynamic member lookup
        object.health = 80
        object.active = false

        // Verify the updates worked
        #expect(object.health as Int? == 80)
        #expect(object.active as Bool? == false)

        // Use nil-coalescing for default values
        let stamina = object.stamina as Int? ?? 50
        #expect(stamina == 50) // Default value used

        // Setting nil removes the property - use removeState directly
        // since the compiler can't infer T for nil assignments
        object.removeState(forKey: "health")
        #expect(object.health as Int? == nil)

        // Test removal of state via removeState
        object.role = "wizard"
        #expect(object.role as String? == "wizard")
        object.removeState(forKey: "role")
        #expect(object.role as String? == nil)
    }

    @Test("Testing property existence checking with isSet")
    func testPropertyExistenceChecking() {
        let object = GameObject(name: "test object", description: "A test object for isSet testing")

        // Initially, the property doesn't exist
        #expect(object.score.isSet == false)
        #expect(object.hasProperty("score") == false)

        // Set the property
        object.score = 100

        // Now it should exist
        #expect(object.score.isSet == true)
        #expect(object.hasProperty("score") == true)

        // Type doesn't matter for existence checking
        #expect(object.score as Int? == 100)

        // Remove the property
        object.removeState(forKey: "score")

        // Now it should not exist again
        #expect(object.score.isSet == false)
        #expect(object.hasProperty("score") == false)

        // Compound example: only access a property if it exists
        object.playerName = "Hero"

        let displayName: String
        if object.playerName.isSet {
            displayName = (object.playerName as String?) ?? "Unknown"
        } else {
            displayName = "Unnamed Hero"
        }

        #expect(displayName == "Hero")

        // Alternative using hasProperty
        let otherObject = GameObject(name: "other", description: "Another test object")

        let otherDisplayName: String
        if otherObject.hasProperty("playerName") {
            otherDisplayName = (otherObject.playerName as String?) ?? "Unknown"
        } else {
            otherDisplayName = "Unnamed Hero"
        }

        #expect(otherDisplayName == "Unnamed Hero")
    }
}
