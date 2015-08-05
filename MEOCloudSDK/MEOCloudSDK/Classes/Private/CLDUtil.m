//
//  CLDUtil.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 09/04/14.
//
//

#import "CLDUtil.h"

@implementation CLDUtil


+ (NSBundle *)frameworkBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"MEOCloudSDK.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return frameworkBundle;
}

+ (NSURL *)applicationSupportDirectory
{
    static NSURL *dirPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
        NSFileManager *fm = [NSFileManager defaultManager];
        
        // Find the application support directory in the home directory.
        NSArray* appSupportDir = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        if ([appSupportDir count] > 0)
        {
            // Append the bundle ID to the URL for the Application Support directory
            dirPath = [[appSupportDir objectAtIndex:0] URLByAppendingPathComponent:bundleID];
            
            // If the directory does not exist, this method creates it.
            // This method call works in OS X 10.7 and later only.
            NSError *error = nil;
            [fm createDirectoryAtURL:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
            NSAssert(error == nil, @"Could not create app directory in Application Support. Error: %@", error.description);
        }
    });
    return dirPath;
}

+ (NSString *)generateIdentifier {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

+ (void)postNotificationNamed:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    [self postNotificationNamed:aName object:anObject userInfo:aUserInfo synchronous:NO];
}

+ (void)postNotificationNamed:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo synchronous:(BOOL)synchronous {
    void(^notificationBlock)() = ^() {
        [[NSNotificationCenter defaultCenter] postNotificationName:aName object:anObject userInfo:aUserInfo];
    };
    if (synchronous) RunBlockSynchronouslyOnMainThread(notificationBlock);
    else RunBlockOnMainThread(notificationBlock);
}

+ (NSArray *)outstandingTasksForURLSession:(NSURLSession *)session {
    NSCondition *condition = [NSCondition new];
    
    NSMutableArray *_tasks = [NSMutableArray new];
    __block BOOL finishedFetch = NO;
    
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        [condition signalWithBlock:^{
            [_tasks addObjectsFromArray:dataTasks];
            [_tasks addObjectsFromArray:uploadTasks];
            [_tasks addObjectsFromArray:downloadTasks];
            finishedFetch = YES;
        }];
    }];
    
    // wait until tasks are fetched
    [condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:10] whileCondition:^BOOL{ return !finishedFetch; }];
    
    return [NSArray arrayWithArray:_tasks];
}

@end

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

@implementation CLDUtil (Assets)

+ (ALAssetsLibrary *)assetsLibrary {
    static ALAssetsLibrary *assetsLibrary = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    });
    return assetsLibrary;
}


@end

#endif