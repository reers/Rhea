//
//  RheaContext.swift
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

import Foundation


public class RheaContext: NSObject {
    public internal(set) var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    public internal(set) var param: Any?
    
    init(launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil, param: Any? = nil) {
        self.launchOptions = launchOptions
        self.param = param
    }
}
