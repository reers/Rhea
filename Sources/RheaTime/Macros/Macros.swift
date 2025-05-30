//
//  Macros.swift
//
//
//  Created by phoenix on 2024/8/21.
//

/// Registers a callback function for a specific Rhea event.
///
/// This macro is used to register a callback function to a section in the binary,
/// associating it with a specific event time, priority, and repeatability.
///
/// - Parameters:
///   - time: A `RheaEvent` representing the timing or event name for the callback.
///           This parameter also supports direct string input, which will be
///           processed by the framework as an event identifier.
///   - priority: A `RheaPriority` value indicating the execution priority of the callback.
///               Default is `.normal`. Predefined values include `.veryLow`, `.low`,
///               `.normal`, `.high`, and `.veryHigh`. Custom integer priorities are also
///               supported. Callbacks for the same event are sorted and executed based
///               on this priority.
///   - repeatable: A boolean flag indicating whether the callback can be triggered multiple times.
///                 If `false` (default), the callback will only be executed once.
///                 If `true`, the callback can be re-triggered on subsequent event occurrences.
///   - async: A boolean flag indicating whether the callback should be executed asynchronously.
///            If `false` (default), the callback will be executed on the main thread.
///            If `true`, the callback will be executed on a background thread. Note that when
///            `async` is `true`, the execution order based on `priority` may not be guaranteed.
///            Even when `async` is set to `false`, users can still choose to dispatch their tasks
///            to a background queue within the callback function if needed. This provides
///            flexibility for handling both quick, main thread operations and longer-running
///            background tasks.
///   - func: The callback function of type `RheaFunction`. This function receives a `RheaContext`
///           parameter, which includes `launchOptions` and an optional `Any?` parameter.
///
/// - Note: When triggering an event externally using `Rhea.trigger(event:param:)`, you can include
///         an additional parameter that will be passed to the callback via the `RheaContext`.
///
/// ```swift
/// #rhea(time: .load, priority: .veryLow, repeatable: true, func: { _ in
///     print("~~~~ load in Account Module")
/// })
///
/// #rhea(time: .registerRoute, func: { _ in
///     print("~~~~ registerRoute in Account Module")
/// })
///
/// // Use a StaticString as event directly
/// #rhea(time: "ACustomEventString", func: { _ in
///     print("~~~~ custom event")
/// })
///
/// // Example of using async execution
/// #rhea(time: .load, async: true, func: { _ in
///     // This will run on a background thread
///     performHeavyTask()
/// })
///
/// // Example of manually dispatching to background queue when async is false
/// #rhea(time: .load, func: { _ in
///     DispatchQueue.global().async {
///         // Perform background task
///     }
/// })
/// ```
/// - Note: ⚠️⚠️⚠️ When extending ``RheaEvent`` with static constants, ensure that
///   the constant name exactly matches the string literal value. This practice
///   maintains consistency and prevents confusion.
///
@freestanding(declaration)
public macro rhea(
    time: RheaEvent,
    priority: RheaPriority = .normal,
    repeatable: Bool = false,
    async: Bool = false,
    func: RheaFunction
) = #externalMacro(module: "RheaTimeMacros", type: "WriteTimeToSectionMacro")

/// Registers a callback function for the `.load` event timing.
///
/// This is a convenience wrapper macro for `#rhea` that specifically handles the `.load` event timing.
/// The callback will be executed during the module load phase with default settings:
/// - priority: `.normal`
/// - repeatable: `false`
/// - async: `false`
///
/// ```swift
/// #load {
///     print("Module loaded")
/// }
/// ```
///
/// - Parameter func: A parameterless callback function to be executed during module load.
///
/// - Warning: Usage of this timing is **strongly discouraged**.
/// - Note: ⚠️⚠️⚠️ This event occurs very early in the app's lifecycle, before even `main()` is called.
///         The primary reason for discouraging its use is that any code executed during this phase
///         **blocks the entire application and framework loading process**, potentially leading to
///         **significantly increased launch times**. Furthermore, it runs in a **limited runtime
///         environment** where not all classes may be loaded, leading to **fragile dependency
///         management** and making debugging difficult. Consider using `.premain` or
///         `.appDidFinishLaunching` for safer and more predictable initialization.
@freestanding(declaration)
public macro load(
    func: RheaParameterlessFunction
) = #externalMacro(module: "RheaTimeMacros", type: "RheaLoad")

/// Registers a callback function for the `.premain` event timing.
///
/// This is a convenience wrapper macro for `#rhea` that specifically handles the `.premain` event timing.
/// The callback will be executed before the main function with default settings:
/// - priority: `.normal`
/// - repeatable: `false`
/// - async: `false`
///
/// ```swift
/// #premain {
///     print("Before main function")
/// }
/// ```
///
/// - Parameter func: A parameterless callback function to be executed before main.
@freestanding(declaration)
public macro premain(
    func: RheaParameterlessFunction
) = #externalMacro(module: "RheaTimeMacros", type: "RheaPremain")

/// Registers a callback function for the `.appDidFinishLaunching` event timing.
///
/// This is a convenience wrapper macro for `#rhea` that specifically handles the `.appDidFinishLaunching` event timing.
/// The callback will be executed when the application finishes launching with default settings:
/// - priority: `.normal`
/// - repeatable: `false`
/// - async: `false`
///
/// Note: This macro provides a simplified interface for cases where `launchOptions` are not needed.
/// If you need access to `launchOptions` or other context parameters, use the full `#rhea` macro instead:
/// ```swift
/// // With launch options
/// #rhea(time: .appDidFinishLaunching) { context in
///     if let options = context.launchOptions {
///         // Handle launch options
///     }
/// }
///
/// // Without launch options (simplified)
/// #appDidFinishLaunching {
///     print("App did finish launching")
/// }
/// ```
///
/// - Parameter func: A parameterless callback function to be executed when the app finishes launching.
@freestanding(declaration)
public macro appDidFinishLaunching(
    func: RheaParameterlessFunction
) = #externalMacro(module: "RheaTimeMacros", type: "RheaAppDidFinishLaunching")
