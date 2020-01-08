//
//  NSObject+LLAssociatedObject.m
//  LLCrashProtector
//
//  Created by luolei on 2019/12/31.
//  Copyright © 2019 luolei. All rights reserved.
//

#import "NSObject+LLAssociatedObject.h"

@implementation NSObject (LLAssociatedObject)
- (id)llt_objectWithAssociatedKey:(void *)key
{
    return objc_getAssociatedObject(self, key);
}

- (void)llt_setObject:(id)object forAssociatedKey:(void *)key retained:(BOOL)retain
{
    objc_setAssociatedObject(self, key, object, retain?OBJC_ASSOCIATION_RETAIN_NONATOMIC:OBJC_ASSOCIATION_ASSIGN);
}

- (void)llt_setObject:(id)object forAssociatedKey:(void *)key associationPolicy:(objc_AssociationPolicy)policy
{
    objc_setAssociatedObject(self, key, object, policy);
}   

@end
