//
//  RheaContext.swift
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

import Foundation
import UIKit

/// Represents the context for function callbacks in the Rhea framework.
/// This class encapsulates information relevant to the application's launch
/// and any additional parameters passed during callback execution.
public class RheaContext: NSObject {
    /// The launch options dictionary passed to the application upon its initialization.
    /// This property is set internally and can only be read externally.
    public internal(set) var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    
    /// An optional parameter that can hold any additional data relevant to the callback.
    /// This property is set internally and can only be read externally.
    public internal(set) var param: Any?
    
    /// Initializes a new instance of RheaContext.
    /// - Parameters:
    ///   - launchOptions: The launch options dictionary from the application's initialization.
    ///   - param: Any additional parameter to be included in the context.
    init(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil, param: Any? = nil) {
        self.launchOptions = launchOptions
        self.param = param
    }
}
