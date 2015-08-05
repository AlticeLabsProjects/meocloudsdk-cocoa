//
//  CLDItem+Private.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 02/07/14.
//
//

#import <MEOCloudSDK/CLDItem.h>

@interface CLDItem (Private)
@property (readonly, strong, nonatomic) NSURL *uploadURL;
+ (instancetype)itemWithDictionary:(NSDictionary *)dictionary session:(CLDSession *)session;
- (NSString *)trimmedPath;
@end