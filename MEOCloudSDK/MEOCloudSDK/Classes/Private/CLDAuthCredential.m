//
//  CLDAuthCredential.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 24/03/14.
//
//

#import "CLDAuthCredential.h"

NSString * const kCLDAuthCredentialServiceName = @"CLDAuthCredentialServiceName";
static NSMutableDictionary * CLDKeychainQueryDictionaryWithIdentifier(NSString *identifier) {
    NSMutableDictionary *queryDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:(__bridge id)kSecClassGenericPassword, kSecClass, kCLDAuthCredentialServiceName, kSecAttrService, nil];
    [queryDictionary setValue:identifier forKey:(__bridge id)kSecAttrAccount];
    return queryDictionary;
}

@interface CLDAuthCredential ()
@property (readwrite, strong, nonatomic) NSString *accessToken;
@property (readwrite, strong, nonatomic) NSString *tokenType;
@property (readwrite, strong, nonatomic) NSString *refreshToken;
@property (readwrite, strong, nonatomic) NSString *scope;
@property (readwrite, strong, nonatomic) NSDate *expirationDate;
@property (readwrite, strong, nonatomic) NSString *consumerKey;
@property (readwrite, strong, nonatomic) NSString *consumerSecret;
@property (readwrite, strong, nonatomic) NSURL *callbackURL;
@property (readwrite, nonatomic, getter=isSandbox) BOOL sandbox;
@end

@implementation CLDAuthCredential

+ (instancetype)credentialWithAccessToken:(NSString *)accessToken
                                tokenType:(NSString *)tokenType
                             refreshToken:(NSString *)refreshToken
                                    scope:(NSString *)scope
                           expirationDate:(NSDate *)expirationDate
                              consumerKey:(NSString *)consumerKey
                           consumerSecret:(NSString *)consumerSecret
                              callbackURL:(NSURL *)callbackURL
                                  sandbox:(BOOL)sandbox {
    NSParameterAssert(accessToken);
    NSParameterAssert(tokenType);
    NSParameterAssert(refreshToken);
    NSParameterAssert(scope);
    NSParameterAssert(expirationDate);
    NSParameterAssert(consumerKey);
    NSParameterAssert(consumerSecret);
    NSParameterAssert(callbackURL);
    CLDAuthCredential *newCredential = [CLDAuthCredential new];
    newCredential.accessToken = accessToken;
    newCredential.tokenType = tokenType;
    newCredential.refreshToken = refreshToken;
    newCredential.scope = scope;
    newCredential.expirationDate = expirationDate;
    newCredential.consumerKey = consumerKey;
    newCredential.consumerSecret = consumerSecret;
    newCredential.callbackURL = callbackURL;
    newCredential.sandbox = sandbox;
    return newCredential;
}

#pragma mark - Storing and Retrieving

+ (CLDAuthCredential *)credentialWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *queryDictionary = CLDKeychainQueryDictionaryWithIdentifier(identifier);
    queryDictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    queryDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    
    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)queryDictionary, (CFTypeRef *)&result);
    
    CLDAuthCredential *credential = nil;
    if (status != errSecSuccess) CLDLog(@"Unable to fetch credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
    else {
        NSData *data = (__bridge_transfer NSData *)result;
        credential = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return credential;
}

+ (BOOL)storeCredential:(CLDAuthCredential *)credential withIdentifier:(NSString *)identifier {
    NSMutableDictionary *queryDictionary = CLDKeychainQueryDictionaryWithIdentifier(identifier);
    
    if (!credential) return [self deleteCredentialWithIdentifier:identifier];
    
    NSMutableDictionary *updateDictionary = [NSMutableDictionary new];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credential];
    updateDictionary[(__bridge id)kSecValueData] = data;
    
    updateDictionary[(__bridge id)kSecAttrAccessible] = (__bridge id)(kSecAttrAccessibleAlways);
    
    OSStatus status;
    BOOL exists = ([self credentialWithIdentifier:identifier] != nil);
    
    if (exists) {
        status = SecItemUpdate((__bridge CFDictionaryRef)queryDictionary, (__bridge CFDictionaryRef)updateDictionary);
    } else {
        [queryDictionary addEntriesFromDictionary:updateDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)queryDictionary, NULL);
    }
    
    if (status != errSecSuccess) CLDLog(@"Unable to %@ credential with identifier \"%@\" (Error %li)", exists ? @"update" : @"add", identifier, (long int)status);
    return (status == errSecSuccess);
}

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *queryDictionary = CLDKeychainQueryDictionaryWithIdentifier(identifier);
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDictionary);
    if (status != errSecSuccess) CLDLog(@"Unable to delete credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
    return (status == errSecSuccess);
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    _accessToken = [decoder decodeObjectForKey:@"accessToken"];
    _tokenType = [decoder decodeObjectForKey:@"tokenType"];
    _refreshToken = [decoder decodeObjectForKey:@"refreshToken"];
    _scope = [decoder decodeObjectForKey:@"scope"];
    _expirationDate = [decoder decodeObjectForKey:@"expirationDate"];
    _consumerKey = [decoder decodeObjectForKey:@"consumerKey"];
    _consumerSecret = [decoder decodeObjectForKey:@"consumerSecret"];
    _callbackURL = [decoder decodeObjectForKey:@"callbackURL"];
    _sandbox = [decoder decodeBoolForKey:@"sandbox"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.accessToken forKey:@"accessToken"];
    [encoder encodeObject:self.tokenType forKey:@"tokenType"];
    [encoder encodeObject:self.refreshToken forKey:@"refreshToken"];
    [encoder encodeObject:self.scope forKey:@"scope"];
    [encoder encodeObject:self.expirationDate forKey:@"expirationDate"];
    [encoder encodeObject:self.consumerKey forKey:@"consumerKey"];
    [encoder encodeObject:self.consumerSecret forKey:@"consumerSecret"];
    [encoder encodeObject:self.callbackURL forKey:@"callbackURL"];
    [encoder encodeBool:self.isSandbox forKey:@"sandbox"];
}

#pragma mark -

- (BOOL)isExpired {
    // We take one day off the real expiration date to make up for possible lack of server sync
    // Also, one day is perfectly fine. Shut up.
    NSDate *expirationDate = [self.expirationDate dateByAddingTimeInterval:-86400];
    return [expirationDate compare:[NSDate date]] == NSOrderedAscending;
}

- (void)updateAccessToken:(NSString *)accessToken
                tokenType:(NSString *)tokenType
             refreshToken:(NSString *)refreshToken
                    scope:(NSString *)scope
           expirationDate:(NSDate *)expirationDate {
    NSParameterAssert(accessToken);
    NSParameterAssert(tokenType);
    NSParameterAssert(refreshToken);
    NSParameterAssert(scope);
    NSParameterAssert(expirationDate);
    self.accessToken = accessToken;
    self.tokenType = tokenType;
    self.refreshToken = refreshToken;
    self.scope = scope;
    self.expirationDate = expirationDate;
}

@end
