import Foundation
import Testing
import ZILFCore

struct GameObjectIDTests {
    @Test func singleWord() {
        #expect(GameObject.ID("sword") == "sword")
        #expect(GameObject.ID("goldCoin") == "goldCoin")
        #expect(GameObject.ID("CIA") == "cia")

        #expect(GameObject.ID("sword").rawValue == "sword")
        #expect(GameObject.ID("goldCoin").rawValue == "goldCoin")
        #expect(GameObject.ID("CIA").rawValue == "cIA")
    }

    @Test func multiWord() {
        #expect(GameObject.ID("glowing sword") == "glowingSword")
        #expect(GameObject.ID("Hallway to Study") == "hallwayToStudy")
        #expect(GameObject.ID("Pyramid of Giza") == "pyramidOfGiza")

        #expect(GameObject.ID("glowing sword").rawValue == "glowingSword")
        #expect(GameObject.ID("Hallway to Study").rawValue == "hallwayToStudy")
        #expect(GameObject.ID("Pyramid of Giza").rawValue == "pyramidOfGiza")
    }

    @Test func caseInsensitive() {
        #expect(GameObject.ID("money.com") == "Money.com")
        #expect(GameObject.ID("sword") == "SWORD")
        #expect(GameObject.ID("goldCoin") == "goldCOIN")
        #expect(GameObject.ID("Glowing Sword") == "glowingSWORD")
        #expect(GameObject.ID("HALLWAY TO STUDY") == "hallwayToStudy")
    }
}
