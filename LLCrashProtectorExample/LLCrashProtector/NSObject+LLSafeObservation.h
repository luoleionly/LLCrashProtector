//
//  NSObject+LLSafeObservation.h
//  LLCrashProtector
//
//  Created by luolei on 2019/12/31.
//  Copyright © 2019 luolei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SafeObservationBlock)(id _Nullable observer, id _Nullable object, NSDictionary<NSKeyValueChangeKey, id> * _Nullable change);

@interface NSObject (SafeObservation)

//使用该方法不用担心观察者的移除问题，以及多次添加引起的crash问题
- (void)safe_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;

//无需主动调用该方法
- (void)safe_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;



@end

NS_ASSUME_NONNULL_END
