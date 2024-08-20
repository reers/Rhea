//
//  RheaEvent.swift
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

public struct RheaEvent: ExpressibleByStringLiteral, Equatable, Hashable, RawRepresentable {
    public typealias StringLiteralType = String

    public private(set) var rawValue: String

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
