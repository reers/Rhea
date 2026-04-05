[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/reers/Rhea)

# Rhea

一个用于触发各种时机的框架. 灵感来自字节内部的框架 Gaia, 但是以不同的方式实现的.
在希腊神话中, Rhea 是 Gaia 的女儿, 本框架也因此得名.

利用 `@used` 和 `@section`（Swift 6.3 起正式支持）可以将数据写入 Mach-O section, 再结合 Swift Macro, 就可以实现 OC 时代各种解耦和的, 用于注册信息的能力了. 本框架也采用此方式进行了全面重构.

## 要求
Xcode 26.4 + (Swift 6.3+)

> 对于旧版 Xcode (16.0-26.3)，请使用 [2.2.8](https://github.com/reers/Rhea/releases/tag/2.2.8) 版本，该版本使用实验性的 `@_section` 和 `@_used` 属性。

iOS 13.0+, macOS 10.15+, tvOS 13.0+, visionOS 1.0+, watchOS 7.0+

swift-syntax 601.0.1+

## 基本使用
```swift
import RheaExtension

#rhea(time: .customEvent, priority: .veryLow, repeatable: true, func: { _ in
    print("~~~~ customEvent in main")
})

#rhea(time: .homePageDidAppear, async: true, func: { context in
    // This will run on a background thread
    print("~~~~ homepageDidAppear")
})

#rhea(time: .load) { _ in
    print("load with trailing closure")
}

#load {
    print("use load directly")
}

#premain {
    print("use premain directly")
}

#appDidFinishLaunching {
    print("use appDidFinishLaunching directly")
}

class ViewController: UIViewController {
    
    #load {
        DispatchQueue.global().async {
            print("~~~~ load nested in main")
        }
    }

    #rhea(time: .homePageDidAppear) { context in
        print("homePageDidAppear with trailing closure \(context.param)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Rhea.trigger(event: .homePageDidAppear, param: self)
    }
}
```
框架内提供了三个回调时机, 分别是
1. OC + load （强烈不推荐） 使用此时机可能会阻塞整个加载过程，从而显著增加应用的启动时间。只要有可能，请在.load中使用异步调用, 或优先选择 .premain 或 .appDidFinishLaunching 来执行初始化任务。
2. constructor (premain)
3. appDidFinishLaunching ()

这三个时机是由框架内部触发的，外部无需调用 trigger 方法。

另外用户可以自定义时机和触发, 可以配置同时机的执行优先级, 以及是否可以重复执行.
⚠️⚠️⚠️ 但需要注意的是, 自定义时机的变量名要和其 rawValue 的 String 完全相同, 否则 Swift Macro 无法正确处理 

```swift
/// Registers a callback function for a specific Rhea event.
///
/// This macro is used to register a callback function to a section in the binary,
/// associating it with a specific event time, priority, and repeatability.
///
/// - Parameters:
///   - time: A `RheaEvent` representing the timing or event name for the callback.
///           This parameter also supports direct string input, which will be
///           processed by the framework as an event identifier.
///   - priority: A `RheaPriority` value indicating the execution priority of the callback.
///               Default is `.normal`. Predefined values include `.veryLow`, `.low`,
///               `.normal`, `.high`, and `.veryHigh`. Custom integer priorities are also
///               supported. Callbacks for the same event are sorted and executed based
///               on this priority.
///   - repeatable: A boolean flag indicating whether the callback can be triggered multiple times.
///                 If `false` (default), the callback will only be executed once.
///                 If `true`, the callback can be re-triggered on subsequent event occurrences.
///   - async: A boolean flag indicating whether the callback should be executed asynchronously.
///            If `false` (default), the callback will be executed on the main thread.
///            If `true`, the callback will be executed on a background thread. Note that when
///            `async` is `true`, the execution order based on `priority` may not be guaranteed.
///            Even when `async` is set to `false`, users can still choose to dispatch their tasks
///            to a background queue within the callback function if needed. This provides
///            flexibility for handling both quick, main thread operations and longer-running
///            background tasks.
///   - func: The callback function of type `RheaFunction`. This function receives a `RheaContext`
///           parameter, which includes `launchOptions` and an optional `Any?` parameter.
///
/// - Note: When triggering an event externally using `Rhea.trigger(event:param:)`, you can include
///         an additional parameter that will be passed to the callback via the `RheaContext`.
///
/// ```swift
/// #rhea(time: .load, priority: .veryLow, repeatable: true, func: { _ in
///     print("~~~~ load in Account Module")
/// })
///
/// #rhea(time: .registerRoute, func: { _ in
///     print("~~~~ registerRoute in Account Module")
/// })
///
/// // Use a StaticString as event directly
/// #rhea(time: "ACustomEventString", func: { _ in
///     print("~~~~ custom event")
/// })
///
/// // Example of using async execution
/// #rhea(time: .load, async: true, func: { _ in
///     // This will run on a background thread
///     performHeavyTask()
/// })
///
/// // Example of manually dispatching to background queue when async is false
/// #rhea(time: .load, func: { _ in
///     DispatchQueue.global().async {
///         // Perform background task
///     }
/// })
/// ```
/// - Note: ⚠️⚠️⚠️ When extending ``RheaEvent`` with static constants, ensure that
///   the constant name exactly matches the string literal value. This practice
///   maintains consistency and prevents confusion.
///
@freestanding(declaration)
public macro rhea(
    time: RheaEvent,
    priority: RheaPriority = .normal,
    repeatable: Bool = false,
    async: Bool = false,
    func: RheaFunction
) = #externalMacro(module: "RheaTimeMacros", type: "WriteTimeToSectionMacro")

```

添加 [代码片段](https://github.com/reers/Rhea/tree/main/CodeSnippets) 到 XCode, 高效开发.

`~/Library/Developer/Xcode/UserData/CodeSnippets/`

<img width="555" alt="截屏2025-02-08 20 26 22" src="https://github.com/user-attachments/assets/4db5a273-9084-4be5-8803-49674c9d9f5b" />

## 性能说明

Release 模式下, 在 iPhone 15 Pro 上测试，3000 个注册宏，从 section 读取注册函数耗时约 20 毫秒，另外 3000 次调度后执行 print 带来的性能损耗约 1.5 毫秒, 而对于 iPhone 8 这样的老旧机型, 读取3000个注册函数的耗时是98毫秒. 所以总体上, 对任何一个超大型 App 来说, 这样的性能表现都是足够使用的.

## 使用说明

1. 函数内打断点需要宏展开后再打, 否则断点不生效.
![CleanShot 2025-07-30 at 16 08 14@2x](https://github.com/user-attachments/assets/4041c240-80df-48ba-89c7-971438c9bfb9)

3. 传入的函数如果比较复杂可能会报错，可以封装成函数后再调用即可：

```swift
func complexFunction(context: RheaContext) {
    // 复杂的业务逻辑
    performComplexTask()
    handleMultipleOperations()
}

#rhea(time: .load) { context in
    complexFunction(context: context)
}
```

## 接入工程

### Example工程: https://github.com/Asura19/RheaExample

因为业务要自定义事件, 如下:
```swift
extension RheaEvent {
    public static let homePageDidAppear: RheaEvent = "homePageDidAppear"
    public static let registerRoute: RheaEvent = "registerRoute"
    public static let didEnterBackground: RheaEvent = "didEnterBackground"
}
```
所以推荐的方式是, 将本框架再封装一层, 如命名为 RheaExtension
```
业务A    业务B
  ↓       ↓
RheaExtension
     ↓
  RheaTime
```

另外, RheaExtension 中除了可以自定义事件名, 还可以封装一些时机事件的业务逻辑
```
#rhea(time: .appDidFinishLaunching, func: { _ in
    NotificationCenter.default.addObserver(
        forName: UIApplication.didEnterBackgroundNotification,
        object: nil,
        queue: .main
    ) { _ in
        Rhea.trigger(event: .didEnterBackground)
    }
})
```
外部使用
```
#rhea(time: .didEnterBackground, repeatable: true, func: { _ in
    print("~~~~ app did enter background")
})
```

### Swift Package Manager
```swift
// Package.swift
let package = Package(
    name: "RheaExtension",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "RheaExtension", targets: ["RheaExtension"]),
    ],
    dependencies: [
        .package(url: "https://github.com/reers/Rhea.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "RheaExtension",
            dependencies: [
                .product(name: "RheaTime", package: "Rhea")
            ]
        ),
    ]
)

// RheaExtension.swift
// @_exported 导出后, 其他业务 module 以及主 target 就只需 import RheaExtension 了
@_exported import RheaTime

extension RheaEvent {
    public static let homePageDidAppear: RheaEvent = "homePageDidAppear"
    public static let registerRoute: RheaEvent = "registerRoute"
    public static let didEnterBackground: RheaEvent = "didEnterBackground"
}
```

```swift
// 业务 Module Account
// Package.swift
let package = Package(
    name: "Account",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "Account",
            targets: ["Account"]),
    ],
    dependencies: [
        .package(name: "RheaExtension", path: "../RheaExtension")
    ],
    targets: [
        .target(
            name: "Account",
            dependencies: [
                .product(name: "RheaExtension", package: "RheaExtension")
            ]
        ),
    ]
)
// 业务 Module Account 使用
import RheaExtension

#rhea(time: .homePageDidAppear, func: { context in
    print("~~~~ homepageDidAppear in main")
})
```

```swift
// 主 target 使用
import RheaExtension

#rhea(time: .premain, func: { _ in
    Rhea.trigger(event: .registerRoute)
})
```

另外, 还可以直接传入 `StaticString` 作为 time key.
```
#rhea(time: "ACustomEventString", func: { _ in
    print("~~~~ custom event")
})
```

### CocoaPods

Podfile中添加:

```ruby
pod 'RheaTime'
```

由于 CocoaPods 不支持直接使用 Swift Macro, 可以将宏实现编译为二进制提供使用, 接入方式如下, 需要设置`s.pod_target_xcconfig`来加载宏实现的二进制插件:
```swift
// RheaExtension podspec
Pod::Spec.new do |s|
  s.name             = 'RheaExtension'
  s.version          = '0.1.0'
  s.summary          = 'A short description of RheaExtension.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/bjwoodman/RheaExtension'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bjwoodman' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/bjwoodman/RheaExtension.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.source_files = 'RheaExtension/Classes/**/*'

  s.dependency 'RheaTime', '2.2.7'

  # 复制以下 config 到你的 pod
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/MacroPlugin/RheaTimeMacros#RheaTimeMacros'
  }
end
```

```swift
Pod::Spec.new do |s|
  s.name             = 'Account'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Account.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/bjwoodman/Account'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bjwoodman' => 'x.rhythm@qq.com' }
  s.source           = { :git => 'https://github.com/bjwoodman/Account.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.source_files = 'Account/Classes/**/*'
  s.dependency 'RheaExtension'
  
  # 复制以下 config 到你的 pod
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/MacroPlugin/RheaTimeMacros#RheaTimeMacros'
  }
end
```

或者, 如果不使用`s.pod_target_xcconfig`和`s.user_target_xcconfig`, 也可以在 podfile 中添加如下脚本统一处理:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    rhea_dependency = target.dependencies.find { |d| ['RheaTime', 'RheaExtension'].include?(d.name) }
    if rhea_dependency
      puts "Adding Rhea Swift flags to target: #{target.name}"
      target.build_configurations.each do |config|
        swift_flags = config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['$(inherited)']
        
        plugin_flag = '-Xfrontend -load-plugin-executable -Xfrontend ${PODS_ROOT}/RheaTime/MacroPlugin/RheaTimeMacros#RheaTimeMacros'
        
        unless swift_flags.join(' ').include?(plugin_flag)
          swift_flags.concat(plugin_flag.split)
        end
        
        
        end
        
        config.build_settings['OTHER_SWIFT_FLAGS'] = swift_flags
      end
    end
  end
end
```

<p><strong>⚠️ 重要提示：</strong>若在 Xcode 14+ 遇到 <code>rsync</code> 权限错误，需关闭用户脚本沙盒：</p>
<p>在工程的 <strong>Build Settings</strong> 中搜索 <code>User Script Sandboxing</code>，将 <code>ENABLE_USER_SCRIPT_SANDBOXING</code> 设为 <code>No</code>。这可解决 Xcode 严格沙盒限制导致的 CocoaPods 脚本执行失败问题。</p>

代码使用上与SPM相同.

## Note

⚠️ 理论上对 rhea macro 进行二次包装可以实现更多便利的宏, 如路由注册, 插件注册, 模块初始化, 或是对 rhea 某个 time 的具体封装, 但目前疑似是 Swift 的 bug, 暂时无法这样做, 我向 Swift 提了一个 [issue](https://github.com/swiftlang/swift/issues/79235), 正在等待回应

## Author

Asura19, x.rhythm@qq.com

## License

Rhea is available under the MIT license. See the LICENSE file for more info.
