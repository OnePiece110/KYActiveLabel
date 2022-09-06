//
//  KYFormatting.swift
//  KYActiveLabel
//
//  Created by keyon on 2022/9/6.
//

import Foundation

public extension NSAttributedString {

    convenience init(formatting string: String, style: KYFormattedStringStyle) {
        let parse = KYParse(style: style)
        do {
            let output = try parse.parse(string)
            self.init(attributedString: output)
        } catch {
            self.init(string: string, attributes: style.attributes(forElement: "body"))
        }
    }

}

// MARK: KYFormattedStringStyle
public struct KYFormattedStringStyle {
    private var attributes = [String: [NSAttributedString.Key: Any]]()

    public init(attributes: [String: [NSAttributedString.Key: Any]]) {
        self.attributes = attributes
    }

    func attributes(forElement element: String) -> [NSAttributedString.Key: Any]? {
        self.attributes[element]
    }
}

// MARK: KYParse
private final class KYParse: NSObject, XMLParserDelegate {
    private var text = ""
    private let style: KYFormattedStringStyle
    private var elements = [Element]()
    private var attributes = [(NSRange, [NSAttributedString.Key: Any])]()
    private var parseError: Error?
    private static let hrefRegex = try? KYRegex("<a[^>]*?href=\"([^\"]+)\">")

    private struct Element {
        let name: String
        let startOffset: Int
        let attributes: [NSAttributedString.Key: Any]
    }

    init(style: KYFormattedStringStyle) {
        self.style = style
    }

    func parse(_ string: String) throws -> NSAttributedString {
        guard let data = preprocess(string).data(using: .utf8) else {
            throw NSError(domain: "com.github.parser", code: -1, userInfo: [NSDebugDescriptionErrorKey: "Failed to process the input string"])
        }
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        if let parseError = parseError {
            throw parseError
        }
        return makeAttributedString()
    }

    private func preprocess(_ string: String) -> String {
        var string = string

        // 将“<br>”替换为“行分隔符”（不分隔段落）要分隔段落，请使用 '\b'
        string = string.replacingOccurrences(of: "<br ?/?>", with: "\u{2028}", options: .regularExpression, range: nil)

        string = preprocessLinks(string)

        return "<body>\(string)</body>"
    }

    private func preprocessLinks(_ string: String) -> String {
        guard let regex = KYParse.hrefRegex else {
            return string
        }
        return regex.replaceMatches(in: string, sanitizeURL)
    }

    private func sanitizeURL(_ url: Substring) -> String? {
        guard url.contains("&") else {
            return nil
        }
        guard var comp = URLComponents(string: String(url)) else {
            return nil
        }
        let query = (comp.queryItems ?? [])
            .map { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&amp;")
        comp.queryItems = nil
        var output = comp.url?.absoluteString
        if !query.isEmpty {
            output?.append("?\(query)")
        }
        return output
    }

    private func makeAttributedString() -> NSAttributedString {
        let output = NSMutableAttributedString(string: text)
        // Apply tags in reverse, more specific tags are applied last.
        for (range, attributes) in attributes.reversed() {
            let lb = text.index(text.startIndex, offsetBy: range.lowerBound)
            let ub = text.index(text.startIndex, offsetBy: range.upperBound)
            let range = NSRange(lb..<ub, in: text)
            output.addAttributes(attributes, range: range)
        }
        return output
    }

    // MARK: XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        var attributes = style.attributes(forElement: elementName) ?? [:]
        if elementName == "a", let url = attributeDict["href"].map(URL.init(string:)) {
            attributes[.link] = url
        }
        let element = Element(name: elementName, startOffset: text.count, attributes: attributes)
        elements.append(element)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let element = elements.popLast() else {
            return assertionFailure("No opening tag for \(elementName)")
        }
        guard element.name == elementName else {
            return assertionFailure("Closing tag mismatch. Expected: \(element.name), got: \(elementName)")
        }
        let range = NSRange(location: element.startOffset, length: text.count - element.startOffset)
        attributes.append((range, element.attributes))
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text.append(string)
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        // Do nothing
    }
}

// MARK: KYRegex
final class KYRegex {

    struct Match {
        let fullMatch: Substring
        let groups: [Substring]
    }

    private let regex: NSRegularExpression

    init(_ pattern: String, _ options: NSRegularExpression.Options = []) throws {
        self.regex = try NSRegularExpression(pattern: pattern, options: options)
    }

    func isMatch(_ s: String) -> Bool {
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        return regex.firstMatch(in: s, options: [], range: range) != nil
    }

    func matches(in s: String) -> [Match] {
        let range = NSRange(s.startIndex..<s.endIndex, in: s)
        let matches = regex.matches(in: s, options: [], range: range)
        return matches.map { match in
            let ranges = (0..<match.numberOfRanges)
                .map(match.range(at:))
                .filter{ $0.location != NSNotFound }
            return Match(fullMatch: s[Range(match.range, in: s)!], groups: ranges.dropFirst().map{ s[Range($0, in: s)!]})
        }
    }

    func replaceMatches(in string: String, _ transform: (Substring) -> String?) -> String {
        var offset = 0
        var string = string
        for group in matches(in: string).flatMap(\.groups) {
            guard let replacement = transform(group) else {
                continue
            }
            let startIndex = string.index(group.startIndex, offsetBy: offset)
            let endIndex = string.index(group.endIndex, offsetBy: offset)
            string.replaceSubrange(startIndex..<endIndex, with: replacement)
            offset += replacement.count - group.count
        }
        return string
    }
}
