//
//  NSObject+LLSafeObservation.m
//  LLCrashProtector
//
//  Created by luolei on 2019/12/31.
//  Copyright © 2019 luolei. All rights reserved.
//

#import "NSObject+LLSafeObservation.h"
#import <pthread.h>
#import <objc/runtime.h>
#import "NSObject+LLDeallocBlock.h"

static char *SafeObservationProxyKey = "SafeObservationProxyKey";

@interface SafeObservationInfo : NSObject

@end

@implementation SafeObservationInfo
{
    NSString *_keyPath;
    NSKeyValueObservingOptions _options;
    SEL _action;
    void *_context;
    SafeObservationBlock _block;
}

- (instancetype)initWithKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    return [self initWithKeyPath:keyPath options:options block:NULL action:NULL context:context];
}

- (instancetype)initWithKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(nullable SafeObservationBlock)block action:(nullable SEL)action context:(nullable void *)context {
    if (self = [super init]) {
        _block = [block copy];
        _keyPath = [keyPath copy];
        _options = options;
        _action = action;
        _context = context;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[SafeObservationInfo class]]) {
      return NO;
    }
    
    if ([[self valueForKey:@"_keyPath"] isEqualToString:[object valueForKey:@"_keyPath"]]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return [_keyPath hash];
}

@end


@interface SafeObservationProxy : NSObject

@property (nonatomic, weak) id object;
@property (nonatomic, strong) NSMapTable *observationInfoMap;  //维护表信息

@end

@implementation SafeObservationProxy
{
    pthread_mutex_t _mutex;
}

- (instancetype)initWithObject:(id)object {
    if (self = [super init]) {
        _observationInfoMap = [[NSMapTable alloc]initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:0];
        pthread_mutex_init(&_mutex, NULL);
        _object = object;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"handler dealloc");
}

- (void)lock {
    pthread_mutex_lock(&_mutex);
}

- (void)unlock {
    pthread_mutex_unlock(&_mutex);
}

- (BOOL)safe_addObserverHandle:(id)object SafeObservationInfo:(SafeObservationInfo *)observationInfo {
    if (!object || !observationInfo) {
        return NO;
    }
    [self lock];
    NSMutableSet *infos = [self.observationInfoMap objectForKey:object];
    BOOL addSuccess = NO;
    if (infos) {
        if ([infos containsObject:observationInfo]) {
            addSuccess = NO;
        } else {
            addSuccess = YES;
            [infos addObject:observationInfo];
        }
    } else {
        infos = [[NSMutableSet alloc]init];
        [self.observationInfoMap setObject:infos forKey:object];
        [infos addObject:observationInfo];
        addSuccess = YES;
    }
    [self unlock];
    return addSuccess;
}

- (BOOL) safe_removeObserverHandle:(id)object keyPath:(NSString *)keyPath {
    [self lock];
    BOOL removeSuccess = NO;
    NSMutableSet *infos = [self.observationInfoMap objectForKey:object];
    __block SafeObservationInfo *info;
    [infos enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        if([keyPath isEqualToString:[obj valueForKey:@"_keyPath"]]){
            info = (SafeObservationInfo *)obj;
            *stop = YES;
        }
    }];
    if (info) {
        [infos removeObject:info];
        removeSuccess = YES;
        if (0 == infos.count) {
            [self.observationInfoMap removeObjectForKey:object];
        }
    }
    [self unlock];
    return removeSuccess;
}

@end

@implementation NSObject (SafeObservation)

- (void)safe_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    
    if (!observer || !keyPath) {
        return;
    }
    SafeObservationInfo *observationInfo = [[SafeObservationInfo alloc]initWithKeyPath:keyPath options:options context:context];
    SafeObservationProxy *proxy = objc_getAssociatedObject(self, &SafeObservationProxyKey);
    if (!proxy) {
        proxy = [[SafeObservationProxy alloc] initWithObject:self];
        objc_setAssociatedObject(self, &SafeObservationProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    __weak typeof (observer) Wobserver = observer;
    BOOL addSuccess = [proxy safe_addObserverHandle:Wobserver SafeObservationInfo:observationInfo];
    if (addSuccess) {
        __weak typeof (self) Wself = self;
        [observer setSafeBlockDeallocBlock:^(NSString *identifier,id object) {
            if (Wself && object) {
               [Wself removeObserver:object forKeyPath:keyPath];
            }
        }];
        [self setSafeBlockDeallocBlock:^(NSString *identifier, id object) {
            if (object && Wobserver) {
              [object removeObserver:Wobserver forKeyPath:keyPath];
            }
        }];
        [self addObserver:observer forKeyPath:keyPath options:options context:context];
    }
    
}

//移除的观察者，防止重复移除

- (void)safe_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    if (!observer || !keyPath) {
        return;
    }
    SafeObservationProxy *proxy = objc_getAssociatedObject(self, &SafeObservationProxyKey);
    if (proxy) {
        BOOL removeSuccess = [proxy safe_removeObserverHandle:observer keyPath:keyPath];
        if (removeSuccess) {
            [self removeObserver:observer forKeyPath:keyPath];
        }
    }
}

@end
