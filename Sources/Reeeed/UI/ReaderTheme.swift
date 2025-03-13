import SwiftUI

#if os(macOS)
import AppKit
public typealias UINSColor = NSColor
#else
import UIKit
public typealias UINSColor = UIColor
#endif

public struct ReaderTheme {
    public var foreground: UINSColor // for body text
    public var foreground2: UINSColor // used for button titles
    public var background: UINSColor // page background
    public var background2: UINSColor // used for buttons
    public var link: UINSColor
    public var additionalCSS: String?
    
    public var fontName: String
    public var fontSize: Int
    public var isBold: Bool
    public var lineHeight: CGFloat
    

    public init(
        foreground: UINSColor = .reader_Primary,
        foreground2: UINSColor = .reader_Secondary,
        background: UINSColor = .reader_Background,
        background2: UINSColor = .reader_Background2,
        link: UINSColor = .systemBlue,
        fontName: String = "system-ui",
        fontSize: Int = 16,
        isBold: Bool = false,
        lineHeight: CGFloat = 1.5,
        additionalCSS: String? = nil
    ) {
        self.foreground = foreground
        self.foreground2 = foreground2
        self.background = background
        self.background2 = background2
        self.link = link
        self.fontName = fontName
        self.fontSize = fontSize
        self.isBold = isBold
        self.lineHeight = lineHeight
        self.additionalCSS = additionalCSS
    }
}

public extension UINSColor {
#if os(macOS)
    static let reader_Primary = NSColor.labelColor
    static let reader_Secondary = NSColor.secondaryLabelColor
    static let reader_Background = NSColor.textBackgroundColor
    static let reader_Background2 = NSColor.windowBackgroundColor
#else
    static let reader_Primary = UIColor.label
    static let reader_Secondary = UIColor.secondaryLabel
    static let reader_Background = UIColor.systemBackground
    static let reader_Background2 = UIColor.secondarySystemBackground
#endif
}

extension ReaderTheme: Equatable {}

extension ReaderTheme: Codable {
    enum CodingKeys: String,CodingKey {
        case fontName, fontSize, isBold, lineHeight, additionalCSS
    }
    
    public init(from decoder: any Decoder) throws {
        foreground = .reader_Primary
        foreground2 = .reader_Secondary
        background = .reader_Background
        background2 = .reader_Background2
        link = .systemBlue
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fontName = try container.decode(String.self, forKey: .fontName)
        self.fontSize = try container.decode(Int.self, forKey: .fontSize)
        self.isBold = try container.decode(Bool.self, forKey: .isBold)
        self.lineHeight = try container.decode(CGFloat.self, forKey: .lineHeight)
        self.additionalCSS = try container.decodeIfPresent(String.self, forKey: .additionalCSS) ?? ""
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.fontName, forKey: .fontName)
        try container.encode(self.fontSize, forKey: .fontSize)
        try container.encode(self.isBold, forKey: .isBold)
        try container.encode(self.lineHeight, forKey: .lineHeight)
        try container.encodeIfPresent(self.additionalCSS, forKey: .additionalCSS)
    }
}

extension ReaderTheme: RawRepresentable {
    public init?(rawValue: String) {
        self = (try? JSONDecoder().decode(ReaderTheme.self, from: rawValue.data(using: .utf8) ?? Data())) ?? .init()
    }
    
    public var rawValue: String {
        let data = try? JSONEncoder().encode(self)
        return String(data: data ?? Data(), encoding: .utf8) ?? ""
    }
}


