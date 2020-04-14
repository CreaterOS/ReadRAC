//
//  RACTargetQueueScheduler.m
//  ReactiveCocoa
//
//  Created by Josh Abernathy on 6/6/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACTargetQueueScheduler.h"
#import "RACBacktrace.h"
#import "RACQueueScheduler+Subclass.h"

@implementation RACTargetQueueScheduler

#pragma mark Lifecycle

- (id)initWithName:(NSString *)name targetQueue:(dispatch_queue_t)targetQueue {
	NSCParameterAssert(targetQueue != NULL);

	if (name == nil) {
        /* 如果name为空，会给你个默认的名称 */
		name = [NSString stringWithFormat:@"com.ReactiveCocoa.RACTargetQueueScheduler(%s)", dispatch_queue_get_label(targetQueue)];
	}

    /* 创建一个线程 */
	dispatch_queue_t queue = dispatch_queue_create(name.UTF8String, DISPATCH_QUEUE_SERIAL);
	if (queue == NULL) return nil;

	dispatch_set_target_queue(queue, targetQueue);

	self = [super initWithName:name queue:queue];
	if (self == nil) return nil;

    /* 释放线程GCD */
	dispatch_release(queue);

    /* 线程信息由self保存 */
	return self;
}

@end
