# Rhea

一个用于触发各种时机的框架. 灵感来自字节内部的框架 Gaia, 但是以不同的方式实现的. (原理上更简单, 使用上稍麻烦) 
在希腊神话中, Rhea 是 Gaia 的女儿, 本框架也因此得名.

## 使用方法

### 在工程任意位置扩展 `Rhea` 以实现 `RheaConfigable` 协议, 框架会在启动时自动读取该配置, 并以 `NSClassFromString()` 生成 Class, 所以要求使用本框架的类型必须是 class, 而不能是 struct, enum
```
import Foundation
import RheaTime

extension Rhea: RheaConfigable {
    public static var classNames: [String] {
        return [
            "Rhea_Example.ViewController"
        ]
    }
}

```

### 在需要使用的类型实现 `RheaDelegate` 中需要的方法. 
其中 `rheaLoad`, `rheaAppDidFinishLaunching(context:)` 为框架内部自动调用, 而 `rheaDidReceiveCustomEvent(event:)` 需要使用者调用 `Rhea.trigger(event:)` 来主动触发.
主动触发的事件名可以直接使用字符串, 也可以扩展 `RheaEvent` 定义常量
```
extension RheaEvent {
    static let homepageDidAppear: RheaEvent = "app_homepageDidAppear"
}

class ViewController: UIViewController {

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
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
`>= iOS 10.0`

## Installation

Rhea is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RheaTime'
```

## Author

Asura19, x.rhythm@qq.com

## License

Rhea is available under the MIT license. See the LICENSE file for more info.
