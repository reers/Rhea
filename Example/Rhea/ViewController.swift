//
//  ViewController.swift
//  Rhea
//
//  Created by Asura19 on 08/13/2022.
//  Copyright (c) 2022 Asura19. All rights reserved.
//

import UIKit
import RheaTime
import OSLog



@_used
@_section("__DATA,__rheatime")
let test4: RheaRegisterInfo = ("rhea.load.2.true", { context in
    // do something when load
    
    print("参数是: \(context.param)")
    print("~~~~ ViewController load 2")
})


@_used
@_section("__DATA,__rheatime")
let test2: RheaRegisterInfo = ("rhea.load.5.false", { context in
    // do something when load
    
    print("参数是: \(context.param)")
    print("~~~~ ViewController load 5")
})



@_used 
@_section("__DATA,__rheatime")
let test: RheaRegisterInfo = ("rhea.premain.5.false", { context in
    // do something when load
    
    print("参数是: \(context.param)")
    print("~~~~ ViewController premain")
})

@_used
@_section("__DATA,__rheatime")
let test3: RheaRegisterInfo = ("rhea.appFinishLaunching.5.false", { context in
    // do something when load
    
    print("参数是: \(context.launchOptions)")
    print("~~~~ ViewController appFinishLaunching")
})

@_used
@_section("__DATA,__rheatime")
let test5: RheaRegisterInfo = ("rhea.homepageDidAppear.5.false", { context in
    // do something when load
    
    print("参数是: \(context.launchOptions)")
    print("~~~~ ViewController homepageDidAppear")
})

@_used
@_section("__DATA,__rheatime")
let test6: RheaRegisterInfo = ("rhea.homepageDidAppear.5.false", dfasdf)
let dfasdf: RheaFunction = { context in
    // do something when load
    
    print("参数是: \(context.launchOptions)")
    print("~~~~ ViewController homepageDidAppear 222222 ")
}

@_used
@_section("__DATA,__rheatime")
let __macro_local_4rheafMu_: RheaRegisterInfo = ("rhea.load.5.true", __macro_local_8rheaFuncfMu_)
let __macro_local_8rheaFuncfMu_: @convention(c) (RheaContext) -> Void = { context in
    
    print("~~~~ __macro_local_8rheaFuncfMu_ ")
}


//#rhea(time: .appFinishLaunching, priority: 5, repeatable: true) {
//
//}

extension RheaEvent {
    static let homepageDidAppear: RheaEvent = "app_homepageDidAppear"
}

class ViewController: UIViewController {
    
    static func test() {
        print(#function)
    }
    
    func instanceTest() {
        print(#function)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Rhea.trigger(event: .aaaEvent)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Rhea.trigger(event: .init(stringLiteral: "load"))
        Rhea.trigger(event: "homepageDidAppear")
//        test()
    }
}


//extension ViewController: RheaDelegate {
//    static func rheaLoad() {
//        print("ViewController \(#function)")
//    }
//    
//    static func rheaPremain() {
//        print("ViewController \(#function)")
//    }
//
//    static func rheaAppDidFinishLaunching(context: RheaContext) {
//        print("ViewController \(#function)")
//        print(context)
//    }
//
//    static func rheaDidReceiveCustomEvent(event: RheaEvent) {
//        switch event {
//        case "register_route": print("register_route")
//        case .homepageDidAppear: print(RheaEvent.homepageDidAppear)
//        case .aaaEvent: print(event)
//        case .bbbEvent: print(event)
//        case .cccEvent: print(event)
//        case .dddEvent: print(event)
//        default: break
//        }
//    }
//}
