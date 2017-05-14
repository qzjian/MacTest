//
//  ZJTaskDispatchManager.h
//  runloopTest
//
//  Created by qzjian on 2017/4/3.
//  Copyright © 2017年 qzjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZJRunLoopSource.h"

@interface ZJTaskDispatchManager : NSObject<ZJRunLoopSourceProvider>

- (instancetype)initWithConcurrentNumber:(NSUInteger)num;

- (void)addTaskBlock:(TaskBlock)block;

- (void)setConccurrentNum:(NSUInteger)num;

- (void)addTaskBlockToMainQueue:(TaskBlock)block;


@end
