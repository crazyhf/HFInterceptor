//
//  HFInterceptObj.h
//  HFInterceptor
//
//  Created by crazylhf on 16/7/6.
//  Copyright © 2016年 crazylhf. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, HFInterceptOption) {
    HFIntercept_TAIL,
    HFIntercept_HEAD,
    HFIntercept_REPLACE,
};

typedef void(^HFIntercept_block_t)(NSInvocation * oriInvocation);


///================================================================
#pragma mark - intercept information

@interface HFInterceptObj : NSObject

@property (nonatomic, assign) HFInterceptOption option;

@property (nonatomic, strong) HFIntercept_block_t block;

@end


@interface HFInterceptObjList : NSObject

@property (nonatomic, strong) NSArray * headList;

@property (nonatomic, strong) NSArray * tailList;

@property (nonatomic, strong) NSArray * replaceList;

@end
