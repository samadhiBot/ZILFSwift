import Foundation

/// Represents a collection of text options that can be randomly selected from.
public struct RandomTextCollection {
    /// The number of options in this collection.
    public var count: Int {
        options.count
    }

    /// Flag indicating whether this collection is empty.
    public var isEmpty: Bool {
        options.isEmpty
    }

    /// The array of text options to choose from.
    private let options: [String]

    /// Random number generator used for text selection.
    private var generator: any RandomNumberGenerator

    /// Initializes a new random text collection.
    /// - Parameters:
    ///   - options: Array of text strings to choose from.
    ///   - generator: Optional custom random number generator (uses system default if not provided).
    public init(
        options: [String], generator: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.options = options
        self.generator = generator
    }

    /// Gets a random text option from the collection.
    /// - Returns: A randomly selected string from the options.
    public func getRandomText() -> String {
        guard !options.isEmpty else { return "" }

        // Create a local copy of the generator that we can mutate
        var localGenerator = generator
        let index = Int.random(in: 0..<options.count, using: &localGenerator)
        return options[index]
    }

    /// Gets the array of text options.
    /// - Returns: Copy of the options array.
    func getOptions() -> [String] {
        return options
    }
}

/// Extension for game objects to support random text collections.
extension GameObject {
    /// Adds a text option to an existing random text collection.
    /// - Parameters:
    ///   - text: Text option to add.
    ///   - forKey: Identifier for the random text collection.
    /// - Returns: `true` if successfully added, `false` if collection doesn't exist.
    @discardableResult
    public func addRandomTextOption(_ text: String, forKey key: String) -> Bool {
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

    /// Gets a random text collection for a specific key.
    /// - Parameter key: Identifier for the random text collection.
    /// - Returns: The `RandomTextCollection` if it exists, `nil` otherwise.
    public func getRandomTextCollection(forKey key: String) -> RandomTextCollection? {
        let collectionKey = GameObject.randomTextPrefix + key
        return getState(forKey: collectionKey)
    }

    /// Gets a random text option from a specific collection.
    /// - Parameter key: Identifier for the random text collection.
    /// - Returns: A randomly selected text string, or `nil` if collection doesn't exist.
    public func getRandomText(forKey key: String) -> String? {
        guard let collection = getRandomTextCollection(forKey: key) else {
            return nil
        }
        return collection.getRandomText()
    }

    /// Sets a random text collection for a specific key.
    /// - Parameters:
    ///   - options: Array of text options.
    ///   - key: Identifier for this random text collection.
    public func setRandomTextOptions(_ options: [String], forKey key: String) {
        let collectionKey = GameObject.randomTextPrefix + key
        let collection = RandomTextCollection(options: options)
        setState(collection, forKey: collectionKey)
    }

    /// Key prefix for storing random text collections.
    private static let randomTextPrefix = "randomText_"
}
