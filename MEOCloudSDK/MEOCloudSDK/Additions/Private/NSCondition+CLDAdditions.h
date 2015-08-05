//
//  NSCondition+CLDAdditions.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 12/08/14.
//
//

#import <Foundation/Foundation.h>

@interface NSCondition (CLDAdditions)
- (void)waitUntilDate:(NSDate *)limitDate whileCondition:(BOOL(^)())conditionBlock;
- (void)waitUntilDate:(NSDate *)limitDate whileCondition:(BOOL(^)())conditionBlock timeOutBlock:(void(^)())timeOutBlock;
- (void)signalWithBlock:(void(^)())conditionBlock;
@end
