import SwiftBasicFormat
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
        var actionClosure: ClosureExprSyntax?
        
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
                actionClosure = argument.expression.as(ClosureExprSyntax.self)
            default:
                break
            }
        }
        
        // `#rhea(time: .load) { context in ... }` puts the closure in trailingClosure.
        actionClosure = actionClosure ?? node.trailingClosure
        
        guard let actionClosure else {
            throw RheaMacroExpansionError("Requires a closure.")
        }
        
        return makeRegisterInfoDecls(
            time: time,
            priority: priority,
            repeatable: repeatable,
            async: async,
            closure: normalizedClosure(actionClosure),
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
        var actionClosure: ClosureExprSyntax?
        
        for argument in argumentList {
            switch argument.label?.text {
            case "func":
                actionClosure = argument.expression.as(ClosureExprSyntax.self)
            default:
                break
            }
        }
        actionClosure = actionClosure ?? node.trailingClosure
        
        guard let actionClosure else {
            throw RheaMacroExpansionError("Requires a closure.")
        }
        
        // Bare `#load { ... }` has no parameter clause; inject `context in`.
        let closureText: String
        if actionClosure.signature == nil {
            closureText = actionClosure.trimmedDescription.addedContextIn()
        } else {
            closureText = actionClosure.trimmedDescription
        }
        
        let rheaSource = """
        #rhea(time: .\(time), priority: \(priority), repeatable: \(repeatable), async: \(async), func: \(closureText))
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
        closure: ExprSyntax,
        isGlobal: Bool,
        uniqueName: String
    ) -> [DeclSyntax] {
        let staticString = isGlobal ? "" : "static "
        let hashLiteral = fnv1aHashLiteral(time)
        // Interpolate closure as a syntax node so Indenter applies the insertion-site indent.
        let declaration: DeclSyntax = """
            @used
            @section("__DATA,__rheatime")
            \(raw: staticString)let \(raw: uniqueName): RheaRegisterInfo = (
                \(raw: hashLiteral), \(raw: priority), \(raw: repeatable), \(raw: async),
                \(closure)
            )
            """
        return [declaration]
    }
    
    /// Drop call-site leading spaces/tabs, then `.formatted()` so Indenter can
    /// re-embed the closure at any nesting depth without stacking indentation.
    private static func normalizedClosure(_ actionClosure: ClosureExprSyntax) -> ExprSyntax {
        let normalized = actionClosure.trimmed.withoutLeadingIndentation
        return ExprSyntax(normalized).formatted().cast(ExprSyntax.self)
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

/// Drop spaces/tabs from leading trivia so call-site absolute indentation is not
/// stacked again when SwiftSyntax's Indenter embeds the node.
private final class LeadingIndentStripper: SyntaxRewriter {
    override func visit(_ token: TokenSyntax) -> TokenSyntax {
        let pieces = token.leadingTrivia.filter {
            switch $0 {
            case .spaces, .tabs: return false
            default: return true
            }
        }
        return token.with(\.leadingTrivia, Trivia(pieces: Array(pieces)))
    }
}

private extension ClosureExprSyntax {
    /// Closure with call-site indentation removed; newlines kept.
    var withoutLeadingIndentation: ClosureExprSyntax {
        LeadingIndentStripper().rewrite(self).cast(ClosureExprSyntax.self)
    }
}

private extension String {
    func addedContextIn() -> String {
        guard hasPrefix("{") else {
            return self
        }
        return "{ context in " + dropFirst()
    }
}
