# Rhea

一个用于触发各种时机的框架. 灵感来自字节内部的框架 Gaia, 但是以不同的方式实现的. 
本框架只是对Gaia的拙劣模仿, 并不是很推荐使用.

基本原理很简单, 在load时获取 `Rhea` 类所有的分类方法, 对其按时机进行分组, 待外部业务触发某个时机, 再调用所有对应方法.
缺点如下: 
* Rhea 的分类如果很多, 会影响启动时长
* 分类命名需要按照一定格式, `{时机名}_{uniqueID一般是文件名}`, 如 `appDidFinishLaunching_homePageViewController`, 且没有代码提示, 容易书写错误.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

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
