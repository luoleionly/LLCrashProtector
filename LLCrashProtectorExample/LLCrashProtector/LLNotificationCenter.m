//
//  LLNotificationCenter.m
//  LLCrashProtector
//
//  Created by luolei on 2019/12/31.
//  Copyright © 2019 luolei. All rights reserved.
//

#import "LLNotificationCenter.h"
#import <objc/runtime.h>
#import "NSObject+LLAssociatedObject.h"

static char *LLObjectAssociatedKey = "LLObjectAssociatedKey";

@interface LLNotificationMiddle : NSObject

@property (nonatomic, copy) void(^deallocBlock)(void);

@end

@implementation LLNotificationMiddle

- (void)dealloc {
    
    if (self.deallocBlock) {
        self.deallocBlock();
    }
}

@end

@interface LLNotificationCenter ()

@end

@implementation LLNotificationCenter

+ (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    if (!observer) {
        return;
    }
    LLNotificationMiddle *middle = [LLNotificationMiddle new];
    __weak typeof (observer) Wobserver = observer;
    middle.deallocBlock = ^{
        if (Wobserver) {
            [[NSNotificationCenter defaultCenter]removeObserver:Wobserver];
        }
    };
    [observer llt_setObject:middle forAssociatedKey:LLObjectAssociatedKey retained:YES];
    [[NSNotificationCenter defaultCenter]addObserver:observer selector:aSelector name:aName object:anObject];
}

+ (void)postNotification:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter]postNotification:notification];
}
+ (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject {
    [[NSNotificationCenter defaultCenter]postNotificationName:aName object:anObject];
}
+ (void)postNotificationName:(NSNotificationName)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo {
    [[NSNotificationCenter defaultCenter]postNotificationName:aName object:anObject userInfo:aUserInfo];
}

+ (void)removeObserver:(id)observer {
    [[NSNotificationCenter defaultCenter]removeObserver:observer];
}

+ (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject {
    [[NSNotificationCenter defaultCenter]removeObserver:observer name:aName object:anObject];
}

@end
