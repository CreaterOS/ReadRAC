//
//  RACDisposable.m
//  ReactiveCocoa
//
//  Created by Josh Abernathy on 3/16/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACDisposable.h"
#import "RACScopedDisposable.h"
#import <libkern/OSAtomic.h>

@interface RACDisposable () {
	// A copied block of type void (^)(void) containing the logic for disposal,
	// a pointer to `self` if no logic should be performed upon disposal, or
	// NULL if the receiver is already disposed.
	//
	// This should only be used atomically.
	void * volatile _disposeBlock;
}

@end

@implementation RACDisposable

#pragma mark Properties

- (BOOL)isDisposed {
	return _disposeBlock == NULL;
}

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if (self == nil) return nil;

	_disposeBlock = (__bridge void *)self;
	OSMemoryBarrier();

	return self;
}

- (id)initWithBlock:(void (^)(void))block {
	NSCParameterAssert(block != nil);

	self = [super init];
	if (self == nil) return nil;

	_disposeBlock = (void *)CFBridgingRetain([block copy]);
    /* 内存障碍 -- 用于将barrier之前和barrier之后的内存操作分开，OSMemoryBarrier可用于读写操作 */
	OSMemoryBarrier();

	return self;
}

+ (instancetype)disposableWithBlock:(void (^)(void))block {
	return [[self alloc] initWithBlock:block];
}

- (void)dealloc {
	if (_disposeBlock == NULL || _disposeBlock == (__bridge void *)self) return;

	CFRelease(_disposeBlock);
	_disposeBlock = NULL;
}

#pragma mark Disposal

/**
 * 销毁
 */
- (void)dispose {
    /* 声明一个无返回值的Block，无参数Block */
	void (^disposeBlock)(void) = NULL;

	while (YES) {
		void *blockPtr = _disposeBlock;
        /* OSAtomicCompareAndSwapPtrBarrier -- 比较oldValue ptr and theValue ptr 的指针内存地址是否相同，如果相同则返回True，否则，返回False。并且，会将newValue赋给theValue指针指向的地址 */
        /*
           bool    OSAtomicCompareAndSwapPtrBarrier( void *__oldValue, void *__newValue, void * volatile *__theValue );
         */
		if (OSAtomicCompareAndSwapPtrBarrier(blockPtr, NULL, &_disposeBlock)) {
            /* 如果blockPtr指向的指针和disposeBlock指向的指针地址是相同的，则将disposeBlock所指向的指针地址的内容置空 */
			if (blockPtr != (__bridge void *)self) {
                /* CFBridgingRelease会导致CF实例引用计数-1 */
				disposeBlock = CFBridgingRelease(blockPtr);
			}

			break;
		}
	}

    /* 如果Block块不为空，则去执行Block块 */
	if (disposeBlock != nil) disposeBlock();
}

#pragma mark Scoped Disposables

- (RACScopedDisposable *)asScopedDisposable {
	return [RACScopedDisposable scopedDisposableWithDisposable:self];
}

@end
