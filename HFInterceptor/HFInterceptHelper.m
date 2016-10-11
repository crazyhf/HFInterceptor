//
//  HFInterceptHelper.m
//  HFInterceptor
//
//  Created by crazylhf on 16/7/6.
//  Copyright © 2016年 crazylhf. All rights reserved.
//

#import "HFInterceptHelper.h"

#import <objc/message.h>


#define HFIntercept_safeCallBlock(_block_, _call_statement_) \
            if (nil != (_block_)) _call_statement_


///================================================================
#pragma mark - utils

SEL HFIntercept_aliasSelector(SEL aSelector)
{
    return NSSelectorFromString([NSString stringWithFormat:@"intercepted_%@", NSStringFromSelector(aSelector)]);
}

NSString * HFIntercept_classAlias(Class aClass)
{
    return [NSString stringWithFormat:@"%@_Interceptor", NSStringFromClass(aClass)];
}

IMP HFIntercept_msgForward_imp(Class aClass, SEL aSelector)
{
#ifndef __arm64__
    NSMethodSignature * aSignature = [aClass instanceMethodSignatureForSelector:aSelector];
    if (aSignature.methodReturnLength > sizeof(id)) {
        return (IMP)_objc_msgForward_stret;
    }
#endif
    return _objc_msgForward;
}


///================================================================
#pragma mark - forwardInvocation implementation

static void HFIntercept_oriForwardInvocation(__unsafe_unretained id selfObj, SEL aSelector, NSInvocation * anInvocation)
{
    SEL anAliasForwardSel = HFIntercept_aliasSelector(aSelector);
    
    if (YES == class_respondsToSelector(object_getClass(selfObj), anAliasForwardSel)) {
        NSMethodSignature * anAliasForwardSig = [selfObj methodSignatureForSelector:anAliasForwardSel];
        NSInvocation * anAliasForwardInv = [NSInvocation invocationWithMethodSignature:anAliasForwardSig];
        
        anAliasForwardInv.target   = selfObj;
        anAliasForwardInv.selector = anAliasForwardSel;
        [anAliasForwardInv setArgument:&anInvocation atIndex:2];
        
        [anAliasForwardInv invoke];
    } else {
        [selfObj doesNotRecognizeSelector:anInvocation.selector];
    }
}

void HFIntercept_forwardInvocation(__unsafe_unretained id selfObj, SEL aSelector, NSInvocation * anInvocation)
{
    SEL anOriInvSel   = anInvocation.selector;
    SEL anAliasInvSel = HFIntercept_aliasSelector(anOriInvSel);
    
    anInvocation.selector = anAliasInvSel;
    
    HFInterceptObjList * insObjList = HFIntercept_getAssociateInfo(selfObj, anOriInvSel);
    HFInterceptObjList * clsObjLsit = HFIntercept_getAssociateInfo(object_getClass(selfObj), anOriInvSel);
    
    if (0 != insObjList.headList.count || 0 != clsObjLsit.headList.count) {
        for (HFInterceptObj * anInterceptObj in insObjList.headList) {
            HFIntercept_safeCallBlock(anInterceptObj.block, anInterceptObj.block(anInvocation));
        }
        for (HFInterceptObj * anInterceptObj in clsObjLsit.headList) {
            HFIntercept_safeCallBlock(anInterceptObj.block, anInterceptObj.block(anInvocation));
        }
    }
    
    BOOL callOriForwardInv = YES;
    
    if (0 != insObjList.replaceList.count || 0 != clsObjLsit.replaceList.count) {
        callOriForwardInv = NO;
        for (HFInterceptObj * anInterceptObj in insObjList.replaceList) {
            HFIntercept_safeCallBlock(anInterceptObj.block, anInterceptObj.block(anInvocation));
        }
        for (HFInterceptObj * anInterceptObj in clsObjLsit.replaceList) {
            HFIntercept_safeCallBlock(anInterceptObj.block, anInterceptObj.block(anInvocation));
        }
    } else if (YES == class_respondsToSelector(object_getClass(selfObj), anAliasInvSel)) {
        callOriForwardInv = NO;
        [anInvocation invoke];
    }
    
    if (0 != insObjList.tailList.count || 0 != clsObjLsit.tailList.count) {
        for (HFInterceptObj * anInterceptObj in insObjList.tailList) {
            HFIntercept_safeCallBlock(anInterceptObj.block, anInterceptObj.block(anInvocation));
        }
        for (HFInterceptObj * anInterceptObj in clsObjLsit.tailList) {
            HFIntercept_safeCallBlock(anInterceptObj.block, anInterceptObj.block(anInvocation));
        }
    }
    
    anInvocation.selector = anOriInvSel;
    
    if (YES == callOriForwardInv) {
        HFIntercept_oriForwardInvocation(selfObj, aSelector, anInvocation);
    }
}


///================================================================
#pragma mark - associate intercept information

void HFIntercept_setAssociateInfo(id anInstance, SEL aSelector, HFInterceptOption anOption, HFIntercept_block_t aBlock)
{
    if (nil == anInstance || nil == aSelector) return;
    
    SEL anAliasSel = HFIntercept_aliasSelector(aSelector);
    
    HFInterceptObjList * anObjList = HFIntercept_getAssociateInfo(anInstance, aSelector);
    if (nil == anObjList) {
        anObjList = [[HFInterceptObjList alloc] init];
        objc_setAssociatedObject(anInstance, anAliasSel, anObjList, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    HFInterceptObj * anInterceptObj = [[HFInterceptObj alloc] init];
    anInterceptObj.option = anOption;
    anInterceptObj.block  = aBlock;
    
    switch (anOption) {
        case HFIntercept_HEAD:
            if (nil == anObjList.headList) {
                anObjList.headList = @[anInterceptObj];
            } else {
                anObjList.headList = [anObjList.headList arrayByAddingObject:anInterceptObj];
            }
            break;
        case HFIntercept_TAIL:
            if (nil == anObjList.tailList) {
                anObjList.tailList = @[anInterceptObj];
            } else {
                anObjList.tailList = [anObjList.tailList arrayByAddingObject:anInterceptObj];
            }
            break;
        case HFIntercept_REPLACE:
            if (nil == anObjList.replaceList) {
                anObjList.replaceList = @[anInterceptObj];
            } else {
                anObjList.replaceList = [anObjList.replaceList arrayByAddingObject:anInterceptObj];
            }
            break;
        default: break;
    }
}

HFInterceptObjList * HFIntercept_getAssociateInfo(id anInstance, SEL aSelector)
{
    if (nil == anInstance || nil == aSelector) return nil;
    
    SEL anAliasSel = HFIntercept_aliasSelector(aSelector);
    
    return objc_getAssociatedObject(anInstance, anAliasSel);
}


