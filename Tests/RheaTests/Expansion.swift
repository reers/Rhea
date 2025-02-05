import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import RheaTime
import Testing
import Foundation

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(RheaTimeMacros)
import RheaTimeMacros

let testMacros: [String: Macro.Type] = [
    "rhea": WriteTimeToSectionMacro.self
]
#endif

final class RheaTimeTests: XCTestCase {
    
    func testExpansion() throws {
        #if canImport(RheaTimeMacros)
        assertMacroExpansion(
            """
            class ViewController: UIViewController {
                var name: String?
            
                #rhea(time: .load, priority: .veryLow, repeatable: true) { context in
                    print("\\(context.param)")
                }
            
                override func viewDidAppear(_ animated: Bool) {
                    super.viewDidAppear(animated)
                    Rhea.trigger(event: .homePageDidAppear, param: self)
                } 
            }
            """,
            expandedSource: """
            class ViewController: UIViewController {
                var name: String?

                @_used
                @_section("__DATA,__rheatime")
                static let __macro_local_4rheafMu_: RheaRegisterInfo = (
                    "rhea.load.1.true.false",
                    { context in
                        print("\\(context.param)")
                    }
                )

                override func viewDidAppear(_ animated: Bool) {
                    super.viewDidAppear(animated)
                    Rhea.trigger(event: .homePageDidAppear, param: self)
                } 
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testExpansion2() throws {
        #if canImport(RheaTimeMacros)
        assertMacroExpansion(
            """
            #rhea(time: .customEvent, priority: .veryLow, repeatable: true, func: { _ in
                print("~~~~ customEvent in main")
            })
            """,
            expandedSource: """
            @_used
            @_section("__DATA,__rheatime")
            let __macro_local_4rheafMu_: RheaRegisterInfo = (
                "rhea.customEvent.1.true.false",
                { _ in
                    print("~~~~ customEvent in main")
                }
            )
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
