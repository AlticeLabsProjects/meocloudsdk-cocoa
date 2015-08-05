//
//  CLDError.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 24/03/14.
//
//

#import "CLDError.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *CLDErrorDomain = @"pt.sapo.ios.meocloudsdk.ErrorDomain";
#elif TARGET_OS_MAC
NSString *CLDErrorDomain = @"pt.sapo.osx.meocloudsdk.ErrorDomain";
#endif

// strings file config
static NSString *kTableName = @"CLDError";
static NSString *kDescriptionSuffix = @"description";
static NSString *kFailureReasonSuffix = @"failureReason";
static NSString *kRecoverySuggestionSuffix = @"recoverySuggestion";

// default fallback keys
static NSString *kLocalizedDescriptionKey = @"Error";
static NSString *kLocalizedFailureReasonErrorKey = @"Could not complete operation.";
static NSString *kLocalizedRecoverySuggestionErrorKey = nil;

@implementation CLDError

#pragma mark - Status Code
- (NSInteger)statusCode {
	if (self.userInfo && self.userInfo[@"status_code"]) {
		return [self.userInfo[@"status_code"] integerValue];
	} else {
		return NSNotFound;
	}
}

#pragma mark - Returning errors...

+ (instancetype)errorWithCode:(CLDErrorCode)code
{
    return [self errorWithCode:code userInfo:nil];
}

+ (instancetype)errorWithCode:(CLDErrorCode)code userInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *uInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];
    
    NSString *msg = userInfo[NSLocalizedDescriptionKey] ?: [self localizedDescriptionForCode:code];
    if (msg) uInfo[NSLocalizedDescriptionKey] = msg;
    
    msg = userInfo[NSLocalizedFailureReasonErrorKey] ?: [self localizedFailureReasonForCode:code, nil];
    if (msg) uInfo[NSLocalizedFailureReasonErrorKey] = msg;
    
    return [CLDError errorWithDomain:CLDErrorDomain code:code userInfo:uInfo];
}

+ (instancetype)errorWithCode:(CLDErrorCode)code description:(NSString *)description {
    return [self errorWithCode:code description:description failureReason:nil];
}

+ (instancetype)errorWithCode:(CLDErrorCode)code description:(NSString *)description failureReason:(NSString *)failureReason {
    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    if (description) userInfo[NSLocalizedDescriptionKey] = description;
    if (failureReason) userInfo[NSLocalizedFailureReasonErrorKey] = failureReason;
    return [self errorWithCode:code userInfo:userInfo];
}

#pragma mark - Localized messages

+ (NSString *)localizedDescriptionForCode:(CLDErrorCode)code {
//    va_list args;
//    va_start(args, code);
//    NSString *s = [self localizedErrorMessageForCode:code suffix:kDescriptionSuffix fallbackKey:kLocalizedDescriptionKey args:args];
//    va_end(args);
//    return s;
    return CLDLocalizedString(@"Error");
}

+ (NSString *)localizedFailureReasonForCode:(CLDErrorCode)code, ... {
    va_list args;
    va_start(args, code);
    NSString *s = [self localizedErrorMessageForCode:code suffix:nil fallbackKey:kLocalizedFailureReasonErrorKey args:args];
    va_end(args);
    return s;
}

+ (NSString *)localizedErrorMessageForCode:(CLDErrorCode)code suffix:(NSString *)suffix fallbackKey:(NSString *)fallbackKey args:(va_list)argp {
    NSString *errorCodeString = CLDErrorCodeToString(code);
    NSString *key = suffix ? [NSString stringWithFormat:@"%@_%@", errorCodeString, suffix] : errorCodeString;
    NSString *format = CLDLocalizedString(key);
	if (format) format = [[NSString alloc] initWithFormat:format arguments:argp];
    return format;
}

@end
