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

/// A function type representing callback with no parameters in Rhea framework.
///
/// - Important: This is a transitional definition that will be automatically
///   replaced by `RheaFunction` during macro expansion. 
public typealias RheaParameterlessFunction = @convention(c) () -> Void

/// Represents the registration information stored in the `__DATA,__rheatime` section.
/// Fields: (eventHash, priority, repeatable, isAsync, function)
/// - eventHash: FNV-1a 64-bit hash of the event name string.
/// - priority: Execution priority (higher values execute first).
/// - repeatable: Whether the callback survives after first trigger.
/// - isAsync: Whether the callback runs on a background queue.
/// - function: The callback to execute.
public typealias RheaRegisterInfo = (UInt64, Int, Bool, Bool, RheaFunction)

/// FNV-1a 64-bit hash used to encode event names into a fixed-size integer.
/// Identical implementations exist in both the macro plugin (compile-time)
/// and the runtime (trigger-time) to ensure hash consistency.
public func rheaFNV1aHash(_ string: String) -> UInt64 {
    var hash: UInt64 = 0xcbf29ce484222325
    for byte in string.utf8 {
        hash ^= UInt64(byte)
        hash &*= 0x100000001b3
    }
    return hash
}

/// Represents a task to be executed by the Rhea framework.
internal struct RheaTask {
    /// FNV-1a hash of the event name.
    let eventHash: UInt64
    /// The priority of the task. Higher priority tasks are executed first.
    let priority: Int
    /// Indicates whether the task can be executed multiple times.
    let repeatable: Bool
    /// Indicates whether the task can be executed asynchronously.
    let isAsync: Bool
    /// The function to be executed when the task is triggered.
    let function: @convention(c) (RheaContext) -> Void
}
