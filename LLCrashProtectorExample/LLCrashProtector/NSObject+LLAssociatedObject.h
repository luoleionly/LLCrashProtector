//
//  NSObject+LLAssociatedObject.h
//  LLCrashProtector
//
//  Created by luolei on 2019/12/31.
//  Copyright © 2019 luolei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/*!
 *  添加 NSObject 设置，获取关联对象的工具方法。
 */
@interface NSObject (LLAssociatedObject)
/*!
 *  取得当前对象对应key的关联对象
 *
 *  @param key 关联对象key
 *
 *  @return 对应key的关联对象
 */
- (id)llt_objectWithAssociatedKey:(void *)key;

/*!
 *  设置关联对象给对应key
 *
 *  @param object 关联对象
 *  @param key    关联对象对应key
 *  @param retain 是否要retain该对象
 */
- (void)llt_setObject:(id)object forAssociatedKey:(void *)key retained:(BOOL)retain;

/*!
 *  设置关联对象给对应key
 *
 *  @param object 关联对象
 *  @param key    关联对象对应key
 *  @param policy AssociationPolicy
 */
- (void)llt_setObject:(id)object forAssociatedKey:(void *)key associationPolicy:(objc_AssociationPolicy)policy;

@end
