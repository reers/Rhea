//
//  RheaTimeExtension.swift
//  Rhea_Example
//
//  Created by phoenix on 2023/7/27.
//  Copyright © 2023 Reer. All rights reserved.
//

import Foundation

/// List all your custom event to a Module, and depend this module instead of depending on RheaTime directly.
/// Biz -> RheaTimeExtension -> Rhea
@_exported import RheaTime

extension RheaEvent {
    static let aaaEvent: RheaEvent = "aaaEvent"
    static let bbbEvent: RheaEvent = "bbbEvent"
    static let cccEvent: RheaEvent = "cccEvent"
    static let dddEvent: RheaEvent = "dddEvent"
}
