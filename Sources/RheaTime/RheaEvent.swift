//
//  RheaEvent.swift
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

/// Represents a type-safe event identifier in the Rhea framework.
/// This struct is designed to prevent hard-coded string usage for event names,
/// providing compile-time safety and better code organization.
/// 
/// ```
/// extension RheaEvent {
///     static let appDidFinishLaunching: RheaEvent = "appDidFinishLaunching"
/// }
/// ```
/// - Note: ⚠️⚠️⚠️ When extending this struct with static constants, ensure that
///   the constant name exactly matches the string literal value. This practice
///   maintains consistency and prevents confusion.
public struct RheaEvent: ExpressibleByStringLiteral, Equatable, Hashable, RawRepresentable {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    public private(set) var rawValue: String
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
