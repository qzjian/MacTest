//
//  ZJRunLoopSource.m
//  runloopTest
//
//  Created by qzjian on 2017/3/25.
//  Copyright © 2017年 qzjian. All rights reserved.
//

#import "ZJRunLoopSource.h"

@interface ZJRunLoopSource()<ZJRunLoopSourceProvider>
{
    CFRunLoopSourceRef runLoopSource;
    NSMutableArray *commands;
    NSThread *assosiateThread;
    BOOL mainRunLoop;
}

@end

@implementation ZJRunLoopSource

void RunLoopSourceScheduleRoutine(void *info, CFRunLoopRef r1, CFStringRef mode){
    NSLog(@"---> RunLoopSourceScheduleRoutine");
}

void RunLoopSourcePerformRoutine (void *info)
{
    NSLog(@"---> RunLoopSourcePerformRoutine ");
    ZJRunLoopSource*  obj = (__bridge ZJRunLoopSource*)info;
    [obj sourceFiredTimely];
}


void RunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode)
{
    NSLog(@"---> RunLoopSourceCancelRoutine");
}


- (id)initWithThread:(NSString *)threadName
{
    if (assosiateThread == nil) {
        if (threadName == nil || [threadName isEqualToString:@"main"]) {
            mainRunLoop = YES;
            [self performSelectorOnMainThread:@selector(setUpRunLoop:) withObject:nil waitUntilDone:YES];
            return self;
        }
        assosiateThread = [[NSThread alloc] initWithTarget:self selector:@selector(setUpRunLoop:) object:nil];
        [assosiateThread setName:threadName];
        [assosiateThread start];
    }
    return self;
}

- (void)setUpRunLoop:(id)obj{
    
    // 创建上下文容器，其中会连接自己的 info，retain info release info，还会关联三个例行程序。
    CFRunLoopSourceContext context = {0, (__bridge void *)(self), NULL, NULL, NULL ,NULL, NULL, &RunLoopSourceScheduleRoutine, RunLoopSourceCancelRoutine, RunLoopSourcePerformRoutine};
    /** 通过索引，上下文，和CFAllocator创建source */
    runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
    commands = [[NSMutableArray alloc] init];
    [self addToRunLoop:mainRunLoop];
}

- (void)addToRunLoop:(BOOL)mainRunloop{
    CFRunLoopRef runLoopRef;
    NSRunLoop *rl ;
    if (mainRunLoop) {
        rl = [NSRunLoop mainRunLoop];
        runLoopRef = CFRunLoopGetMain();
    }else{
        rl = [NSRunLoop currentRunLoop];
        runLoopRef = CFRunLoopGetCurrent();
    }
    
    
    CFRunLoopAddSource(runLoopRef, runLoopSource, kCFRunLoopDefaultMode);
    
    // 创建一个run loop观察者对象；观察事件为每次循环的kCFRunLoopBeforeWaiting；
    CFRunLoopObserverContext  context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    CFRunLoopObserverRef  observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                             kCFRunLoopBeforeWaiting,
                                                             YES,
                                                             0,
                                                             &sourceRunLoopObserver, &context);
    if (observer)
    {
        // 添加观察者对象到该run loop上
        CFRunLoopAddObserver(runLoopRef, observer, kCFRunLoopDefaultMode);
    }
    
    BOOL shouldKeepRunning = YES;
    while (shouldKeepRunning && mainRunLoop == NO)
    {
        [rl runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

// Run loop观察者的回调函数：
void sourceRunLoopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    ZJRunLoopSource *src = (__bridge ZJRunLoopSource *)(info);
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"run loop entry");
            break;
        case kCFRunLoopBeforeTimers:{
            NSLog(@"run loop before timers");
        }
            break;
        case kCFRunLoopBeforeSources:{
            NSLog(@"run loop before sources");
            }
            break;
        case kCFRunLoopBeforeWaiting:{
            NSLog(@"run loop before waiting");
            if ([src shouldFireCommand]) {
                [src fireCommands];
            }else{
                if (![src isMainRunLoopSource]) {
                    id<RunableTask> task = [src.sourceProvider takeNextTask];
                    if (task){
                        NSLog(@"--> src2:%@",src);
                        [src addCommand:task];
                        [src fireCommands];
                    }
                }else{
                    //主队列不执行子队列任务
                }
            }
        }
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"run loop after waiting");
            break;
        case kCFRunLoopExit:
            NSLog(@"run loop exit");
            break;
        default:
            break;
    }
}

- (void)addCommand:(id<RunableTask>)taskBlock
{
    if (mainRunLoop) {
        [self performSelectorOnMainThread:@selector(coreAddCommand:) withObject:taskBlock waitUntilDone:NO];
    }else{
        [self performSelector:@selector(coreAddCommand:) onThread:assosiateThread withObject:taskBlock waitUntilDone:NO];
    }
}

- (void)coreAddCommand:(id<RunableTask>)taskBlock
{
    NSLog(@"addCommand \n");
    @synchronized (commands) {
        [commands addObject:taskBlock];
    }
}


- (id<RunableTask>)takeNextComamand{
    @synchronized (commands) {
        id<RunableTask> task = [commands firstObject];
        if (task) {
            [commands removeObjectAtIndex:0];
        }
        return task;
    }
}

- (BOOL)shouldFireCommand
{
    @synchronized (commands) {
        return commands.count > 0;
    }
}

- (BOOL)isMainRunLoopSource
{
    return mainRunLoop;
}

- (void)fireCommands
{
    NSLog(@"--> fireCommands \n");
    CFRunLoopSourceSignal(runLoopSource);
    if (mainRunLoop) {
        CFRunLoopWakeUp(CFRunLoopGetMain());
    }else{
        CFRunLoopWakeUp(CFRunLoopGetCurrent());
    }
}

- (void)sourceFiredTimely
{
    NSLog(@"sourceFired \n");
    id<RunableTask> task = [self takeNextComamand];
    [task run];
}

// 销毁
- (void)invalidate
{
    NSLog(@"invalidate \n");
    [commands removeAllObjects];
    CFRunLoopSourceInvalidate(runLoopSource);
    [assosiateThread cancel];
}

@end
