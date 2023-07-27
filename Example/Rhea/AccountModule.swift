//
//  AccountModule.swift
//  Rhea_Example
//
//  Created by phoenix on 2023/6/29.
//  Copyright © 2023 Reer. All rights reserved.
//

import Foundation
import RheaTime

extension RheaEvent {
    static let userLoggedIn: RheaEvent = "userLoggedIn"
}

@objc(REAccountModule)
class AccountModule: NSObject, RheaDelegate {
    static func rheaLoad() {
        print("AccountModule \(#function)")
    }
    
    static func rheaPremain() {
        print("AccountModule \(#function)")
    }

    static func rheaAppDidFinishLaunching(context: RheaContext) {
        print("AccountModule \(#function)")
        print(context)
    }

    static func rheaDidReceiveCustomEvent(event: RheaEvent) {
        if event == .userLoggedIn {
            print(RheaEvent.userLoggedIn)
        }
    }
}
