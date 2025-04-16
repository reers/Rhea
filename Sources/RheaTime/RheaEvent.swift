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
///
public struct RheaEvent: ExpressibleByStringLiteral, Equatable, Hashable, RawRepresentable, Sendable {
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

/// Extension to `RheaEvent` providing predefined event timings used by the Rhea framework.
/// These events are automatically triggered by the framework and do not require manual invocation.
extension RheaEvent {
    /// Represents the timing equivalent to Objective-C's `+load` method.
    /// Automatically triggered by the framework; no need to call `Rhea.trigger(event: .load)`.
    ///
    /// - Warning: Usage of this timing is **strongly discouraged**.
    /// - Note: ⚠️⚠️⚠️ This event occurs very early in the app's lifecycle, before even `main()` is called.
    ///         The primary reason for discouraging its use is that any code executed during this phase
    ///         **blocks the entire application and framework loading process**, potentially leading to
    ///         **significantly increased launch times**. Furthermore, it runs in a **limited runtime
    ///         environment** where not all classes may be loaded, leading to **fragile dependency
    ///         management** and making debugging difficult. Consider using `.premain` or
    ///         `.appDidFinishLaunching` for safer and more predictable initialization.
    public static let load: RheaEvent = "load"
    
    /// Represents the timing of functions decorated with `__attribute__((constructor))`.
    ///
    /// - Note: This event occurs after `load` but still before `main()`.
    ///         It's useful for early initialization that doesn't depend on the full runtime environment.
    ///         Automatically triggered by the framework; no need to call `Rhea.trigger(event: .premain)`.
    public static let premain: RheaEvent = "premain"
    
    /// Represents the timing when the app has finished launching.
    ///
    /// - Note: This corresponds to `application(_:didFinishLaunchingWithOptions:)` in UIKit,
    ///         and `applicationDidFinishLaunching(_:)` in AppKit.
    ///         It's a safe point to perform most app initializations.
    ///         Automatically triggered by the framework; no need to call `Rhea.trigger(event: .appDidFinishLaunching)`.
    public static let appDidFinishLaunching: RheaEvent = "appDidFinishLaunching"
}
