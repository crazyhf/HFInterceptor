//
//  NSObject+Interceptor.h
//  HFInterceptor
//
//  Created by crazylhf on 16/7/6.
//  Copyright © 2016年 crazylhf. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HFInterceptHelper.h"


@interface NSObject (Interceptor)

+ (void)interceptClsSel:(SEL)aSelector
                 option:(HFInterceptOption)anOption
             usingBlock:(HFIntercept_block_t)usingBlock;

+ (void)interceptInsSel:(SEL)aSelector
                 option:(HFInterceptOption)anOption
             usingBlock:(HFIntercept_block_t)usingBlock;

- (void)interceptInsSel:(SEL)aSelector
                 option:(HFInterceptOption)anOption
             usingBlock:(HFIntercept_block_t)usingBlock;

@end
