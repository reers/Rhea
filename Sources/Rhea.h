//
//  Rhea.h
//  Rhea
//
//  Created by phoenix on 2022/8/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define RheaTimeBegin(UniqueCategoryName) \
@interface Rhea (UniqueCategoryName)      \
@end                                      \
@implementation Rhea (UniqueCategoryName) \


#define RheaTimeEnd @end

typedef NSString * RheaTimeName NS_EXTENSIBLE_STRING_ENUM;
/// `load`
FOUNDATION_EXPORT RheaTimeName const RheaTimeNameLoad;
/// `appWillFinishLaunching`
FOUNDATION_EXPORT RheaTimeName const RheaTimeNameAppWillFinishLaunching;
/// `appDidFinishLaunching`
FOUNDATION_EXPORT RheaTimeName const RheaTimeNameAppDidFinishLaunching;

@interface Rhea : NSObject
+ (instancetype)shared;
- (void)triggerTime:(RheaTimeName)timeName NS_SWIFT_NAME(trigger(_:));
@end

NS_ASSUME_NONNULL_END
