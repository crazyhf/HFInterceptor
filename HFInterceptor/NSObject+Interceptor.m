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
    if (self == self.class) return;
    
    Method anOriMethod = NULL;
    IMP    anOriIMP    = NULL;
    
    Class  aClass  = object_getClass(self);
    
    if (NULL != (anOriMethod = class_getInstanceMethod(aClass, aSelector))
        && NULL != (anOriIMP = method_getImplementation(anOriMethod)))
    {
        HFIntercept_setAssociateInfo(self, aSelector, anOption, usingBlock);
        
        NSString * anAliasName = HFIntercept_classAlias(self.class);
        if (NO == [NSStringFromClass(aClass) isEqualToString:anAliasName])
        {
            Class anAliasClass = objc_getClass(anAliasName.UTF8String);
            if (nil == anAliasClass)
            {
                anAliasClass = objc_allocateClassPair(aClass,
                                                      anAliasName.UTF8String, 0);
                objc_registerClassPair(anAliasClass);
            }
            
            Class anOriClass = object_setClass(self, anAliasClass);
            class_replaceMethod(anAliasClass,
                                @selector(class),
                                imp_implementationWithBlock(^(id self) { return anOriClass; }),
                                "#@:");
            
            aClass = anAliasClass;
        }
        
        const char * aTypeEncoding = method_getTypeEncoding(anOriMethod);
        
        IMP aMsgForwardIMP = HFIntercept_msgForward_imp(aClass, aSelector);
        
        if (anOriIMP != aMsgForwardIMP
            && YES == class_addMethod(aClass,
                                      HFIntercept_aliasSelector(aSelector),
                                      anOriIMP, aTypeEncoding)) {
                class_replaceMethod(aClass, aSelector, aMsgForwardIMP, aTypeEncoding);
            }
        
        [aClass swizzlingForwardInvocation];
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
