//
//  Rhea.swift
//  Rhea
//
//  Created by phoenix on 2022/8/13.
//

@objc
public class Rhea: NSObject {
    typealias Class = RheaDelegate
    static var classes: [Rhea.Class.Type] = []

    @objc
    public static func rhea_load() {
        guard let configable = self as? RheaConfigable.Type else {
            assertionFailure("Please extend `Rhea` to conform to `RheaConfigable`")
            return
        }
        #if DEBUG
        var wrongClassNames: [String] = []
        #endif
        for name in configable.classNames {
            guard let aClass = NSClassFromString(name) else {
                #if DEBUG
                wrongClassNames.append(name)
                #endif
                continue
            }
            guard let rheaClass = aClass as? RheaDelegate.Type else {
                assertionFailure("Please extend you class to conform to `RheaDelegate`")
                continue
            }
            classes.append(rheaClass)
            rheaClass.rheaLoad()
        }
        #if DEBUG
        if wrongClassNames.count > 0 {
            assertionFailure("Generate classes failed from: \(wrongClassNames)")
        }
        #endif
        registerNotifications()
    }
    
    @objc
    public static func rhea_premain() {
        classes.forEach { rheaClass in
            rheaClass.rheaPremain()
        }
    }

    public static func trigger(event: RheaEvent) {
        classes.forEach { rheaClass in
            rheaClass.rheaDidReceiveCustomEvent(event: event)
        }
    }

    private static func registerNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { notification in
            let application = notification.object as? UIApplication ?? UIApplication.shared
            let launchOptions = notification.userInfo as? [UIApplication.LaunchOptionsKey: Any]

            let context = RheaContext(application: application, launchOptions: launchOptions)
            classes.forEach { rheaClass in
                rheaClass.rheaAppDidFinishLaunching(context: context)
            }
        }
    }
}
