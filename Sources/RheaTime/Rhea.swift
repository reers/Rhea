//
//  Rhea.swift
//  Rhea
//
//  Created by phoenix on 2022/8/13.
//

import Foundation
import UIKit
import MachO

@_used
@_section("__DATA,__mySection")
let my_global1: StaticString = "ss:11"

@objc
public class Rhea: NSObject {
    typealias Class = RheaDelegate
    static var classes: [Rhea.Class.Type] = []

    @objc
    public static func rhea_load() {
        guard let configable = self as? RheaConfigable.Type else {
            assertionFailure("Please extend `Rhea` to conform to `RheaConfigable`")
            return
        }
        #if DEBUG
        var wrongClassNames: [String] = []
        #endif
        for name in configable.classNames {
            guard let aClass = NSClassFromString(name) else {
                #if DEBUG
                wrongClassNames.append(name)
                #endif
                continue
            }
            guard let rheaClass = aClass as? RheaDelegate.Type else {
                assertionFailure("Please extend you class to conform to `RheaDelegate`")
                continue
            }
            classes.append(rheaClass)
            rheaClass.rheaLoad()
        }
        #if DEBUG
        if wrongClassNames.count > 0 {
            assertionFailure("Generate classes failed from: \(wrongClassNames)")
        }
        #endif
        registerNotifications()
        
        let start = UnsafeRawPointer(&rheaLoadHStart)
        let end = UnsafeRawPointer(&rheaLoadHEnd)
        let size = end - start
        print("~~~~ start \(start)")
        startPT = start
        var count = 0
        let typeSize = MemoryLayout<RheaFuncType>.size
        let typeStride = MemoryLayout<RheaFuncType>.stride
        if size == typeSize {
            count = 1
        } else {
            count = 1 + (size - typeSize) / typeStride
        }
        
        print("size: \(size)")
        if size > 0 {
            let function = start.bindMemory(to: RheaFuncType.self, capacity: count)
            let buffer = UnsafeBufferPointer(start: function, count: count)

            for function in buffer {
                function()
            }
        }
        
        let startReadSection = Date()
        readCustomSectionData()
        print("$$$$ \(Date().timeIntervalSince(startReadSection) * 1000)")
        
        
        
        
    }
    
    static var startPT: UnsafeRawPointer?
    
    @objc
    public static func rhea_premain() {
        classes.forEach { rheaClass in
            rheaClass.rheaPremain()
        }
    }

    public static func trigger(event: RheaEvent) {
        classes.forEach { rheaClass in
            rheaClass.rheaDidReceiveCustomEvent(event: event)
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

            let context = RheaContext(application: application, launchOptions: launchOptions)
            classes.forEach { rheaClass in
                rheaClass.rheaAppDidFinishLaunching(context: context)
            }
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
                    sectionName: "__psection",
                    baseAddress: baseAddress
                ) {
                    print("Section data from image \(i): \(sectionData)")
                }
            }
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
                            let typeSize = MemoryLayout<RheaStringAndFunc>.size
                            let typeStride = MemoryLayout<RheaStringAndFunc>.stride
                            if sectionSize == typeSize {
                                count = 1
                            } else {
                                count = 1 + (sectionSize - typeSize) / typeStride
                            }
                            
                            print("size: \(sectionSize)")
                            if sectionSize > 0 {
                                let function = start.bindMemory(to: RheaStringAndFunc.self, capacity: count)
                                let buffer = UnsafeBufferPointer(start: function, count: count)

                                for function in buffer {
//                                    function()
//                                    print(function)
                                    print(function.0)
                                    function.1()
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
