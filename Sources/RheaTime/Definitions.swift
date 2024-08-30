//
//  Definitions.swift
//  RheaTime
//
//  Created by phoenix on 2024/6/19.
//

/// Represents a callback function type used in the Rhea framework.
/// - Parameter context: A `RheaContext` object containing relevant information for the callback.
/// - Returns: Void
/// - Note: This function type uses C calling convention for compatibility.
public typealias RheaFunction = @convention(c) (RheaContext) -> Void

/// Represents the registration information for a Rhea function.
/// - Note: The `StaticString` follows the format: "prefix.rheaTimeName.priority.isRepeatable"
///   - prefix: The namespace or module identifier.
///   - rheaTimeName: The specific timing or event name.
///   - priority: An integer indicating the execution priority.
///   - isRepeatable: A boolean flag ('true' or 'false') indicating if the function can be called multiple times.
/// - Example: "rhea.load.5.true"
public typealias RheaRegisterInfo = (StaticString, RheaFunction)
