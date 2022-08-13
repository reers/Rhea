//
//  Rhea.swift
//  Rhea
//
//  Created by phoenix on 2022/8/13.
//

import Foundation
import ObjectiveC

public class Rhea: NSObject {
    
    @objc
    public class func loadClass() {
        var methodCount: UInt32 = 0
        guard let methodList = class_copyMethodList(Self.self, &methodCount) else { return }
        
        for i in 0..<Int(methodCount) {
            let method = methodList[i]
            let methodName = NSStringFromSelector(method_getName(method))
//            let methodName = String(utf8String: .description)
            print(methodName)
        }
        free(methodList)
    }
    
    @objc
    public func ccc() {
        
    }
}
