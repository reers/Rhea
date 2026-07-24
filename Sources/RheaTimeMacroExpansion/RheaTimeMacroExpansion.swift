import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Shared helpers for producing `#rhea` / section-backed declarations.
///
/// Use these from your own macro plugin when wrapping Rhea (instead of returning
/// `#rhea(...)` for the compiler to re-expand). See
/// https://github.com/swiftlang/swift/issues/79235
public enum RheaMacroExpansion {
    
    /// Expands a synthesized or real `#rhea(...)` freestanding declaration macro node.
    public static func expandRhea(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let argumentList = node.arguments
        var time: String = ""
        var priority: String = "5"
        var repeatable: String = "false"
        var async: String = "false"
        var functionBody: String = ""
        var signature: String?
        
        for argument in argumentList {
            switch argument.label?.text {
            case "time":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    time = memberAccess.declName.baseName.text
                }
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self),
                   let hostValue = stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text {
                    time = hostValue
                }
            case "priority":
                if let intLiteral = argument.expression.as(IntegerLiteralExprSyntax.self) {
                    priority = intLiteral.literal.text
                } else if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    let memberName = memberAccess.declName.baseName.text
                    switch memberName {
                    case "veryLow": priority = "1"
                    case "low": priority = "3"
                    case "high": priority = "7"
                    case "veryHigh": priority = "9"
                    default: priority = "5"
                    }
                }
            case "repeatable":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    repeatable = boolLiteral.literal.text
                }
            case "async":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    async = boolLiteral.literal.text
                }
            case "func":
                if let closureExpr = argument.expression.as(ClosureExprSyntax.self) {
                    functionBody = closureExpr.statements.trimmedDescription
                    if let sig = closureExpr.signature {
                        signature = sig.description
                    }
                }
            default:
                break
            }
        }
        
        let closure: String
        if !functionBody.isEmpty {
            closure = """
            { \(signature ?? "context in")\n\(functionBody)
            }
            """
        } else if let trailingClosure = node.trailingClosure?.trimmedDescription {
            closure = trailingClosure
        } else {
            throw RheaMacroExpansionError("Requires a closure.")
        }
        
        return makeRegisterInfoDecls(
            time: time,
            priority: priority,
            repeatable: repeatable,
            async: async,
            closure: closure,
            isGlobal: context.lexicalContext.isEmpty,
            uniqueName: "\(context.makeUniqueName("rhea"))"
        )
    }
    
    /// Expands a convenience wrapper like `#load` / `#premain` by synthesizing
    /// `#rhea(time: .<time>, priority:..., repeatable:..., async:..., func: ...)`
    /// and expanding it in-process.
    ///
    /// Defaults match `#rhea`: `priority = 5` (`.normal`), `repeatable = false`, `async = false`.
    ///
    /// Do **not** `return ["#rhea(...)"]` for nested freestanding declaration macros.
    public static func expandFixedTimeWrapper(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext,
        time: String,
        priority: Int = 5,
        repeatable: Bool = false,
        async: Bool = false
    ) throws -> [DeclSyntax] {
        let argumentList = node.arguments
        var functionBody: String = ""
        var signature: String?
        
        for argument in argumentList {
            switch argument.label?.text {
            case "func":
                if let closureExpr = argument.expression.as(ClosureExprSyntax.self) {
                    functionBody = closureExpr.statements.trimmedDescription
                    if let sig = closureExpr.signature {
                        signature = sig.description
                    }
                }
            default:
                break
            }
        }
        
        let closure: String
        if !functionBody.isEmpty {
            closure = """
            { \(signature ?? "context in")\n\(functionBody)
            }
            """
        } else if let trailingClosure = node.trailingClosure?.trimmedDescription {
            closure = trailingClosure.addedContextIn()
        } else {
            throw RheaMacroExpansionError("Requires a closure.")
        }
        
        let rheaSource = """
        #rhea(time: .\(time), priority: \(priority), repeatable: \(repeatable), async: \(async), func: \(closure))
        """
        let rheaCall = DeclSyntax(stringLiteral: rheaSource)
        guard let rheaNode = rheaCall.as(MacroExpansionDeclSyntax.self) else {
            throw RheaMacroExpansionError("Failed to synthesize #rhea(time: .\(time)).")
        }
        return try expandRhea(of: rheaNode, in: context)
    }
    
    public static func makeRegisterInfoDecls(
        time: String,
        priority: String,
        repeatable: String,
        async: String,
        closure: String,
        isGlobal: Bool,
        uniqueName: String
    ) -> [DeclSyntax] {
        let staticString = isGlobal ? "" : "static "
        let hashLiteral = fnv1aHashLiteral(time)
        let declarationString = """
        @used 
        @section("__DATA,__rheatime")
        \(staticString)let \(uniqueName): RheaRegisterInfo = (
            \(hashLiteral),
            \(priority), \(repeatable), \(async),
            \(closure)
        )
        """
        return [DeclSyntax(stringLiteral: declarationString)]
    }
}

public struct RheaMacroExpansionError: Error, CustomStringConvertible {
    public let text: String
    public init(_ text: String) { self.text = text }
    public var description: String { text }
}

// MARK: - FNV-1a Hash (compile-time, mirrors the runtime implementation in Definitions.swift)

private func fnv1aHash(_ string: String) -> UInt64 {
    var hash: UInt64 = 0xcbf29ce484222325
    for byte in string.utf8 {
        hash ^= UInt64(byte)
        hash &*= 0x100000001b3
    }
    return hash
}

private func fnv1aHashLiteral(_ string: String) -> String {
    let hash = fnv1aHash(string)
    let hex = String(hash, radix: 16)
    return "0x" + String(repeating: "0", count: max(0, 16 - hex.count)) + hex
}

private extension String {
    func addedContextIn() -> String {
        guard hasPrefix("{") else {
            return self
        }
        return "{ context in " + dropFirst()
    }
}
