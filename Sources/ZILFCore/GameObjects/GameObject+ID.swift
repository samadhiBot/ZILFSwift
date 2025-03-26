import Foundation

extension GameObject {
    /// A single-word unique identifier for any game object.
    public struct ID: Equatable, ExpressibleByStringLiteral {
        private let rawValue: String

        public init(stringLiteral value: StringLiteralType) {
            assert(
                value.components(separatedBy: .whitespacesAndNewlines).count == 1,
                "GameObject.ID must be a single word"
            )
            rawValue = value
        }
    }
}
