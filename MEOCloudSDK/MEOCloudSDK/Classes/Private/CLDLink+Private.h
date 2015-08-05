//
//  CLDLink+Private.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 04/07/14.
//
//

#import <MEOCloudSDK/CLDLink.h>

@class CLDSession;

@interface CLDLink (Private)
+ (instancetype)linkWithDictionary:(NSDictionary *)dictionary session:(CLDSession *)session;
+ (instancetype)uploadLinkWithDictionary:(NSDictionary *)dictionary session:(CLDSession *)session;
@end