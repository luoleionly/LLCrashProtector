//
//  NSObject+LLDeallocBlock.h
//  LLCrashProtector
//
//  Created by luolei on 2019/12/31.
//  Copyright © 2019 luolei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SafeBlockDeallocBlock)(NSString *identifier,id object);

extern NSString * const SafeBlockObjectDidDeallocNotification;

@interface NSObject (SafeBlock)

- (NSString *)safeBlockIdentifier;
- (NSString *)safeBlockIdentifierCreate:(BOOL)create;
- (void)setSafeBlockDeallocBlock:(SafeBlockDeallocBlock)deallocBlock;

@end

id get_safe_block_object(NSString *safeBlockIdentifier);
BOOL is_safe_block_object_still_alive(NSString *safeBlockIdentifier);
void dispatch_async_safe(NSString *safeBlockIdentifier, dispatch_queue_t queue, dispatch_block_t block);
void dispatch_after_safe(NSString *safeBlockIdentifier, dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block);
