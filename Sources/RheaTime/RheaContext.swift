//
//  RheaContext.swift
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Represents the context for function callbacks in the Rhea framework.
/// This class encapsulates information relevant to the application's launch
/// and any additional parameters passed during callback execution.
public class RheaContext: NSObject {
    #if canImport(UIKit)
    /// The launch options dictionary passed to the application upon its initialization.
    /// This property is set internally and can only be read externally.
    public internal(set) var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    #endif
    
    /// An optional parameter that can hold any additional data relevant to the callback.
    /// This property is set internally and can only be read externally.
    public internal(set) var param: Any?
    
    #if canImport(UIKit)
    /// Initializes a new instance of RheaContext.
    /// - Parameters:
    ///   - launchOptions: The launch options dictionary from the application's initialization.
    ///   - param: Any additional parameter to be included in the context.
    init(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil, param: Any? = nil) {
        self.launchOptions = launchOptions
        self.param = param
    }
    #else
    /// Initializes a new instance of RheaContext.
    /// - Parameters:
    ///   - param: Any additional parameter to be included in the context.
    init(param: Any? = nil) {
        self.param = param
    }
    #endif
}
