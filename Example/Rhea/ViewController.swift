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

// import RheaTimeExtension
//@_used
//@_section("__DATA,__rheaLoadH")
//let info1: RheaInfo = RheaInfo(name: "asdf") {
//    print("123")
//}

//@_cdecl("rhea_function_asdf")
//func rheaFunctionAsdf() {
//    print("123")
//}
//
//@_used
//@_section("__DATA,__rheaLoadH")
//let rheaInfoStorage = RheaInfoStorage(name: "asdf", function: rheaFunctionAsdf)


//let loadViewControllerInfo = InfoStorage(
//    name: "loadViewController",
//    function: {
//        print("~~~~ ViewController load")
//        ViewController.test()
//        ViewController().instanceTest()
//    }
//)

@_section("__TEXT,__mysection") var gp1: UnsafeMutablePointer<Int>? = nil
@_section("__TEXT,__mysection") var gp2: UnsafeMutablePointer<Int>? = UnsafeMutablePointer(bitPattern: 0x42424242)

//@_used @_section("__DATA,__rheaLoadH") let test: (StaticString, StaticString) = ("aasfsfdsfsd", "asfsd")




//@_used
//@_section("__DATA,__rheaString") let string: StaticString = "abc"
//
//@_used
//@_section("__DATA,__rheaLoadH") let fasdfasfaasdf: @convention(c) () -> Void = {
//    // do something when load
//    print("~~~~ ViewController load")
//    ViewController.test()
//    ViewController().instanceTest()
//}

@_used @_section("__DATA,__psection") let test: RheaStringAndFunc = ("aasfsfdsfsd", {
    // do something when load
    print("~~~~ ViewController load")
    ViewController.test()
    ViewController().instanceTest()
})

//@_used
//@_section("__DATA,__rheaLoadH") let b: RheaFuncType = {
//    // do something when load
//    print("~~~~ ViewController load 2222")
//}

@_silgen_name("function_in_special_section")
@_section("__TEXT,__swift5_funcs")
func specialSectionFunction() {
    print("This function is stored in a special section")
}

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
        
        test()
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


extension ViewController: RheaDelegate {
    static func rheaLoad() {
        print("ViewController \(#function)")
    }
    
    static func rheaPremain() {
        print("ViewController \(#function)")
    }

    static func rheaAppDidFinishLaunching(context: RheaContext) {
        print("ViewController \(#function)")
        print(context)
    }

    static func rheaDidReceiveCustomEvent(event: RheaEvent) {
        switch event {
        case "register_route": print("register_route")
        case .homepageDidAppear: print(RheaEvent.homepageDidAppear)
        case .aaaEvent: print(event)
        case .bbbEvent: print(event)
        case .cccEvent: print(event)
        case .dddEvent: print(event)
        default: break
        }
    }
}
