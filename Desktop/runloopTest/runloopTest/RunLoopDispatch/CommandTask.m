//
//  CommandTask.m
//  runloopTest
//
//  Created by qzjian on 2017/3/26.
//  Copyright © 2017年 qzjian. All rights reserved.
//

#import "CommandTask.h"

@interface CommandTask()
@property(copy ,nonatomic)TaskBlock commandBlock;
@end

@implementation CommandTask

- (instancetype)initWithBlock:(TaskBlock)block{
    self = [super init];
    self.commandBlock = block;
    return self;
}

- (void)run
{
    if (self.commandBlock) {
        self.commandBlock();
    }
}

@end
