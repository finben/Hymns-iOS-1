import Foundation

public class RegexUtil {

    /**
     * Regex format to extract information out of a hymn path.<br>
     * (\w+) --> matches any word character (letter, number, or underscore)<br>
     * ([a-z]?\d+[a-z]?) --> maybe a single letter followed by more than 1 digit followed by 0 or more letters. eg: 13, 13f, c333, 54de<br>
     * (?:/f=(\w+\z)|\z) --> conditional to extract the media type if the url contains a media type. eg: ns/17 or ns/17/f=(pdf)<br>
     *   ?: --> do not extract whatever is matched<br>
     *          http://stackoverflow.com/questions/3378773/can-i-use-an-or-in-regex-without-capturing-whats-enclosed<br>
     *   \w+\z --> any number of word characters at the end of the string<br>
     *   | --> or statement<br>
     *   \z --> the end of the string<br>
     *   <p/>
     *   Examples:<br>
     *       /en/hymn/h/594 --> h, 594, null <br>
     *       /en/hymn/h/13f/f=mp3 --> h, 13f, mp3 <br>
     */
    static let songPathFormat = "(\\w+)/([a-z]?\\d+[a-z]*)(?:/f=(\\w+\\z)|\\z)"

    /**
     * Regex format to extract information out of a scripture reference that doesn't include the verse<br>
     * ([123]?\s?\w+) --> maybe a number 1, 2, or 3, followed by maybe a white space, followed by 1
     *                    or more word characters
     * Examples:<br>
     *     2 Chronicles 15:45
     *     Psalms 45
     *     Psalms
     *     1 John 5:12
     *     3 John 5:12
     *     Jude 1:12
     *     Matthew 17:5-14
     *     Song of Songs 4:12
     *     6:19
     *     80
     *     cf. Psalms 16
     *
     *     See songs:
     *     https://www.hymnal.net/en/hymn/ns/123
     *     https://www.hymnal.net/en/hymn/ns/138
     *     https://www.hymnal.net/en/hymn/h/600
     */
    static let scripturePatternNoVerse = "(?:cf. )?(Song of Songs|(?:[123]\\s)?[a-zA-Z]+)?(?:\\s?(\\d+))?"

    /**
     * Regex format to extract information out of the verse portion of a scripture reference<br>
     */
    static let scripturePatternVerse = "\\A(\\d+(?:-?\\d+)?)\\z"

    /**
     * @param path path of the song
     * @return parsed hymn type from path, or null if it's not found
     */
    static func getHymnType(path: String) -> HymnType? {
        let regex = NSRegularExpression(songPathFormat, options: .caseInsensitive)
        let pathWithoutQueryParams = removeQueryParams(path: path)

        if let match = regex.firstMatch(in: pathWithoutQueryParams, options: [], range: NSRange(location: 0, length: pathWithoutQueryParams.utf16.count)) {
            if let hymnTypeRange = Range(match.range(at: 1), in: pathWithoutQueryParams) {
                return HymnType.fromAbbreviatedValue(String(pathWithoutQueryParams[hymnTypeRange]))
            }
        }
        return nil
    }

    /**
     * @param path path of the song
     * @return parsed hymn number from path, or null if it's not found
     */
    static func getHymnNumber(path: String) -> String? {
        let regex = NSRegularExpression(songPathFormat, options: .caseInsensitive)
        let pathWithoutQueryParams = removeQueryParams(path: path)

        if let match = regex.firstMatch(in: pathWithoutQueryParams, options: [], range: NSRange(location: 0, length: pathWithoutQueryParams.utf16.count)) {
            if let hymnNumberRange = Range(match.range(at: 2), in: pathWithoutQueryParams) {
                return String(pathWithoutQueryParams[hymnNumberRange])
            }
        }
        return nil
    }

    static func getQueryParams(path: String) -> [String: String]? {
        guard let url = URL(string: path), let query = url.query else { return nil }
        var queryParams = [String: String]()
        for pair in query.components(separatedBy: "&") {
            let key = pair.components(separatedBy: "=")[0]
            let value = pair
                .components(separatedBy: "=")[1]
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? ""
            queryParams[key] = value
        }
        return queryParams.isEmpty ? nil : queryParams
    }

    private static func removeQueryParams(path: String) -> String {
        if let index = path.firstIndex(of: "?") {
            return String(path.prefix(upTo: index))
        } else {
            return path
        }
    }

    static func getBookFromReference(_ reference: String) -> Book? {
        guard let firstReference = reference.components(separatedBy: ":").first else {
            return nil
        }

        let regex = NSRegularExpression(scripturePatternNoVerse, options: .caseInsensitive)
        if let match = regex.firstMatch(in: firstReference, options: [], range: NSRange(location: 0, length: firstReference.utf16.count)) {
            if let hymnTypeRange = Range(match.range(at: 1), in: firstReference) {
                return Book.from(bookName: String(reference[hymnTypeRange]))
            }
        }
        return nil
    }

    static func getChapterFromReference(_ reference: String) -> String? {
        // If the reference is just a single digit, then that's just the verse only, so return
        // a null chapter
        if reference.isPositiveInteger {
            return nil
        }

        guard let firstReference = reference.components(separatedBy: ":").first else {
            return nil
        }
        let regex = NSRegularExpression(scripturePatternNoVerse, options: .caseInsensitive)
        if let match = regex.firstMatch(in: firstReference, options: [], range: NSRange(location: 0, length: firstReference.utf16.count)) {
            if let hymnNumberRange = Range(match.range(at: 2), in: firstReference) {
                return String(reference[hymnNumberRange])
            }
        }
        return nil
    }

    static func getVerseFromReference(_ reference: String) -> String? {
        var secondReference: String
        if reference.contains(":") {
            guard let ref = reference.components(separatedBy: ":").dropFirst().first ?? nil else {
                return nil
            }
            secondReference = ref
        } else {
            secondReference = reference
        }

        let regex = NSRegularExpression(scripturePatternVerse, options: .caseInsensitive)
        if let match = regex.firstMatch(in: secondReference, options: [], range: NSRange(location: 0, length: secondReference.utf16.count)) {
            if let hymnTypeRange = Range(match.range(at: 1), in: secondReference) {
                return String(secondReference[hymnTypeRange])
            }
        }
        return nil
    }
}

// https://www.hackingwithswift.com/articles/108/how-to-use-regular-expressions-in-swift
extension NSRegularExpression {
    // Create convenience method to avoid the try! which swiftlint doesn't like
    convenience init(_ pattern: String, options: Options) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }

    func matches(_ string: String) -> Bool {
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: [], range: range) != nil
    }
}
