//
//  RheaPriority.swift
//
//
//  Created by phoenix on 2024/8/31.
//

import Foundation

/// Represents the priority of a Rhea task.
///
/// This struct allows for both predefined priority levels and custom integer-based priorities.
/// It conforms to ExpressibleByIntegerLiteral, allowing direct use of integer values for priorities.
public struct RheaPriority: ExpressibleByIntegerLiteral, Equatable, Hashable, RawRepresentable {
    public typealias IntegerLiteral = Int
    public init(integerLiteral value: Int) {
        self.rawValue = value
    }
    
    public private(set) var rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension RheaPriority {
    /// Callback function receive very low priority for execution.
    public static let veryLow: RheaPriority = 1
    /// Callback function receive low priority for execution.
    public static let low: RheaPriority = 3
    /// Callback function receive the normal priority for execution.
    public static let normal: RheaPriority = 5
    /// Callback function receive high priority for execution.
    public static let high: RheaPriority = 7
    /// Callback function receive very high priority for execution.
    public static let veryHigh: RheaPriority = 9
}

