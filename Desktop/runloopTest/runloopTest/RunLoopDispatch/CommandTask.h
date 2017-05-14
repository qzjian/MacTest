//
//  CommandTask.h
//  runloopTest
//
//  Created by qzjian on 2017/3/26.
//  Copyright © 2017年 qzjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunableTask.h"

@interface CommandTask : NSObject<RunableTask>

- (instancetype)initWithBlock:(TaskBlock)block;

@end
