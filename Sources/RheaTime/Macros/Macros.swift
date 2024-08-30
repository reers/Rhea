//
//  Macros.swift
//
//
//  Created by phoenix on 2024/8/21.
//

@freestanding(declaration)
public macro rhea(
    time: RheaEvent,
    priority: Int = 5,
    repeatable: Bool = false,
    func: RheaFunction
) = #externalMacro(module: "RheaTimeMacros", type: "WriteSectionMacro")
