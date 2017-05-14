//
//  ZJRunLoopSource.h
//  runloopTest
//
//  Created by qzjian on 2017/3/25.
//  Copyright © 2017年 qzjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RunableTask.h"

@protocol ZJRunLoopSourceProvider <NSObject>

- (id<RunableTask>)takeNextTask;

@end

@interface ZJRunLoopSource : NSObject

@property(nonatomic, weak)id<ZJRunLoopSourceProvider> sourceProvider;

- (id)initWithThread:(NSString *)threadName;

//添加需要执行的任务块
- (void)addCommand:(id<RunableTask>)taskBlock;

- (void)invalidate;

- (id<RunableTask>)takeNextComamand;

- (BOOL)isMainRunLoopSource;

@end
