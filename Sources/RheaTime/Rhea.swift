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
    static var tasks: [String: [RheaTask]] = [:]
    static let segmentName = "__DATA"
    static let sectionName = "__rheatime"

    @objc
    public static func rhea_load() {
        let start = Date()
        registerNotifications()
        readSectionDatas()
        
        NSLog("~~~~ \(Date().timeIntervalSince(start) * 1000)")
        callbackForTime("load")
    }
    
    @objc
    public static func rhea_premain() {
        callbackForTime("premain")
    }

    public static func trigger(event: RheaEvent) {
        callbackForTime(event.rawValue)
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
            callbackForTime("appFinishLaunching")
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
                    let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
                    return String(cString: ptr)
                }
                
                if segmentNamePtr == segmentName {
                    var sectionCursor = cursor
                    for _ in 0..<Int(segmentCmd.pointee.nsects) {
                        let sectionCmd = sectionCursor.bindMemory(to: section_64.self, capacity: 1)
                        sectionCursor = sectionCursor.advanced(by: MemoryLayout<section_64>.size)
                        
                        let sectionNamePtr = withUnsafeBytes(of: sectionCmd.pointee.sectname) { rawPtr -> String in
                            let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
                            return String(cString: ptr)
                        }
                        if sectionNamePtr == sectionName {
                            let sectionAddress = Int(sectionCmd.pointee.addr)
                            let sectionSize = Int(sectionCmd.pointee.size)
                            let sectionStart = slide + UnsafeRawPointer(bitPattern: sectionAddress)!
                            
                            var count = 0
                            let typeSize = MemoryLayout<RheaRegisterInfo>.size
                            let typeStride = MemoryLayout<RheaRegisterInfo>.stride
                            if sectionSize == typeSize {
                                count = 1
                            } else {
                                count = 1 + (sectionSize - typeSize) / typeStride
                            }
                            
                            if sectionSize > 0 {
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
                    }
                }
            }
            cursor = cursor.advanced(by: Int(segmentCmd.pointee.cmdsize) - MemoryLayout<segment_command_64>.size)
        }
    }
}
