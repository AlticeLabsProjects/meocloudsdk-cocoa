//
//  MEOCloud.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 13/03/14.
//
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif


//! Project version number for MEOCloudSDK-OSX.
FOUNDATION_EXPORT double MEOCloudSDK_VersionNumber;

//! Project version string for MEOCloudSDK-OSX.
FOUNDATION_EXPORT const unsigned char MEOCloudSDK_VersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MEOCloudSDK_OSX/PublicHeader.h>

#import <MEOCloudSDK/CLDAccountUser.h>
#import <MEOCloudSDK/CLDItem.h>
#import <MEOCloudSDK/CLDLink.h>
#import <MEOCloudSDK/CLDSession.h>
#import <MEOCloudSDK/CLDSessionConfiguration.h>
#import <MEOCloudSDK/CLDSharedFolder.h>
#import <MEOCloudSDK/CLDSharedFolderUser.h>
#import <MEOCloudSDK/CLDTransfer.h>
#import <MEOCloudSDK/CLDTransferManager.h>
#import <MEOCloudSDK/CLDUser.h>

FOUNDATION_EXPORT const unsigned char MEOCloudSDKVersionString[];
FOUNDATION_EXPORT const double MEOCloudSDKVersionNumber;

FOUNDATION_EXPORT NSString *CLDErrorDomain;
typedef NS_ENUM(NSInteger, CLDErrorCode) {
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
};