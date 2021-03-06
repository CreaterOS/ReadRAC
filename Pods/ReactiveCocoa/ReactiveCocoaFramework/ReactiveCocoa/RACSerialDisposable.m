//
//  RACSerialDisposable.m
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2013-07-22.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "RACSerialDisposable.h"
#import <libkern/OSAtomic.h>

@interface RACSerialDisposable () {
	// A reference to the receiver's `disposable`. This variable must only be
	// modified atomically.
	//
	// If this is `self`, no `disposable` has been set, but the receiver has not
	// been disposed of yet. `self` is never stored retained.
	//
	// If this is `nil`, the receiver has been disposed.
	//
	// Otherwise, this is a retained reference to the inner disposable and the
	// receiver has not been disposed of yet.
	void * volatile _disposablePtr;
}

@end

@implementation RACSerialDisposable

#pragma mark Properties

- (BOOL)isDisposed {
	return _disposablePtr == nil;
}

- (RACDisposable *)disposable {
	RACDisposable *disposable = (__bridge id)_disposablePtr;
	return (disposable == self ? nil : disposable);
}

- (void)setDisposable:(RACDisposable *)disposable {
    /* 交换两个Disposable */
	[self swapInDisposable:disposable];
}

#pragma mark Lifecycle

+ (instancetype)serialDisposableWithDisposable:(RACDisposable *)disposable {
	RACSerialDisposable *serialDisposable = [[self alloc] init];
	serialDisposable.disposable = disposable;
	return serialDisposable;
}

- (id)init {
	self = [super init];
	if (self == nil) return nil;

	_disposablePtr = (__bridge void *)self;
	OSMemoryBarrier();

	return self;
}

- (id)initWithBlock:(void (^)(void))block {
	self = [self init];
	if (self == nil) return nil;

	self.disposable = [RACDisposable disposableWithBlock:block];

	return self;
}

- (void)dealloc {
	self.disposable = nil;
}

#pragma mark Inner Disposable

/**
 * 交换两个Disposable
 * 传入参数是需要交换的Disposable
 * 思考如何交换？？？
 * 交换过程就是两个需要交换内容的指针分别指向另一个对象，从而实现交换操作
 */
- (RACDisposable *)swapInDisposable:(RACDisposable *)newDisposable {
    /* self -- RACSerialDisposable */
    /* 获得自身的指针 */
	void * const selfPtr = (__bridge void *)self;

	// Only retain the new disposable if it's not `self`.
	// Take ownership before attempting the swap so that a subsequent swap
	// receives an owned reference.
    /* 如果不是“ self”，则仅保留新的一次性用品。尝试进行交换之前先取得所有权，以便后续的交换收到拥有的引用 */
	void *newDisposablePtr = selfPtr;
	if (newDisposable != nil) {
		newDisposablePtr = (void *)CFBridgingRetain(newDisposable);
	}

	void *existingDisposablePtr;
	// Keep trying while we're not disposed.
	while ((existingDisposablePtr = _disposablePtr) != NULL) {
		if (!OSAtomicCompareAndSwapPtrBarrier(existingDisposablePtr, newDisposablePtr, &_disposablePtr)) {
			continue;
		}

		// Return nil if _disposablePtr was set to self. Otherwise, release
		// the old value and return it as an object.
		if (existingDisposablePtr == selfPtr) {
			return nil;
		} else {
			return CFBridgingRelease(existingDisposablePtr);
		}
	}

	// At this point, we've found out that we were already disposed.
	[newDisposable dispose];

	// Failed to swap, clean up the ownership we took prior to the swap.
	if (newDisposable != nil) {
		CFRelease(newDisposablePtr);
	}

	return nil;
}

#pragma mark Disposal

- (void)dispose {
	void *existingDisposablePtr;

	while ((existingDisposablePtr = _disposablePtr) != NULL) {
		if (OSAtomicCompareAndSwapPtrBarrier(existingDisposablePtr, NULL, &_disposablePtr)) {
			if (existingDisposablePtr != (__bridge void *)self) {
				RACDisposable *existingDisposable = CFBridgingRelease(existingDisposablePtr);
				[existingDisposable dispose];
			}

			break;
		}
	}
}

@end
