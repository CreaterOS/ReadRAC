//
//  NSArray+RACSequenceAdditions.m
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2012-10-29.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSArray+RACSequenceAdditions.h"
#import "RACArraySequence.h"

@implementation NSArray (RACSequenceAdditions)
/* rac_sequence转换成为RACSequence -- 使用集合类似于NSArray,NSDictionary */
- (RACSequence *)rac_sequence {
	return [RACArraySequence sequenceWithArray:self offset:0];
}

@end
