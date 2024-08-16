//
//  RheaSections.swift
//  RheaTime
//
//  Created by phoenix on 2024/6/19.
//

@frozen public struct TTPoint {
    public let x: Int
    public let y: Int
    
    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public struct RheaInfoStorage {
    public let name: StaticString
    public let function: UnsafeRawPointer

    public init(name: StaticString, function: @escaping RheaFuncType) {
        self.name = name
        self.function = unsafeBitCast(function, to: UnsafeRawPointer.self)
    }
}

public typealias InfoStorage = (name: StaticString, function: RheaFuncType)

// 用于存储函数信息的结构体
public struct RheaInfo {
    public let name: StaticString
    public let function: RheaFuncType
    
    public init(name: StaticString, function: @escaping RheaFuncType) {
        self.name = name
        self.function = function
    }
}


//public typealias RheaFuncType = @convention(c) () -> Void

public typealias RheaFuncType = () -> Void

public typealias RheaStringAndFunc = (StaticString, @convention(c) () -> Void)

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
