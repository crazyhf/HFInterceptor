//
//  HFInterceptHelper.h
//  HFInterceptor
//
//  Created by crazylhf on 16/7/6.
//  Copyright © 2016年 crazylhf. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HFInterceptObj.h"


///================================================================
#pragma mark - utils

FOUNDATION_EXPORT SEL HFIntercept_aliasSelector(SEL aSelector);

FOUNDATION_EXPORT NSString * HFIntercept_classAlias(Class aClass);

FOUNDATION_EXPORT IMP HFIntercept_msgForward_imp(Class aClass, SEL aSelector);


///================================================================
#pragma mark - forwardInvocation implementation

FOUNDATION_EXPORT void HFIntercept_forwardInvocation(id selfObj, SEL aSelector, NSInvocation * anInvocation);


///================================================================
#pragma mark - associate intercept information

FOUNDATION_EXPORT void HFIntercept_setAssociateInfo(id anInstance, SEL aSelector, HFInterceptOption anOption, HFIntercept_block_t aBlock);

FOUNDATION_EXPORT HFInterceptObjList * HFIntercept_getAssociateInfo(id anInstance, SEL aSelector);