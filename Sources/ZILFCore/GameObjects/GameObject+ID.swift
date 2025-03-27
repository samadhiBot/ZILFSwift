import Foundation

extension GameObject {
    /// A single-word unique identifier for any game object.
    public struct ID: ExpressibleByStringLiteral, Sendable {
        public let rawValue: String

        public init(stringLiteral value: StringLiteralType) {
            let words = value.components(separatedBy: .whitespacesAndNewlines)
            rawValue = words.enumerated().reduce("") { result, element in
                let (index, word) = element
                guard !word.isEmpty else { return result }
                return if index == 0 {
                    result + word.prefix(1).lowercased() + word.dropFirst()
                } else {
                    result + word.prefix(1).uppercased() + word.dropFirst().lowercased()
                }
            }

            assert(!rawValue.isEmpty, "GameObject.ID cannot be empty.")
        }
    }
}

extension GameObject.ID: Equatable {
    public static func == (lhs: GameObject.ID, rhs: GameObject.ID) -> Bool {
        lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
    }
}
