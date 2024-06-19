//
//  RheaDelegate.swift
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

public protocol RheaDelegate {
    static func rheaLoad()
    static func rheaPremain()
    static func rheaAppDidFinishLaunching(context: RheaContext)
    static func rheaDidReceiveCustomEvent(event: RheaEvent)
}

public extension RheaDelegate {
    static func rheaLoad() {}
    static func rheaPremain() {}
    static func rheaAppDidFinishLaunching(context: RheaContext) {}
    static func rheaDidReceiveCustomEvent(event: RheaEvent) {}
}
