//
//  TestFailure.swift
//  ZILFSwift
//
//  Created by Chris Sessions on 2/25/25.
//

import Foundation

struct TestFailure: Error, CustomStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var description: String {
        return message
    }
}
