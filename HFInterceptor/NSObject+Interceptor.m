//
//  NSObject+Interceptor.m
//  HFInterceptor
//
//  Created by crazylhf on 16/7/6.
//  Copyright © 2016年 crazylhf. All rights reserved.
//

#import "NSObject+Interceptor.h"

#import <objc/runtime.h>


@implementation NSObject (Interceptor)

+ (void)interceptClsSel:(SEL)aSelector
                 option:(HFInterceptOption)anOption
             usingBlock:(HFIntercept_block_t)usingBlock
{
    [object_getClass(self) interceptInsSel:aSelector option:anOption usingBlock:usingBlock];
}

+ (void)interceptInsSel:(SEL)aSelector
                 option:(HFInterceptOption)anOption
             usingBlock:(HFIntercept_block_t)usingBlock
{
    Method anOriMethod = NULL;
    IMP    anOriIMP    = NULL;
    
    if (NULL != (anOriMethod = class_getInstanceMethod(self, aSelector))
        && NULL != (anOriIMP = method_getImplementation(anOriMethod)))
    {
        HFIntercept_setAssociateInfo(self, aSelector, anOption, usingBlock);
        
        const char * aTypeEncoding = method_getTypeEncoding(anOriMethod);
        
        IMP aMsgForwardIMP = HFIntercept_msgForward_imp(self, aSelector);
        
        if (anOriIMP != aMsgForwardIMP
            && YES == class_addMethod(self,
                                      HFIntercept_aliasSelector(aSelector),
                                      anOriIMP, aTypeEncoding)) {
            class_replaceMethod(self, aSelector, aMsgForwardIMP, aTypeEncoding);
        }
        
        [self swizzlingForwardInvocation];
    }
}

- (void)interceptInsSel:(SEL)aSelector
                 option:(HFInterceptOption)anOption
             usingBlock:(HFIntercept_block_t)usingBlock
{
    Method anOriMethod = NULL;
    IMP    anOriIMP    = NULL;
    
    if (NULL != (anOriMethod = class_getInstanceMethod(self.class, aSelector))
        && NULL != (anOriIMP = method_getImplementation(anOriMethod)))
    {
        HFIntercept_setAssociateInfo(self, aSelector, anOption, usingBlock);
        
        Class aClass = objc_allocateClassPair(self.class, HFIntercept_classAlias(self.class).UTF8String, 0);
        objc_registerClassPair(aClass);
        object_setClass(self, aClass);
        
        const char * aTypeEncoding = method_getTypeEncoding(anOriMethod);
        
        IMP aMsgForwardIMP = HFIntercept_msgForward_imp(self.class, aSelector);
        
        if (anOriIMP != aMsgForwardIMP
            && YES == class_addMethod(self.class,
                                      HFIntercept_aliasSelector(aSelector),
                                      anOriIMP, aTypeEncoding)) {
            class_replaceMethod(self.class, aSelector, aMsgForwardIMP, aTypeEncoding);
        }
        
        [self.class swizzlingForwardInvocation];
    }
}


#pragma mark - swizzling forwardInvocation

+ (void)swizzlingForwardInvocation
{
    SEL anOriForwardSel = @selector(forwardInvocation:);
    SEL anAliasForwardSel = HFIntercept_aliasSelector(anOriForwardSel);
    
    if (YES == [self instancesRespondToSelector:anAliasForwardSel]) {
        return;
    }
    
    IMP anOriForwardIMP = class_getMethodImplementation(self, anOriForwardSel);
    
    if (NULL != anOriForwardIMP
        && (IMP)HFIntercept_forwardInvocation != anOriForwardIMP)
    {
        class_addMethod(self, anAliasForwardSel, anOriForwardIMP, "v@:@");
    }
    
    if ((IMP)HFIntercept_forwardInvocation != anOriForwardIMP) {
        class_replaceMethod(self, anOriForwardSel, (IMP)HFIntercept_forwardInvocation, "v@:@");
    }
}

@end
