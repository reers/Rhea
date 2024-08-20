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
let test: RheaRegisterInfo = ("rhea.premain.5.true", { context in
    // do something when load
    
    print("参数是: \(context.param)")
    print("~~~~ ViewController load")
    ViewController.test()
    ViewController().instanceTest()
})

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
        Rhea.trigger(event: .homepageDidAppear)
        
//        test()
    }
    
    func test() {
        _dyld_register_func_for_add_image { (image, slide) in
            var info = Dl_info()
            if (dladdr(image, &info) == 0) {
                return
            }
            if (!String(cString: info.dli_fname).hasPrefix(Bundle.main.bundlePath)) {
                return
            }
            print("~~~~ image: \(String(describing: image))")
        }
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
