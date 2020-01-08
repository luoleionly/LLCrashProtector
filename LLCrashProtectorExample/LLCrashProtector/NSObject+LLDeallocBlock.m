//
//  NSObject+LLDeallocBlock.m
//  LLCrashProtector
//
//  Created by luolei on 2019/12/31.
//  Copyright © 2019 luolei. All rights reserved.
//

#import "NSObject+LLDeallocBlock.h"
#import <objc/runtime.h>

NSString * const SafeBlockObjectDidDeallocNotification = @"SafeBlockObjectDidDeallocNotification";

static char *safeBlockObjectHandlerKey = "SafeBlockObjectHandler";

static NSMutableDictionary *safeBlockObjects = nil;

static dispatch_queue_t shared_safeblcok_queue;

@interface SafeBlockObjectHandler : NSObject
@property (strong, nonatomic, readonly) NSString *identifier;
@property (nonatomic, copy) SafeBlockDeallocBlock deallocBlock;
- (id)initWithObject:(id)object;
@end

@implementation SafeBlockObjectHandler
@synthesize identifier = _identifier;
@synthesize deallocBlock = _deallocBlock;
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        safeBlockObjects = (NSMutableDictionary *)CFBridgingRelease(CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, NULL));
        shared_safeblcok_queue = dispatch_queue_create("com.safeblock_queue", 0);
    });
}

- (id)initWithObject:(id)object
{
    self = [super init];
    if (self)
    {
        __weak id weakObjc = object;
        CFUUIDRef u = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef s = CFUUIDCreateString(kCFAllocatorDefault, u);
        CFRelease(u);
        _identifier =  (NSString *)CFBridgingRelease(s);
        dispatch_async(shared_safeblcok_queue, ^{
            if (object) {
                [safeBlockObjects setObject:weakObjc forKey:self->_identifier];
            }
        });
    }
    
    return self;
}

- (void)dealloc
{
    NSString *tempIdentifier = [_identifier copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SafeBlockObjectDidDeallocNotification object:nil userInfo:[NSDictionary dictionaryWithObject:tempIdentifier forKey:@"identifier"]];
    
    if (_deallocBlock)
    {
        _deallocBlock(tempIdentifier,[safeBlockObjects objectForKey:tempIdentifier]);
    }
    dispatch_async(shared_safeblcok_queue, ^{
        [safeBlockObjects removeObjectForKey:tempIdentifier];
    });
    
}

@end

@implementation NSObject (SafeBlock)

- (SafeBlockObjectHandler *)safeBlockObjectHandlerCreate:(BOOL)create
{
    SafeBlockObjectHandler *handler = objc_getAssociatedObject(self, &safeBlockObjectHandlerKey);
    if (!handler && create)
    {
        handler = [[SafeBlockObjectHandler alloc] initWithObject:self];
        objc_setAssociatedObject(self, &safeBlockObjectHandlerKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return handler;
}

- (SafeBlockObjectHandler *)safeBlockObjectHandler
{
    return [self safeBlockObjectHandlerCreate:YES];
}

- (NSString *)safeBlockIdentifierCreate:(BOOL)create
{
    SafeBlockObjectHandler *handler = [self safeBlockObjectHandlerCreate:create];
    return handler.identifier;
}

- (NSString *)safeBlockIdentifier
{
    return [self safeBlockIdentifierCreate:YES];
}

- (void)setSafeBlockDeallocBlock:(SafeBlockDeallocBlock)deallocBlock;
{
    SafeBlockObjectHandler *handler = [self safeBlockObjectHandler];
    handler.deallocBlock = deallocBlock;
}

@end

id get_safe_block_object(NSString *safeBlockIdentifier)
{
        __block id obj = nil;
    
        dispatch_sync(shared_safeblcok_queue, ^{
            obj = [safeBlockObjects objectForKey:safeBlockIdentifier];
        });
    
        return obj;
}

BOOL is_safe_block_object_still_alive(NSString *safeBlockIdentifier)
{
    if (safeBlockIdentifier)
    {
        id obj = get_safe_block_object(safeBlockIdentifier);
        return (obj) != nil;
    }
    return YES;
}

void dispatch_async_safe(NSString *safeBlockIdentifier, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_async(queue, ^{
        if (is_safe_block_object_still_alive(safeBlockIdentifier))
        {
            id obj = get_safe_block_object(safeBlockIdentifier);
            block();
            obj = nil;
        }
    });
}

void dispatch_after_safe(NSString *safeBlockIdentifier, dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_after(when, queue, ^(void){
        if (is_safe_block_object_still_alive(safeBlockIdentifier))
        {
            id obj = get_safe_block_object(safeBlockIdentifier);
            block();
            obj = nil;
        }
    });
}
