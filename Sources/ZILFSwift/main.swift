//
//  main.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation
import ZILFCore

let world = HelloWorldGame.create()
let engine = GameEngine(world: world)
engine.start()
