//
//  TestOutputHandler.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/26/25.
//

import Foundation
@testable import ZILFCore

/// Output handler for tests - captures text instead of printing it
class TestOutputHandler: OutputHandler {
    var output = ""

    func output(_ text: String, terminator: String) {
        output += text + terminator
    }

    func output(_ text: String) {
        output(text, terminator: "\n")
    }

    func clear() {
        output = ""
    }
}
