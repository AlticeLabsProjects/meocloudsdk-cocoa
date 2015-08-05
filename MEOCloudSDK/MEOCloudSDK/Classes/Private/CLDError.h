//
//  CLDError.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 24/03/14.
//
//

@import Foundation;

FOUNDATION_EXPORT NSString *CLDErrorDomain;

CLDPrintableEnum(CLDErrorCode, NSInteger,
                 CLDErrorCodeUnknownError = 100,
                 CLDErrorCodeUnauthorized,
                 CLDErrorCodeAccessForbidden,
                 CLDErrorCodeInvalidResponse,
				 CLDErrorCodeTooManyRecords,
				 CLDErrorCodeOverQuota,
				 
                 CLDErrorCodeResourceNotFound,
                 CLDErrorCodeResourceAlreadyExists,
                 
                 CLDErrorCodeSessionNotLinked,
                 CLDErrorCodeSessionAlreadyLinked,
                 
                 CLDErrorCodeMissingWindow,
                 
                 CLDErrorCodeConnectionTimedOut,
                 CLDErrorCodeConnectionFailed,
                 
                 CLDErrorCodeServerCouldNotCreateThumbnail,
                 CLDErrorCodeInvalidItem,
                 CLDErrorCodeInvalidParameters,
                 CLDErrorCancelledByUser
                 );

@interface CLDError : NSError

@property (nonatomic, readonly) NSInteger statusCode;

+ (instancetype)errorWithCode:(CLDErrorCode)code;
+ (instancetype)errorWithCode:(CLDErrorCode)code userInfo:(NSDictionary *)userInfo;
+ (instancetype)errorWithCode:(CLDErrorCode)code description:(NSString *)description;
+ (instancetype)errorWithCode:(CLDErrorCode)code description:(NSString *)description failureReason:(NSString *)failureReason;

+ (NSString *)localizedFailureReasonForCode:(CLDErrorCode)code, ...;

@end
