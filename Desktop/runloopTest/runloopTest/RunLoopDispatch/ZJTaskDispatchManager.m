//
//  ZJTaskDispatchManager.m
//  runloopTest
//
//  Created by qzjian on 2017/4/3.
//  Copyright © 2017年 qzjian. All rights reserved.
//

#import "ZJTaskDispatchManager.h"
#import "CommandTask.h"

@interface ZJTaskDispatchManager()

@property(nonatomic, assign)NSUInteger concurrentNumbers;
@property(nonatomic, strong)NSMutableArray <ZJRunLoopSource *>*threadEntrys;
@property(nonatomic, strong)ZJRunLoopSource *mainSource;

@end

@implementation ZJTaskDispatchManager

- (ZJRunLoopSource *)mainSource{
    if (_mainSource == nil) {
        _mainSource = [[ZJRunLoopSource alloc] initWithThread:@"main"];
    }
    return _mainSource;
}


- (instancetype)initWithConcurrentNumber:(NSUInteger)num
{
    self = [super init];
    if (self){
        _concurrentNumbers = num > 4 ? 4 : num;
        _threadEntrys = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < _concurrentNumbers; i++) {
            NSString *name = [NSString stringWithFormat:@"ZJRunLoopSource_%ld",i+1];
            ZJRunLoopSource *src = [[ZJRunLoopSource alloc] initWithThread:name];
            src.sourceProvider = self;
            [_threadEntrys addObject:src];
        }
    }
    return self;
}


- (void)setConccurrentNum:(NSUInteger)num
{
    @synchronized (self) {
        NSInteger dstnum = num > 4 ? 4 : num;
        if (_concurrentNumbers != dstnum) {
            if (_concurrentNumbers < dstnum) {
                NSInteger diff = dstnum - _concurrentNumbers;
                for (NSInteger i = 0; i < diff; i++) {
                    NSString *name = [NSString stringWithFormat:@"ZJRunLoopSource_%ld",_concurrentNumbers+i+i];
                    ZJRunLoopSource *src = [[ZJRunLoopSource alloc] initWithThread:name];
                    src.sourceProvider = self;
                    [_threadEntrys addObject:src];
                }
            }else{
                NSUInteger diff = dstnum - _concurrentNumbers;
                NSMutableArray *removeArray = [NSMutableArray arrayWithCapacity:diff];
                for (NSInteger i=0; i<diff; i++) {
                    NSInteger index = _concurrentNumbers - i - 1;
                    ZJRunLoopSource * src = _threadEntrys[index];
                    [removeArray addObject:src];
                    [src invalidate];
                }
                [_threadEntrys removeObjectsInArray:removeArray];
            }
            
            _concurrentNumbers = dstnum;
        }
    }
}

- (void)addTaskBlock:(TaskBlock)block{
    CommandTask *task = [[CommandTask alloc] initWithBlock:block];
    static NSUInteger index = 0;
    NSUInteger ci = (index++)%_concurrentNumbers;
    ZJRunLoopSource *src = [_threadEntrys objectAtIndex:ci];
    [src addCommand:task];
}

- (id<RunableTask>)takeNextTask
{
    for (ZJRunLoopSource *src in _threadEntrys) {
        id<RunableTask> task = [src takeNextComamand];
        if (task) {
            NSLog(@"--> src1:%@",src);
            return task;
        }
    }
    return nil;
}

- (void)addTaskBlockToMainQueue:(TaskBlock)block{

    CommandTask *task = [[CommandTask alloc] initWithBlock:block];
    [self.mainSource addCommand:task];
}


@end
