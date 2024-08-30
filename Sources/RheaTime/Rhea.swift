//
//  Rhea.swift
//  Rhea
//
//  Created by phoenix on 2022/8/13.
//

import Foundation
import UIKit
import MachO

struct RheaTask {
    let name: String
    let priority: Int
    let repeatable: Bool
    let function: @convention(c) (RheaContext) -> Void
}

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
    
    static var tasks: [String: [RheaTask]] = [:]
    static let segmentName = "__DATA"
    static let sectionName = "__rheatime"

    @objc
    static func rhea_load() {
        let start = Date()
        registerNotifications()
        NSLog("~~~~ registerNoti \(Date().timeIntervalSince(start) * 1000)")
        readSectionDatas()
        
        NSLog("~~~~ \(Date().timeIntervalSince(start) * 1000)")
        callbackForTime("load")
    }
    
    @objc
    static func rhea_premain() {
        callbackForTime("premain")
    }
    
    private static func callbackForTime(_ time: String, context: RheaContext = .init()) {
        let start = Date()
        guard let rheaTasks = tasks[time] else { return }
        var repeatableTasks: [RheaTask] = []
        rheaTasks
            .sorted { $0.priority > $1.priority }
            .forEach {
                $0.function(context)
                if $0.repeatable {
                    repeatableTasks.append($0)
                }
            }
        if repeatableTasks.isEmpty {
            tasks[time] = nil
        } else {
            tasks[time] = repeatableTasks
        }
        NSLog("~~~~ callback \(time) \(Date().timeIntervalSince(start) * 1000)")
    }
    
    private static func readSectionDatas() {
        let imageCount = _dyld_image_count()

        for i in 0..<imageCount {
            let imageName = String(cString: _dyld_get_image_name(i))
            guard imageName.hasPrefix(Bundle.main.bundlePath) else { continue }
            guard let machHeader = _dyld_get_image_header(i) else { continue }
            let slide = _dyld_get_image_vmaddr_slide(i)
            readSectionData(header: machHeader, segmentName: segmentName, sectionName: sectionName, slide: slide)
        }
    }

    private static func registerNotifications() {
       NotificationCenter.default.addObserver(
            forName: UIApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { notification in
            let application = notification.object as? UIApplication ?? UIApplication.shared
            let launchOptions = notification.userInfo as? [UIApplication.LaunchOptionsKey: Any]

            let context = RheaContext(launchOptions: launchOptions)
            callbackForTime("appDidFinishLaunching", context: context)
        }
    }
    
    static func sortTasksByPriority() {
        for (event, taskArray) in tasks {
            let sortedTasks = taskArray.sorted { $0.priority > $1.priority }
            tasks[event] = sortedTasks
        }
    }
    
    static func readSectionData(
        header: UnsafePointer<mach_header>,
        segmentName: String,
        sectionName: String,
        slide: Int
    ) {
        var cursor = UnsafeRawPointer(header).advanced(by: MemoryLayout<mach_header_64>.size)
        for _ in 0..<header.pointee.ncmds {
            let segmentCmd = cursor.bindMemory(to: segment_command_64.self, capacity: 1)
            cursor = cursor.advanced(by: MemoryLayout<segment_command_64>.size)
            
            if segmentCmd.pointee.cmd == LC_SEGMENT_64 {
                let segmentNamePtr = withUnsafeBytes(of: segmentCmd.pointee.segname) { rawPtr -> String in
                    guard let address = rawPtr.baseAddress else { return "" }
                    let ptr = address.assumingMemoryBound(to: CChar.self)
                    return String(cString: ptr)
                }
                
                if segmentNamePtr == segmentName {
                    var sectionCursor = cursor
                    for _ in 0..<Int(segmentCmd.pointee.nsects) {
                        let sectionCmd = sectionCursor.bindMemory(to: section_64.self, capacity: 1)
                        sectionCursor = sectionCursor.advanced(by: MemoryLayout<section_64>.size)
                        
                        let sectionNamePtr = withUnsafeBytes(of: sectionCmd.pointee.sectname) { rawPtr -> String in
                            guard let address = rawPtr.baseAddress else { return "" }
                            let ptr = address.assumingMemoryBound(to: CChar.self)
                            return String(cString: ptr)
                        }
                        if sectionNamePtr == sectionName {
                            let sectionAddress = Int(sectionCmd.pointee.addr)
                            let sectionSize = Int(sectionCmd.pointee.size)
                            guard let sectionPointer = UnsafeRawPointer(bitPattern: sectionAddress) else {
                                continue
                            }
                            let sectionStart = slide + sectionPointer
                            
                            readRegisterInfo(from: sectionStart, sectionSize: sectionSize)
                        }
                    }
                }
            }
            cursor = cursor.advanced(by: Int(segmentCmd.pointee.cmdsize) - MemoryLayout<segment_command_64>.size)
        }
    }
    
    static func readRegisterInfo(from sectionStart: UnsafeRawPointer, sectionSize: Int) {
        guard sectionSize > 0 else { return }
        
        let typeSize = MemoryLayout<RheaRegisterInfo>.size
        let typeStride = MemoryLayout<RheaRegisterInfo>.stride
        let count =
            if sectionSize == typeSize { 1 }
            else {
                1 + (sectionSize - typeSize) / typeStride
            }
        
        let registerInfoPtr = sectionStart.bindMemory(to: RheaRegisterInfo.self, capacity: count)
        let buffer = UnsafeBufferPointer(start: registerInfoPtr, count: count)
        
        for info in buffer {
            let string = info.0
            let function = info.1
            
            let parts = string.description.components(separatedBy: ".")
            if parts.count == 4 {
                let timeName = parts[1]
                let priority = Int(parts[2]) ?? 5
                let repeatable = Bool(parts[3]) ?? false
                let task = RheaTask(name: timeName, priority: priority, repeatable: repeatable, function: function)
                var existingTasks = tasks[timeName] ?? []
                existingTasks.append(task)
                tasks[timeName] = existingTasks
            } else {
                assert(false, "Register info string should have 4 parts")
            }
        }
    }
}
