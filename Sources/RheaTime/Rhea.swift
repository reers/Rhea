//
//  Rhea.swift
//  Rhea
//
//  Created by phoenix on 2022/8/13.
//

import Foundation
import SectionReader
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

/// Rhea: A dynamic event-driven framework for iOS application lifecycle management and app-wide decoupling.
///
/// The Rhea framework provides a flexible and efficient way to manage the execution of code
/// at specific points in an iOS application's lifecycle and for custom events. It allows developers
/// to register callbacks for predefined lifecycle events or custom events, with fine-grained control
/// over execution priority and repeatability. This approach significantly helps in decoupling
/// different parts of the application, promoting a more modular and maintainable codebase.
///
/// Key features:
/// - Custom event registration: Define and trigger custom events in your application.
/// - Lifecycle event hooks: Easily attach callbacks to iOS app lifecycle events.
/// - Priority-based execution: Control the order of callback execution with customizable priorities.
/// - One-time or repeatable callbacks: Choose whether callbacks should execute once or multiple times.
/// - Macro-based registration: Use the `#rhea` macro for clean and concise callback registration.
/// - External event triggering: Trigger events programmatically from anywhere in your app.
/// - App-wide decoupling: Facilitate better separation of concerns and reduce dependencies between modules.
///
/// Rhea is designed to improve code organization, reduce coupling between components,
/// and provide a more declarative approach to handling app lifecycle and custom events.
///
/// Usage examples:
/// ```swift
/// // Registering a callback for a predefined lifecycle event
/// #rhea(time: .premain, func: { _ in
///     print("~~~~ premain")
/// })
///
/// // Defining a custom event
/// extension RheaEvent {
///     static let customEvent: RheaEvent = "customEvent"
/// }
///
/// // Registering a callback for a custom event
/// #rhea(time: .customEvent, priority: .normal, repeatable: true, func: { context in
///     // Code to run when user triggered "customEvent": `Rhea.trigger(event: .customEvent)`
/// })
/// ```
///
/// The `Rhea` class serves as the central point for event management and framework functionality,
/// enabling effective decoupling and modular design across the entire application.
@objc
public class Rhea: NSObject {
    
    /// Triggers a specific Rhea event and executes all registered callbacks for that event.
    ///
    /// This method activates all callbacks registered for the given event, passing them
    /// a context that includes any provided parameter.
    ///
    /// - Parameters:
    ///   - event: The `RheaEvent` to trigger. This identifies which set of callbacks should be executed.
    ///   - param: An optional parameter of type `Any?` that will be passed to the callbacks via the `RheaContext`.
    ///            This can be used to provide additional data to the callbacks. Defaults to `nil`.
    ///
    /// - Note:
    ///   - The method creates a new `RheaContext` for each trigger call.
    ///   - If a parameter is provided, it will be accessible in the callbacks through `context.param`.
    ///   - The `launchOptions` in the `RheaContext` will be `nil` for triggered events.
    ///   - Callbacks are executed in the order determined by their priority set during registration.
    ///
    /// - Important:
    ///   - Ensure that callbacks are prepared to handle a potentially `nil` parameter.
    ///   - Be mindful of the performance impact when triggering events with many registered callbacks.
    ///   - In callbacks, consider performance implications. For time-consuming operations,
    ///     use asynchronous processing or dispatch to background queues when appropriate.
    ///   - Avoid blocking the main thread in callbacks, especially for UI-related events.
    ///
    public static func trigger(event: RheaEvent, param: Any? = nil) {
        let context = RheaContext()
        context.param = param
        callbackForTime(event.rawValue, context: context)
    }
    
    nonisolated(unsafe) private static let lock: os_unfair_lock_t = {
        let lock = os_unfair_lock_t.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock())
        return lock
    }()
    
    nonisolated(unsafe) private static var tasks: [String: [RheaTask]] = [:]
    private static let segmentName = "__DATA"
    private static let sectionName = "__rheatime"

    @objc
    static func rhea_load() {
        registerNotifications()
        readSectionDatas()
        
        callbackForTime(RheaEvent.load.rawValue)
    }
    
    @objc
    static func rhea_premain() {
        callbackForTime(RheaEvent.premain.rawValue)
    }
    
    private static func callbackForTime(_ time: String, context: RheaContext = .init()) {
        os_unfair_lock_lock(lock)
        guard let rheaTasks = tasks[time] else {
            os_unfair_lock_unlock(lock)
            return
        }
        os_unfair_lock_unlock(lock)
        
        var repeatableTasks: [RheaTask] = []
        rheaTasks
            .sorted { $0.priority > $1.priority }
            .forEach {
                dispatchTask($0, context: context)
                if $0.repeatable {
                    repeatableTasks.append($0)
                }
            }
        
        os_unfair_lock_lock(lock)
        if repeatableTasks.isEmpty {
            tasks[time] = nil
        } else {
            tasks[time] = repeatableTasks
        }
        os_unfair_lock_unlock(lock)
    }
    
    private static func readSectionDatas() {
        let rheaTimes = SectionReader.read(RheaRegisterInfo.self, segment: segmentName, section: sectionName)
        os_unfair_lock_lock(lock)
        for info in rheaTimes {
            let string = info.0
            let function = info.1
            
            let parts = string.description.components(separatedBy: CharacterSet(charactersIn: "."))
            if parts.count == 5 {
                let timeName = parts[1]
                let priority = Int(parts[2]) ?? 5
                let repeatable = Bool(parts[3]) ?? false
                let isAsync = Bool(parts[4]) ?? false
                let task = RheaTask(name: timeName, priority: priority, repeatable: repeatable, isAsync: isAsync, function: function)
                var existingTasks = tasks[timeName] ?? []
                existingTasks.append(task)
                tasks[timeName] = existingTasks
            } else {
                assert(false, "Register info string should have 5 parts")
            }
        }
        os_unfair_lock_unlock(lock)
    }

    private static func registerNotifications() {
        #if canImport(UIKit) && !os(watchOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { notification in
            let launchOptions = notification.userInfo as? [UIApplication.LaunchOptionsKey: Any]
            
            let context = RheaContext(launchOptions: launchOptions)
            callbackForTime(RheaEvent.appDidFinishLaunching.rawValue, context: context)
        }
        #endif
        
        #if canImport(AppKit)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { notification in
            let userInfo = notification.userInfo
            let context = RheaContext(param: userInfo)
            callbackForTime(RheaEvent.appDidFinishLaunching.rawValue, context: context)
        }
        #endif
        
        #if canImport(WatchKit)
        NotificationCenter.default.addObserver(
            forName: WKApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { _ in
            let context = RheaContext()
            callbackForTime(RheaEvent.appDidFinishLaunching.rawValue, context: context)
        }
        #endif
    }
}

// MARK: - Dispatch task

extension Rhea {
    private static let veryHighPriorityQueue = DispatchQueue(
        label: "com.rhea.veryHighPriorityQueue",
        qos: .userInteractive,
        attributes: .concurrent
    )
    private static let highPriorityQueue = DispatchQueue(
        label: "com.rhea.highPriorityQueue",
        qos: .userInitiated,
        attributes: .concurrent
    )
    private static let defaultPriorityQueue = DispatchQueue(
        label: "com.rhea.defaultPriorityQueue",
        qos: .default,
        attributes: .concurrent
    )
    private static let lowPriorityQueue = DispatchQueue(
        label: "com.rhea.lowPriorityQueue",
        qos: .utility,
        attributes: .concurrent
    )
    private static let veryLowPriorityQueue = DispatchQueue(
        label: "com.rhea.veryLowPriorityQueue",
        qos: .background,
        attributes: .concurrent
    )
    
    private static func dispatchTask(_ task: RheaTask, context: RheaContext) {
        if task.isAsync {
            let queue: DispatchQueue
            switch task.priority {
            case RheaPriority.veryHigh.rawValue...:
                queue = veryHighPriorityQueue
            case RheaPriority.high.rawValue..<RheaPriority.veryHigh.rawValue:
                queue = highPriorityQueue
            case RheaPriority.veryLow.rawValue..<RheaPriority.low.rawValue:
                queue = lowPriorityQueue
            case ..<RheaPriority.veryLow.rawValue:
                queue = veryLowPriorityQueue
            default:
                queue = defaultPriorityQueue
            }
            
            queue.async {
                task.function(context)
            }
        } else {
            task.function(context)
        }
    }
}
