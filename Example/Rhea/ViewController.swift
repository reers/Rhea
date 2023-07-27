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

extension RheaEvent {
    static let homepageDidAppear: RheaEvent = "app_homepageDidAppear"
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Rhea.trigger(event: .aaaEvent)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Rhea.trigger(event: .homepageDidAppear)
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
