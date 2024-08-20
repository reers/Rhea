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
    static let sectionName = "__rheatime"
    
    static let loadImageFunc: @convention(c) (UnsafePointer<mach_header>?, Int) -> Void = { mh, slide in
        var info = Dl_info()
        if dladdr(UnsafeRawPointer(mh), &info) == 0 {
            return
        }
        guard let machHeader = mh else { return }
        
//        DispatchQueue.main.async {
//            readSection(header: machHeader, segmentName: "__DATA", sectionName: sectionName, slide: slide)
        getSectionData(header: machHeader, segmentName: "__DATA", sectionName: sectionName, baseAddress: slide)
//        }
    }

    @objc
    public static func rhea_load() {
        registerNotifications()
        _dyld_register_func_for_add_image(loadImageFunc)
    }
    
    @objc
    public static func rhea_premain() {
        guard let rheaTasks = tasks["premain"] else { return }
        rheaTasks
            .sorted { $0.priority > $1.priority }
            .forEach { $0.function(.init()) }
    }

    public static func trigger(event: RheaEvent) {
//        classes.forEach { rheaClass in
//            rheaClass.rheaDidReceiveCustomEvent(event: event)
//        }
    }
    
    
//    private static func load_image(machHeader: UnsafePointer<mach_header>?, slide: Int) {
//        var info = Dl_info()
//        if dladdr(mh, &info) == 0 {
//            return
//        }
//        
//        print("~~~~ image: \(String(describing: mh))")
//        DispatchQueue.main.async {
//            readSectionDatas()
//        }
//    }

    
    private static func readSectionDatas() {
        
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
            guard let rheaTasks = tasks["appFinishLaunching"] else { return }
            rheaTasks
                .sorted { $0.priority > $1.priority }
                .forEach { $0.function(context) }
        }
    }
    
    
    static func sortTasksByPriority() {
        for (event, taskArray) in tasks {
            let sortedTasks = taskArray.sorted { $0.priority > $1.priority }
            tasks[event] = sortedTasks
        }
    }
    
    static func readCustomSectionData() {
        // 获取当前进程的所有加载镜像数量
        let imageCount = _dyld_image_count()

        for i in 0..<imageCount {
            // 获取每个镜像的头部信息
            let imageName = String(cString: _dyld_get_image_name(i))
            
//            print("#### bundle \(Bundle.main.bundlePath)")
            if !imageName.hasPrefix(Bundle.main.bundlePath) {
                continue
            }
            
            print("#### image name: \(imageName)")
//            if imageName.hasSuffix("Rhea_Example") {
//                continue
//            }
            let baseAddress = _dyld_get_image_vmaddr_slide(i)
            if let header = _dyld_get_image_header(i) {
                if let sectionData = getSectionData(
                    header: header,
                    segmentName: "__DATA",
                    sectionName: "__rheatime",
                    baseAddress: baseAddress
                ) {
                    print("Section data from image \(i): \(sectionData)")
                }
            }
        }
    }
    
    static func readSection(
        header: UnsafePointer<mach_header>,
        segmentName: String,
        sectionName: String,
        slide: Int
    ) {
        var cursor = UnsafeRawPointer(header).advanced(by: MemoryLayout<mach_header_64>.size)
        for _ in 0..<header.pointee.ncmds {
            let segmentCmd = cursor.bindMemory(to: segment_command_64.self, capacity: 1)
            cursor = cursor.advanced(by: MemoryLayout<segment_command_64>.size)
            
            guard segmentCmd.pointee.cmd == LC_SEGMENT_64 else { continue }
            
            let segmentNamePtr = withUnsafeBytes(of: segmentCmd.pointee.segname) { rawPtr -> String in
                let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
                return String(cString: ptr)
            }
            
            guard segmentNamePtr == segmentName else { continue }
            
            var sectionCursor = cursor
            for _ in 0..<Int(segmentCmd.pointee.nsects) {
                let sectionCmd = sectionCursor.bindMemory(to: section_64.self, capacity: 1)
                sectionCursor = sectionCursor.advanced(by: MemoryLayout<section_64>.size)
                
                let sectionNamePtr = withUnsafeBytes(of: sectionCmd.pointee.sectname) { rawPtr -> String in
                    let ptr = rawPtr.baseAddress!.assumingMemoryBound(to: CChar.self)
                    return String(cString: ptr)
                }
                print("~~~~ section name: \(sectionNamePtr)")
                
                guard sectionNamePtr == sectionName else { continue }
                
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
                
                print("size: \(sectionSize)")
                
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
            cursor = cursor.advanced(by: Int(segmentCmd.pointee.cmdsize) - MemoryLayout<segment_command_64>.size)
        }
    }

    static func getSectionData(header: UnsafePointer<mach_header>, segmentName: String, sectionName: String, baseAddress: Int) -> String? {
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
                        print("~~~~ section name: \(sectionNamePtr)")
                        if sectionNamePtr == sectionName {
                            
                            
//                            let sectionAddress = sectionCmd.pointee.addr
//                            let sectionSize = sectionCmd.pointee.size
//                            let rawPointer = UnsafeRawPointer(bitPattern: UInt(sectionAddress))
//                            if let data = rawPointer {
//                                let rheaFuncArray = getRheaFuncTypeArray(from: data, sectionSize: 16) // 使用 16 字节的大小
//                                // 现在 rheaFuncArray 包含了所有的 RheaFuncType 函数指针
//                                
//                                // 调用每个函数指针
//                                for rheaFunc in rheaFuncArray {
//                                    rheaFunc()
//                                }
//                            }
                            
                            
                            var sectionAddress = Int(sectionCmd.pointee.addr)
                            var sectionSize = Int(sectionCmd.pointee.size)
                            
                            let start = baseAddress + UnsafeRawPointer(bitPattern: sectionAddress)!
//                            let start = baseAddress + UnsafeRawPointer(pt)
//                            let start = startPT!
                            
                            print("~~~~ start2 \(start)")
                            
//                            let start = UnsafeRawPointer(bitPattern: UInt(sectionAddress))!
                            
                            var count = 0
                            let typeSize = MemoryLayout<RheaRegisterInfo>.size
                            let typeStride = MemoryLayout<RheaRegisterInfo>.stride
                            if sectionSize == typeSize {
                                count = 1
                            } else {
                                count = 1 + (sectionSize - typeSize) / typeStride
                            }
                            
                            print("size: \(sectionSize)")
                            if sectionSize > 0 {
                                let function = start.bindMemory(to: RheaRegisterInfo.self, capacity: count)
                                let buffer = UnsafeBufferPointer(start: function, count: count)

                                for function in buffer {
//                                    function()
//                                    print(function)
                                    print(function.0);
                                    
                                    let context = RheaContext()
                                    context.param = 33333
                                    function.1(context);
                                }
                            }
                            
//                            let data = UnsafeRawPointer(bitPattern: UInt(sectionAddress))
//                            if let data = data {
//                                // let buffer = UnsafeBufferPointer(start: data.assumingMemoryBound(to: UInt8.self), count: Int(sectionSize))
//                                // return String(bytes: buffer, encoding: .utf8)
//                                
//                                var result: [RheaFuncType] = []
//                                
//                                // 计算闭包的大小
//                                let closureSize = MemoryLayout<RheaFuncType>.size
//                                
//                                // 遍历内存区域，读取每个闭包
//                                for offset in stride(from: 0, to: Int(sectionSize), by: closureSize) {
//                                    let pointer = sectionAddress.advanced(by: offset)
//                                    result.append(pointer.pointee)
//                                }
//                                return nil
//                            }
                        }
                    }
                }
            }
            
            cursor = cursor.advanced(by: Int(segmentCmd.pointee.cmdsize) - MemoryLayout<segment_command_64>.size)
        }
        return nil
    }
    
//    static func getRheaFuncTypeArray(from sectionAddress: UnsafeRawPointer, sectionSize: Int) -> [RheaFuncType] {
//        var result: [RheaFuncType] = []
//        
//        // 计算指针的大小
//        let pointerSize = MemoryLayout<RheaFuncType>.size
//        
//        // 遍历内存区域，读取每个函数指针
//        for offset in stride(from: 0, to: sectionSize, by: pointerSize) {
//            let pointer = sectionAddress.advanced(by: offset).assumingMemoryBound(to: RheaFuncType.self)
//            result.append(pointer.pointee)
//        }
//        
//        return result
//    }
}
