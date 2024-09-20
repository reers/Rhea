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
/// - Note: The `StaticString` follows the format:
///  "prefix.rheaTimeName.priority.isRepeatable.isAsync"
///   - prefix: The namespace or module identifier.
///   - rheaTimeName: The specific timing or event name.
///   - priority: An integer indicating the execution priority.
///   - isRepeatable: A boolean flag ('true' or 'false') indicating if the function can be called multiple times.
///   - isAsync: A boolean flag ('true' or 'false') indicating if the function can be called asynchronously.
/// - Example: "rhea.load.5.true.false"
public typealias RheaRegisterInfo = (StaticString, RheaFunction)


/// Represents a task to be executed by the Rhea framework.
internal struct RheaTask {
    /// The name of the task, typically corresponding to a specific event.
    let name: String
    /// The priority of the task. Higher priority tasks are executed first.
    let priority: Int
    /// Indicates whether the task can be executed multiple times.
    let repeatable: Bool
    /// Indicates whether the task can be executed asynchronously.
    let isAsync: Bool
    /// The function to be executed when the task is triggered.
    let function: @convention(c) (RheaContext) -> Void
}
