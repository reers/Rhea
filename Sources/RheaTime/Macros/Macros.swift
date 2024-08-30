//
//  Macros.swift
//
//
//  Created by phoenix on 2024/8/21.
//

@freestanding(expression)
public macro rhea(
    time: RheaEvent,
    priority: Int,
    repeatable: Bool,
    function: RheaFunction
) = #externalMacro(module: "RheaTimeMacros", type: "WriteSectionMacro")


@freestanding(expression)
public macro rhea2(
    time: RheaEvent,
    priority: Int,
    repeatable: Bool,
    function: RheaFunction
) = #externalMacro(module: "RheaTimeMacros", type: "WriteSectionMacro2")

@freestanding(declaration)
public macro rhea3(
    time: RheaEvent,
    priority: Int = 100,
    repeatable: Bool = false,
    function: RheaFunction
) = #externalMacro(module: "RheaTimeMacros", type: "WriteSectionMacro3")

@freestanding(declaration)
public macro rhea4(
    time: RheaEvent,
    priority: Int,
    repeatable: Bool
) = #externalMacro(module: "RheaTimeMacros", type: "WriteSectionMacro4")


@freestanding(declaration)
public macro routeHost(_ host: String) = #externalMacro(module: "RheaTimeMacros", type: "RouteHostMacro")
