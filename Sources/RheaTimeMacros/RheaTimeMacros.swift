import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public enum MacroExpansionError: Error {
    case invalidArguments
    case test(String)
}

public struct WriteSectionMacro: ExpressionMacro {
    
    public static func expansion(
        of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> SwiftSyntax.ExprSyntax {
        let argumentList = node.argumentList
        var time: String = ""
        var priority: String = ""
        var repeatable: String = ""
        var functionBody: String = ""
        var signature: String?
        
        for argument in argumentList {
            switch argument.label?.text {
            case "time":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    time = memberAccess.declName.baseName.text
                }
            case "priority":
                if let intLiteral = argument.expression.as(IntegerLiteralExprSyntax.self) {
                    priority = intLiteral.literal.text
                }
            case "repeatable":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    repeatable = boolLiteral.literal.text
                }
            case "function":
                if let closureExpr = argument.expression.as(ClosureExprSyntax.self) {
                    functionBody = closureExpr.statements.description
                    if let sig = closureExpr.signature {
                        signature = sig.description
                    }
                }
            default:
                break
            }
        }
        
        let infoName = "rhea_\(context.makeUniqueName(""))"
        
        let expansionString = """
            @_used @_section("__DATA,__rheatime") var \(infoName): RheaRegisterInfo = ("rhea.\(time).\(priority).\(repeatable)", { \(signature ?? "context in") \(functionBody) })
            """
        return ExprSyntax(stringLiteral: expansionString)
    }
}

public struct WriteSectionMacro2: ExpressionMacro {
    public static func expansion(
        of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> SwiftSyntax.ExprSyntax {
        let argumentList = node.argumentList
        var time: String = ""
        var priority: String = ""
        var repeatable: String = ""
        
        for argument in argumentList {
            switch argument.label?.text {
            case "time":
                if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                    time = memberAccess.declName.baseName.text
                }
            case "priority":
                if let intLiteral = argument.expression.as(IntegerLiteralExprSyntax.self) {
                    priority = intLiteral.literal.text
                }
            case "repeatable":
                if let boolLiteral = argument.expression.as(BooleanLiteralExprSyntax.self) {
                    repeatable = boolLiteral.literal.text
                }
            default:
                break
            }
        }
        
        let infoName = "rhea_\(context.makeUniqueName("info"))"
        let funcName = "rhea_\(context.makeUniqueName("func"))"
        
        let entireCall = node.parent?.as(ExprSyntax.self) ?? node.as(ExprSyntax.self)!
        let entireString = "\(entireCall)"
        let closure = extractFromFirstBrace(entireString) ?? ""
        
        let expansionString = """
            @_used
            @_section("__DATA,__rheatime")
            var \(infoName): RheaRegisterInfo = ("rhea.\(time).\(priority).\(repeatable)", \(funcName))
            let \(funcName): RheaFunction = \(closure)
            """
        return ExprSyntax(stringLiteral: expansionString)
    }
    
    static func extractFromFirstBrace(_ input: String) -> String? {
        if let range = input.range(of: "{") {
            return String(input[range.lowerBound...])
        }
        return nil
    }
}

@main
struct RheaTimePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WriteSectionMacro.self,
        WriteSectionMacro2.self,
    ]
}
