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

extension RheaEvent {
    static let homepageDidAppear: RheaEvent = "app_homepageDidAppear"
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Rhea.trigger(event: .homepageDidAppear)
    }
}


extension ViewController: RheaDelegate {
    static func rheaLoad() {
        print(#function)
    }

    static func rheaAppDidFinishLaunching(context: RheaContext) {
        print(#function)
        print(context)
    }

    static func rheaDidReceiveCustomEvent(event: RheaEvent) {
        switch event {
        case "register_route": print("register_route")
        case .homepageDidAppear: print(RheaEvent.homepageDidAppear)
        default: break
        }
    }
}
