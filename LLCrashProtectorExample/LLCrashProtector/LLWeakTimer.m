//
//  LLWeakTimer.m
//  LLCrashProtector
//
//  Created by luolei on 2019/12/30.
//  Copyright © 2019 luolei. All rights reserved.
//

#import "LLWeakTimer.h"

@interface LLProxy : NSProxy

@property (nonatomic, weak) id target;

@end

@implementation LLProxy

- (id)forwardingTargetForSelector:(SEL)selector {
    return self.target;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    void *null = NULL;
    [invocation setReturnValue:&null];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [NSObject instanceMethodSignatureForSelector:@selector(init)];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

@end

@interface LLWeakTimer ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) void(^timerBlock)(void);

@end

@implementation LLWeakTimer


- (instancetype)initWithTimeInterval:(NSTimeInterval)timeInterval target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats {
    
    if (self = [super init]) {
        LLProxy *targetProxy = [LLProxy alloc];
        targetProxy.target = target;
        self.timer = [NSTimer timerWithTimeInterval:timeInterval target:targetProxy selector:selector userInfo:userInfo repeats:repeats];
        [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    return self;
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval target:(id)target selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats {
    return [[self alloc]initWithTimeInterval:timeInterval target:target selector:selector userInfo:userInfo repeats:repeats];
}

+ (instancetype)timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(void))block {
    LLWeakTimer *weakTimer = [[LLWeakTimer alloc]init];
    weakTimer.timerBlock = block;
    LLProxy *targetProxy = [LLProxy alloc];
    targetProxy.target = weakTimer;
    weakTimer.timer = [NSTimer timerWithTimeInterval:interval target:targetProxy selector:@selector(blockTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:weakTimer.timer forMode:NSRunLoopCommonModes];
    return weakTimer;
}

- (void)blockTimer {
    
    if (self.timerBlock) {
        self.timerBlock();
    }
}

- (void)dealloc {
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    NSLog(@"LLWeakTimer dealloc");
}

@end
