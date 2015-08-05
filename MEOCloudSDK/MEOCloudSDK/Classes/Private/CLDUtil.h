//
//  CLDUtil.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 09/04/14.
//
//

@import Foundation;


@interface CLDUtil : NSObject

+ (NSBundle *)frameworkBundle;
+ (NSURL*)applicationSupportDirectory;
+ (NSString *)generateIdentifier;
+ (void)postNotificationNamed:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;
+ (void)postNotificationNamed:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo synchronous:(BOOL)synchronous;

+ (NSArray *)outstandingTasksForURLSession:(NSURLSession *)session;

@end


#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

@import AssetsLibrary;

@interface CLDUtil (Assets)

+ (ALAssetsLibrary *)assetsLibrary;

@end

#endif
