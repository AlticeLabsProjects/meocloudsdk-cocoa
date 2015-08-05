//
//  CLDSessionConfiguration.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 16/07/14.
//
//

#import "CLDSessionConfiguration.h"

@interface CLDSessionConfiguration ()
@property (readwrite, strong, nonatomic) NSString *consumerKey;
@property (readwrite, strong, nonatomic) NSString *consumerSecret;
@property (readwrite, strong, nonatomic) NSURL *callbackURL;
@property (readwrite, nonatomic, getter=isSandbox) BOOL sandbox;
@end

@implementation CLDSessionConfiguration

+ (instancetype)configurationWithConsumerKey:(NSString *)consumerKey
                              consumerSecret:(NSString *)consumerSecret
                                 callbackURL:(NSURL *)callbackURL
                                     sandbox:(BOOL)isSandbox {
    NSParameterAssert(consumerKey);
    NSParameterAssert(consumerSecret);
    NSParameterAssert(callbackURL);
    CLDSessionConfiguration *configuration = [self new];
    if (configuration) {
        configuration.consumerKey = consumerKey;
        configuration.consumerSecret = consumerSecret;
        configuration.callbackURL = callbackURL;
        configuration.sandbox = isSandbox;
    }
    return configuration;
}

@end
