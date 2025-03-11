import Foundation
import ZILFCore

let world = HelloWorldGame.create()
let engine = GameEngine(world: world, worldCreator: HelloWorldGame.create)
try engine.start()
