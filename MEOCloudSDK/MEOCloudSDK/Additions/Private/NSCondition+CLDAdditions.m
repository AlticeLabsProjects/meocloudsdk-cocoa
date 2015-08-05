//
//  NSCondition+CLDAdditions.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 12/08/14.
//
//

#import "NSCondition+CLDAdditions.h"

@implementation NSCondition (CLDAdditions)

- (void)waitUntilDate:(NSDate *)limitDate whileCondition:(BOOL(^)())conditionBlock {
    [self waitUntilDate:limitDate whileCondition:conditionBlock timeOutBlock:NULL];
}

- (void)waitUntilDate:(NSDate *)limitDate whileCondition:(BOOL(^)())conditionBlock timeOutBlock:(void(^)())timeOutBlock {
    [self lock];
    while (conditionBlock()){
        if ([limitDate compare:[NSDate date]] == NSOrderedAscending) {
            if (timeOutBlock) timeOutBlock();
            break;
        }
        [self waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    [self unlock];
}

- (void)signalWithBlock:(void(^)())conditionBlock
{
    [self lock];
    RunBlock(conditionBlock);
    [self signal];
    [self unlock];
}

@end
