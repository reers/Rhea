//
//  RheaSections.swift
//  RheaTime
//
//  Created by phoenix on 2024/6/19.
//

public typealias RheaFuncType = () -> Void

// MARK: - Sections
// Rules: rhea_{$time}_{$priority}
// h: high, d: default, l: low

/// rheaLoadH
/// rheaLoadD
/// rheaLoadL
/// rheaPremainH
/// rheaPremainD
/// rheaPremainL
/// rheaAppdflH (`dfl` means didFinishLaunching)
/// rheaAppdflD
/// rheaAppdflL

// MARK: - rheaLoadH
@_silgen_name(raw: "section$start$__DATA$__rheaLoadH") 
var rheaLoadHStart: Int

@_silgen_name(raw: "section$end$__DATA$__rheaLoadH")
var rheaLoadHEnd: Int

@_used
@_section("__DATA,__rheaLoadH") let a: RheaFuncType = {
    // do something when load
    print("~~~~ rhea framework load")
}
/*
@_used
@_section("__DATA,__rheaLoadH") let a: RheaFuncType = {
    // do something when load
}
*/
