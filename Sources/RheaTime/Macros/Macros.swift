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
    repeatable: Bool
) = #externalMacro(module: "RheaTimeMacros", type: "WriteSectionMacro")
