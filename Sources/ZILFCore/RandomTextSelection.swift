//
//  RandomTextSelection.swift
//  ZILFSwift
//
//  Created on current date
//

import Foundation

/// Represents a collection of text options that can be randomly selected from
public struct RandomTextCollection {
    /// The array of text options to choose from
    private let options: [String]

    /// Random number generator used for text selection
    private var generator: any RandomNumberGenerator

    /// Initialize with a list of text options
    /// - Parameters:
    ///   - options: Array of text strings to choose from
    ///   - generator: Optional custom random number generator (uses system default if not provided)
    public init(options: [String], generator: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.options = options
        self.generator = generator
    }

    /// Get a random text option from the collection
    /// - Returns: A randomly selected string from the options
    public func getRandomText() -> String {
        guard !options.isEmpty else { return "" }

        // Create a local copy of the generator that we can mutate
        var localGenerator = generator
        let index = Int.random(in: 0..<options.count, using: &localGenerator)
        return options[index]
    }

    /// Number of options in this collection
    public var count: Int {
        options.count
    }

    /// Check if this collection is empty
    public var isEmpty: Bool {
        options.isEmpty
    }
}

/// Extension for game objects to support random text collections
public extension GameObject {
    /// Key prefix for storing random text collections
    private static let randomTextPrefix = "randomText_"

    /// Set a random text collection for a specific key
    /// - Parameters:
    ///   - options: Array of text options
    ///   - forKey: Identifier for this random text collection
    func setRandomTextOptions(_ options: [String], forKey key: String) {
        let collectionKey = GameObject.randomTextPrefix + key
        let collection = RandomTextCollection(options: options)
        setState(collection, forKey: collectionKey)
    }

    /// Get a random text collection for a specific key
    /// - Parameter forKey: Identifier for the random text collection
    /// - Returns: The RandomTextCollection if it exists, nil otherwise
    func getRandomTextCollection(forKey key: String) -> RandomTextCollection? {
        let collectionKey = GameObject.randomTextPrefix + key
        return getState(forKey: collectionKey)
    }

    /// Get a random text option from a specific collection
    /// - Parameter forKey: Identifier for the random text collection
    /// - Returns: A randomly selected text string, or nil if collection doesn't exist
    func getRandomText(forKey key: String) -> String? {
        guard let collection = getRandomTextCollection(forKey: key) else {
            return nil
        }
        return collection.getRandomText()
    }

    /// Add a text option to an existing random text collection
    /// - Parameters:
    ///   - text: Text option to add
    ///   - forKey: Identifier for the random text collection
    /// - Returns: True if successfully added, false if collection doesn't exist
    @discardableResult
    func addRandomTextOption(_ text: String, forKey key: String) -> Bool {
        let collectionKey = GameObject.randomTextPrefix + key

        // Get existing collection or return false
        guard let collection: RandomTextCollection = getState(forKey: collectionKey) else {
            return false
        }

        // Create new collection with added option
        var options = collection.getOptions()
        options.append(text)

        // Replace old collection
        let newCollection = RandomTextCollection(options: options)
        setState(newCollection, forKey: collectionKey)

        return true
    }
}

// Extension to expose options array for modification
extension RandomTextCollection {
    /// Get the array of text options (for modification)
    /// - Returns: Copy of the options array
    func getOptions() -> [String] {
        return options
    }
}
