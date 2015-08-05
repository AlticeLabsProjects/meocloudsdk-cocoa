//
//  CLDSessionConfiguration.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 16/07/14.
//
//

#import <Foundation/Foundation.h>

/**
 This class is used to hold configuration settings for instances of `CLDSession`.
 */
@interface CLDSessionConfiguration : NSObject

/**
 Default method for creating a session configuration.
 
 @param consumerKey      The API consumer key.
 @param consumerSecret   The API consumer secret.
 @param callbackURL      The callbackURL to be used when authenticating over OAuth 2.0.
 @param isSandbox          `BOOL` stating if this session should access the API in sandbox mode. This must match what was defined
 in your app details (<https://meocloud.pt/my_apps>).
 @since 1.0
 */
+ (instancetype)configurationWithConsumerKey:(NSString *)consumerKey
                              consumerSecret:(NSString *)consumerSecret
                                 callbackURL:(NSURL *)callbackURL
                                     sandbox:(BOOL)isSandbox;

/**
 The API consumer key.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *consumerKey;

/**
 The API consumer secret.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *consumerSecret;

/**
 The callbackURL to be used when authenticating over OAuth 2.0.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSURL *callbackURL;

/**
 `BOOL` stating if this session should access the API in sandbox mode. This must match what was defined
 in your app details (<https://meocloud.pt/my_apps>).
 @since 1.0
 */
@property (readonly, nonatomic, getter=isSandbox) BOOL sandbox;

@end
