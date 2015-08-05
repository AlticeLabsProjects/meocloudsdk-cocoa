//
//  CLDSession+Private.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 13/03/14.
//
//

#import <MEOCloudSDK/CLDSession.h>

typedef NS_ENUM(NSUInteger, CLDSessionEndpoint) {
    CLDSessionEndpointPublicAPI,
    CLDSessionEndpointContentAPI
};

@interface CLDSession (Private)
@property (readonly, nonatomic) NSString *accessMode;
- (NSString *)_serviceName;
- (void)_performJSONRequest:(NSURLRequest *)request successBlock:(void(^)(id object))successBlock failureBlock:(void(^)(CLDError *error))failureBlock;
- (void)_performRequest:(NSURLRequest *)request successBlock:(void(^)(NSData *data))successBlock failureBlock:(void(^)(CLDError *error))failureBlock;
- (NSURL *)_serviceURLForEndpoint:(CLDSessionEndpoint)endpoint path:(NSString *)path;
- (NSURL *)_serviceURLForEndpoint:(CLDSessionEndpoint)endpoint path:(NSString *)path query:(NSDictionary *)queryParameters;
- (NSMutableURLRequest *)_signedMutableURLRequestWithURL:(NSURL *)url;
- (CLDError *)_errorFromStatusCode:(NSInteger)statusCode;
- (CLDError *)_errorFromStatusCode:(NSInteger)statusCode error:(NSError *)error;
- (NSData *)_postDataWithDictionary:(NSDictionary *)dictionary;
@end

///**
// Fetches an `NSURL` for a media item with the specified streaming protocol.
// 
// @param item         The item whose URL should be fetched.
// @param protocol     The desired streaming protocol.
// @param fallback     `BOOL` stating if the API should return a direct URL to the file in case the desired streaming protocol is unavailable.
// @param resultBlock  The block to be executed once the URL is fetched. This block takes two arguments: an `NSURL` containing the URL and and `NSDate` with the URL's expiration date.
// @param failureBlock The block to be executed if the URL could not be fetched. This block takes an `NSError` argument containing the error.
// @see -fetchURLForItem:resultBlock:failureBlock:
// @since 1.0
// */
//- (void)fetchStreamingURLForItem:(CLDItem *)item protocol:(CLDItemStreamingProtocol)protocol fallbackToDownload:(BOOL)fallback resultBlock:(void(^)(NSURL *url, NSDate *expireDate))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


//////////////////////////////////////////////////////////////////////////////////
///// @name Polling for updates
//////////////////////////////////////////////////////////////////////////////////
//
///**
// Starts polling the service for changes.
// 
// The session will post notifications whenever items are created, edited or removed.
// Each notification will include one or more instance of <CLDItem> in their `userInfo` property.
// 
// @note If polling has already started for this session, `failureBlock` will be called with a corresponding error.
// 
// @param resultBlock  The block to be executed once polling began. Notifications will only be posted after this.
// @param failureBlock The block to be executed if polling could not begin. This block takes an `NSError` argument containing the error.
// @since 1.0
// */
//- (void)startPollingForDeltaUpdatesWithResultBlock:(void(^)())resultBlock failureBlock:(void(^)(NSError *error))failureBlock;
//
///**
// Stops polling the service for changes.
// 
// @warning Do not call <stopPollingForDeltaUpdates> and <startPollingForDeltaUpdatesWithResultBlock:failureBlock:> repeatedly in an attempt to obtain faster updates.
// Doing so may result in denial of service for undetermined amounts of time.
// The SDK is already optimized to continuously poll the service without hitting any limits.
// 
// @since 1.0
// */
//- (void)stopPollingForDeltaUpdates;