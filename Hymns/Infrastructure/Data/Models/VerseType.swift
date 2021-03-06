import Foundation

/**
 * Represents the type that a verse can take.
 */
enum VerseType: String, Codable {
    case verse
    case chorus
    case other

    static let all = [verse, chorus, other]
}
