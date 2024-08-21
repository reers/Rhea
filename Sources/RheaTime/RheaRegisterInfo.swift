//
//  RheaRegisterInfo.swift
//  RheaTime
//
//  Created by phoenix on 2024/6/19.
//

public typealias RheaFunction = @convention(c)(RheaContext) -> Void

/// The `StaticString` is like `"rhea.load.5.true"`, that means `"$prefix.$rheaTimeName.$priority.$isRepeatable"`
public typealias RheaRegisterInfo = (StaticString, RheaFunction)


