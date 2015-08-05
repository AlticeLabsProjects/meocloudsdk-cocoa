//
//  CLDAuthCredential.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 24/03/14.
//
//

#ifndef _SECURITY_SECITEM_H_
#error Security framework not found in project, or not included in precompiled header.
#endif

@interface CLDAuthCredential : NSObject
@property (readonly, strong, nonatomic) NSString *accessToken;
@property (readonly, strong, nonatomic) NSString *tokenType;
@property (readonly, strong, nonatomic) NSString *refreshToken;
@property (readonly, strong, nonatomic) NSString *scope;
@property (readonly, strong, nonatomic) NSDate *expirationDate;
@property (readonly, strong, nonatomic) NSString *consumerKey;
@property (readonly, strong, nonatomic) NSString *consumerSecret;
@property (readonly, strong, nonatomic) NSURL *callbackURL;
@property (readonly, nonatomic, getter=isSandbox) BOOL sandbox;

/**
 Creates a new credential with the given parameters
 
 @param accessToken     The access token.
 @param tokenType       The token type.
 @param refreshToken    The refresh token.
 @param scope           The access scope.
 @param expirationDate  The token expiration date.
 @param consumerKey     The OAuth consumer key.
 @param consumerSecret  The OAuth consumer secret.
 @param callbackURL     The OAuth callback URL.
 @param sandbox         `BOOL` stating whether or not this credential was create in sandbox mode.
 
 @return A new instance of `CLDAuthCredential`.
 @since 1.0
 */
+ (instancetype)credentialWithAccessToken:(NSString *)accessToken
                                tokenType:(NSString *)tokenType
                             refreshToken:(NSString *)refreshToken
                                    scope:(NSString *)scope
                           expirationDate:(NSDate *)expirationDate
                              consumerKey:(NSString *)consumerKey
                           consumerSecret:(NSString *)consumerSecret
                              callbackURL:(NSURL *)callbackURL
                                  sandbox:(BOOL)sandbox;

/**
 Retrieves a credential with a specified identifier
 
 @param identifier The credential identifier.
 
 @return An instance of `CLDAuthCredential`
 @since 1.0
 */
+ (instancetype)credentialWithIdentifier:(NSString *)identifier;

/**
 Stores a credential in the keychain with a given identifier.
 
 @param credential The credential to store.
 @param identifier The credential identifier.
 
 @return `YES` if the credential was stored successfully.
 @since 1.0
 */
+ (BOOL)storeCredential:(CLDAuthCredential *)credential withIdentifier:(NSString *)identifier;

/**
 Deletes a credential from the keychain.
 
 @param identifier The credential identifier.
 
 @return `YES` if the credential was deleted successfully.
 @since 1.0
 */
+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier;

/**
 Checks if the access token for the credential is expired.
 
 @return `YES` if the token is expired.
 @since 1.0
 */
- (BOOL)isExpired;

/**
 Sets new authentication values for the receiver credential.
 
 @param accessToken    The access token.
 @param tokenType      The token type.
 @param refreshToken   The refresh token.
 @param scope          The access scope.
 @param expirationDate The token expiration date.
 
 @since 1.0
 */
- (void)updateAccessToken:(NSString *)accessToken
                tokenType:(NSString *)tokenType
             refreshToken:(NSString *)refreshToken
                    scope:(NSString *)scope
           expirationDate:(NSDate *)expirationDate;

@end
