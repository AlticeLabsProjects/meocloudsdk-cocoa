//
//  MEOCloudSDK.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 06/03/14.
//
//

#import "CLDSession.h"
#import "CLDAuthCredential.h"

#if TARGET_OS_IPHONE
#import "CLDLoginViewController.h"
#endif

@interface CLDTransferManager (CLDSession)
- (void)cancelAndRemoveAllTransfers;
@end

@interface CLDSession () <NSURLSessionTaskDelegate>
@property (readonly, nonatomic) NSString *accessMode;
@property (readwrite, strong, nonatomic) NSString *sessionIdentifier;
@property (readwrite, nonatomic, getter = isLinked) BOOL linked;
@property (readwrite, strong, nonatomic) CLDTransferManager *transferManager;
@property (readwrite, strong, nonatomic) CLDAuthCredential *credentials;
@property (readwrite, strong, nonatomic) NSURLSession *urlSession;
@property (readwrite, atomic) CLDSessionNetworkState networkState;
@end

@implementation CLDSession {
	NSUInteger _numberOfNetworkConnections;
}

#pragma mark - Private configuration

- (NSString *)_serviceName { return @"MEO Cloud"; }

- (NSString *)_authScheme { return @"https"; }
- (NSString *)_authHost { return @"meocloud.pt"; }
- (NSString *)_authAuthorizePath { return @"/oauth2/authorize"; }
- (NSString *)_authAuthorizeQuery { return @"client_id=%@&redirect_uri=%@&response_type=code"; }
- (NSString *)_authTokenPath { return @"/oauth2/token"; }

- (NSString *)_apiScheme { return @"https"; }
- (NSString *)_apiHost { return @"publicapi.meocloud.pt"; }
- (NSString *)_apiContentHost { return @"api-content.meocloud.pt"; }
- (NSString *)_apiVersion { return @"1"; }

- (NSString *)_accessModeSandbox { return @"sandbox"; }
- (NSString *)_accessModeFullAccess { return @"meocloud"; }

#pragma mark - Initialization

+ (instancetype)sessionWithIdentifier:(NSString *)identifier {
    NSParameterAssert(identifier);
    static NSHashTable *_existingSessions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _existingSessions = [NSHashTable weakObjectsHashTable];
    });
    CLDSession *session = nil;
    @synchronized(self) {
        for (CLDSession *s in _existingSessions) {
            if ([s.sessionIdentifier isEqualToString:identifier]) {
                session = s;
                break;
            }
        }
        if (session == nil) {
            session = [[self alloc] initWithSessionIdentifier:identifier];
            [_existingSessions addObject:session];
        }
    }
    return session;
}

- (instancetype)init {
    [NSException raise:NSGenericException format:@"CLDSession must be initialized with +sessionWithIdentifier:."];
    self = nil;
    return self;
}

- (instancetype)initWithSessionIdentifier:(NSString *)identifier {
    NSParameterAssert(identifier);
    self = [super init];
    if (self) {
        
        // set properties
        self.sessionIdentifier = identifier;
        
        // get credentials (if they exist)
        self.credentials = [CLDAuthCredential credentialWithIdentifier:identifier];
        
        // create NSURLSession
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 15;
        configuration.timeoutIntervalForResource = 15;
        self.urlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return ([object isKindOfClass:[self class]] && [self.sessionIdentifier isEqualToString:[object sessionIdentifier]]);
}

- (NSUInteger)hash {
    return self.sessionIdentifier.hash;
}

#pragma mark - NSURLSession

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler {
    
    // if linked, sign the new request with the user's credentials
    if (self.isLinked) {
        NSMutableURLRequest *newRequest = [request mutableCopy];
        NSURLRequest *signedRequest = [self _signedMutableURLRequestWithURL:newRequest.URL];
        for (NSString *key in signedRequest.allHTTPHeaderFields) {
            NSString *value = signedRequest.allHTTPHeaderFields[key];
            [newRequest setValue:value forHTTPHeaderField:key];
        }
        completionHandler(newRequest);
    } else {
        completionHandler(request);
    }
}

#pragma mark - Default session

static CLDSession *_defaultSession = nil;

+ (CLDSession *)defaultSession {
    return _defaultSession;
}

+ (void)setDefaultSession:(CLDSession *)session {
    @synchronized(self) {
        _defaultSession = session;
    }
}

#pragma mark - Authorization

- (void)setLinked:(BOOL)linked {
    if (_linked != linked) {
        _linked = linked;
        if (linked) {
            // Create transfer manager
            self.transferManager = [[CLDTransferManager alloc] initWithSession:self];
        } else {
            // Cancel all transfers
            [self.transferManager cancelAndRemoveAllTransfers];
            self.transferManager = nil;
        }
    }
}

- (void)setCredentials:(CLDAuthCredential *)credentials {
    _credentials = credentials;
    self.linked = (self.credentials != nil);
}

- (BOOL)isSandbox {
    return (self.credentials && self.credentials.isSandbox == YES);
}

#if TARGET_OS_IPHONE
- (void)linkSessionWithConfiguration:(CLDSessionConfiguration *)configuration
                         resultBlock:(void (^)())resultBlock
                        failureBlock:(void (^)(NSError *))failureBlock {
    if (self.isLinked) {
        RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeSessionAlreadyLinked]);
        return;
    }
    
    UIWindow *currentWindow = [UIApplication sharedApplication].keyWindow;
    if (currentWindow == nil) {
        RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeMissingWindow]);
    } else {
        CLDLoginViewController *vc = [[CLDLoginViewController alloc] initWithSession:self configuration:configuration resultBlock:^{
            [currentWindow.rootViewController dismissViewControllerAnimated:YES completion:^{
                RunBlockOnMainThread(resultBlock);
            }];
        } failureBlock:^(NSError *error) {
            if (error.code == CLDErrorCancelledByUser) {
                [currentWindow.rootViewController dismissViewControllerAnimated:YES completion:^{
                    RunBlockOnMainThread(failureBlock, error);
                }];
            }
        }];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//            nc.modalPresentationStyle = UIModalPresentationFormSheet;
//        }
        [currentWindow.rootViewController presentViewController:nc animated:YES completion:NULL];
    }
    
}

#endif

- (void)linkSessionWithConfiguration:(CLDSessionConfiguration *)configuration
                            URLBlock:(void (^)(NSURL *, CLDSessionValidateCallbackURLBlock))URLBlock
                         resultBlock:(void (^)())resultBlock
                        failureBlock:(void (^)(NSError *))failureBlock {
    if (self.isLinked) {
        RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeSessionAlreadyLinked]);
        return;
    }
    
    NSURLComponents *authorizeURLComponents = [NSURLComponents new];
    authorizeURLComponents.scheme = [self _authScheme];
    authorizeURLComponents.host = [self _authHost];
    authorizeURLComponents.path = [self _authAuthorizePath];
    authorizeURLComponents.percentEncodedQuery = [NSString stringWithFormat:[self _authAuthorizeQuery],
                                                  [self _escapedURLQueryArgumentFromString:configuration.consumerKey],
                                                  [self _escapedURLQueryArgumentFromString:configuration.callbackURL.absoluteString]];
    NSURL *authorizeURL = authorizeURLComponents.URL;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // validate callback URL block
        CLDSessionValidateCallbackURLBlock block = ^BOOL(NSURL *url){
            
            if (![[url scheme] isEqualToString:configuration.callbackURL.scheme] &&
                ![[url host] isEqualToString:configuration.callbackURL.host] &&
                ![[url path] isEqualToString:configuration.callbackURL.path]) {
                return NO;
            }
                
            // fetch code
            for (NSString *param in [url.query componentsSeparatedByString:@"&"]) {
                NSArray *elts = [param componentsSeparatedByString:@"="];
                if([elts count] < 2) continue;
                if ([elts[0] isEqualToString:@"code"]) {
                    NSString *code = elts[1];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        NSURLComponents *tokenURLComponents = [NSURLComponents new];
                        tokenURLComponents.scheme = [self _authScheme];
                        tokenURLComponents.host = [self _authHost];
                        tokenURLComponents.path = [self _authTokenPath];
                        NSURL *tokenURL = tokenURLComponents.URL;
                        
                        NSDictionary *parameters = @{@"grant_type" : @"authorization_code",
                                                     @"client_id" : configuration.consumerKey,
                                                     @"client_secret" : configuration.consumerSecret,
                                                     @"redirect_uri" : configuration.callbackURL.absoluteString,
                                                     @"code" : code};
                        NSMutableString *s = [NSMutableString new];
                        for (NSString *key in parameters) { [s appendFormat:@"%@=%@&", key, [self _escapedURLQueryArgumentFromString:parameters[key]]]; }
                        NSString *postString = [s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
                        
                        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:tokenURL];
                        request.HTTPMethod = @"POST";
                        request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
						
						[self incrementNumberOfActiveConnections];
                        [[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
							[self decrementNumberOfActiveConnections];
                            NSUInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
                            if (statusCode == 200) {
                                NSError *jsonError;
                                NSDictionary *credentialDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                if (jsonError == nil) {
                                    NSTimeInterval expireInterval = [credentialDictionary[@"expires_in"] doubleValue];
                                    NSDate *expireDate = [NSDate dateWithTimeIntervalSinceNow:expireInterval];
                                    CLDAuthCredential *credential = [CLDAuthCredential credentialWithAccessToken:credentialDictionary[@"access_token"]
                                                                                                       tokenType:credentialDictionary[@"token_type"]
                                                                                                    refreshToken:credentialDictionary[@"refresh_token"]
                                                                                                           scope:credentialDictionary[@"scope"]
                                                                                                  expirationDate:expireDate
                                                                                                     consumerKey:configuration.consumerKey
                                                                                                  consumerSecret:configuration.consumerSecret
                                                                                                     callbackURL:configuration.callbackURL
                                                                                                         sandbox:configuration.isSandbox];
                                    [CLDAuthCredential storeCredential:credential withIdentifier:self.sessionIdentifier];
                                    self.credentials = credential;
                                    
                                    RunBlockOnMainThread(resultBlock);
                                } else {
                                    RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
                                }
                            } else {
                                CLDError *e = [CLDError errorWithCode:CLDErrorCodeInvalidResponse userInfo:@{@"status_code": @(statusCode)}];
                                RunBlockOnMainThread(failureBlock, e);
                            }
                            
                        }] resume];
                        
                    });
                    return YES;
                }
            }
            return NO;
        };
        
        // call URLBlock
        if (URLBlock) {
            URLBlock(authorizeURL, block);
        }
        
    });
    
}

- (void)unlinkSessionWithResultBlock:(void (^)())resultBlock failureBlock:(void (^)(NSError *))failureBlock {
    if (self.isLinked) {
        
        // request device removal from account (fire & forget)
        NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"DisableAccessToken"];
        NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
        request.HTTPMethod = @"POST";
        [self _performJSONRequest:request successBlock:NULL failureBlock:NULL];
        
        // clear credentials
        self.credentials = nil;
        [CLDAuthCredential deleteCredentialWithIdentifier:self.sessionIdentifier];
        RunBlockOnMainThread(resultBlock);
    } else {
        RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeSessionNotLinked]);
    }
}

- (void)fetchAccountInformationWithResultBlock:(void (^)(CLDAccountUser *))resultBlock
                                  failureBlock:(void (^)(NSError *))failureBlock {
    
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"Account/Info"];
    NSURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    
    [self _performJSONRequest:request successBlock:^(NSDictionary *info) {
        CLDAccountUser *user = [CLDAccountUser userWithDictionary:info];
        if (user) {
            RunBlockOnMainThread(resultBlock, user);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
    
}

- (void)_refreshCredentialsIfNeeded {
    @synchronized(self) {
        if (!self.isLinked) return;
        if (!self.credentials.isExpired) return;
        
        NSURLComponents *tokenURLComponents = [NSURLComponents new];
        tokenURLComponents.scheme = [self _authScheme];
        tokenURLComponents.host = [self _authHost];
        tokenURLComponents.path = [self _authTokenPath];
        NSURL *tokenURL = tokenURLComponents.URL;
        
        NSDictionary *parameters = @{@"grant_type" : @"refresh_token",
                                     @"refresh_token" : self.credentials.refreshToken,
                                     @"client_id" : self.credentials.consumerKey,
                                     @"client_secret" : self.credentials.consumerSecret};
        NSMutableString *s = [NSMutableString new];
        for (NSString *key in parameters) { [s appendFormat:@"%@=%@&", key, [self _escapedURLQueryArgumentFromString:parameters[key]]]; }
        NSString *postString = [s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:tokenURL];
        request.HTTPMethod = @"POST";
        request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error) return;
        NSDictionary *credentialDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) return;
        
        NSTimeInterval expireInterval = [credentialDictionary[@"expires_in"] doubleValue];
        NSDate *expireDate = [NSDate dateWithTimeIntervalSinceNow:expireInterval];
        
        [self.credentials updateAccessToken:credentialDictionary[@"access_token"]
                                  tokenType:credentialDictionary[@"token_type"]
                               refreshToken:credentialDictionary[@"refresh_token"]
                                      scope:credentialDictionary[@"scope"]
                             expirationDate:expireDate];
        [CLDAuthCredential storeCredential:self.credentials withIdentifier:self.sessionIdentifier];
        CLDLog(@"Access token was successfully refreshed!");
    }
}










#pragma mark - Network state

- (void)incrementNumberOfActiveConnections {
    @synchronized (self) {
        _numberOfNetworkConnections++;
        if (_numberOfNetworkConnections == 1) {
            // state changed to active (atomic)
			self.networkState = CLDSessionNetworkStateActive;
        }
    }
}

- (void)decrementNumberOfActiveConnections {
    @synchronized (self) {
        if (_numberOfNetworkConnections > 0) _numberOfNetworkConnections--;
        if (_numberOfNetworkConnections == 0) {
            // state changed to inactive (atomic)
			self.networkState = CLDSessionNetworkStateInactive;
        }
    }
}










#pragma mark - Fetching item information

- (NSUInteger)itemLimit {
    if (_itemLimit == 0) _itemLimit = 10000;
    else if (_itemLimit > 25000) _itemLimit = 25000;
    return _itemLimit;
}

- (void)fetchItem:(CLDItem *)item
          options:(CLDSessionFetchItemOptions)options
      resultBlock:(void (^)(CLDItem *))resultBlock
     failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    
    BOOL listContents = (options & CLDSessionFetchItemOptionListContents) != 0;
    BOOL includeDeletedItems = (options & CLDSessionFetchItemOptionIncludeDeletedItems) != 0;
    
    NSMutableDictionary *query = [NSMutableDictionary new];
    query[@"file_limit"] = @(self.itemLimit);
    if (item.folderHash) query[@"hash"] = item.folderHash;
//    if (item.revision) query[@"rev"] = item.revision;
    query[@"list"] = listContents ? @"true" : @"false";
    query[@"include_deleted"] = includeDeletedItems ? @"true" : @"false";
    
    NSString *urlPath = [NSString stringWithFormat:@"Metadata/<mode>/%@", item.trimmedPath];
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:urlPath query:query];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDItem *newItem = [CLDItem itemWithDictionary:object session:self];
        if (newItem) {
            RunBlockOnMainThread(resultBlock, newItem);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        if (item.folderHash && error.statusCode == 304) {
            RunBlockOnMainThread(resultBlock, item);
        } else {
            RunBlockOnMainThread(failureBlock, error);
        }
    }];
}








#pragma mark - Copying items

- (void)copyItem:(CLDItem *)item
          toPath:(NSString *)path
     resultBlock:(void (^)(CLDItem *))resultBlock
    failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSParameterAssert(path);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"root"] = self.accessMode;
    parameters[@"from_path"] = item.path;
    parameters[@"to_path"] = path;
    
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointContentAPI path:@"Fileops/Copy"];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:parameters];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDItem *copiedItem = [CLDItem itemWithDictionary:object session:self];
        if (copiedItem) {
            RunBlockOnMainThread(resultBlock, copiedItem);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        if (error.statusCode == 403) {
            NSString *failureReason = [CLDError localizedFailureReasonForCode:CLDErrorCodeResourceAlreadyExists,
                                     item.type == CLDItemTypeFile ? CLDLocalizedString(@"That file") : CLDLocalizedString(@"That folder")];
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeResourceAlreadyExists
                                                              userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}]);
        } else {
            RunBlockOnMainThread(failureBlock, error);
        }
    }];
}

- (void)fetchCopyReferenceForItem:(CLDItem *)item
                      resultBlock:(void (^)(NSString *, NSDate *))resultBlock
                     failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    
    NSString *urlPath = [NSString stringWithFormat:@"CopyRef/%@/%@", self.accessMode, item.trimmedPath];
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointContentAPI path:urlPath];
    NSURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        NSString *reference = object[@"copy_ref"];
        NSDate *expireDate = [[NSDateFormatter serviceDateFormatter] dateFromString:object[@"expires"]];
        if (reference && expireDate) {
            RunBlockOnMainThread(resultBlock, reference, expireDate);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)fetchItemDetailsFromReference:(NSString *)reference
                          resultBlock:(void (^)(NSDictionary *))resultBlock
                         failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(reference);
    
    NSDictionary *queryParameters = @{@"copy_ref":reference};
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"CopyRefDetails" query:queryParameters];
    NSURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        if (object[@"is_dir"] &&
            object[@"bytes"] &&
            object[@"size"] &&
            object[@"name"] &&
            object[@"mime_type"] &&
            object[@"icon"]) {
            BOOL isDirectory = [object[@"is_dir"] boolValue];
            CLDItemType itemType = isDirectory ? CLDItemTypeFolder : CLDItemTypeFile;
            NSUInteger size = [object[@"bytes"] unsignedIntegerValue];
            NSString *sizeString = object[@"size"];
            NSString *name = object[@"name"];
            NSString *mimeType = object[@"mime_type"];
            NSString *iconName = object[@"icon"];
            NSDictionary *itemDetails = @{@"itemType":@(itemType),
                                          @"size":@(size),
                                          @"sizeString":sizeString,
                                          @"name":name,
                                          @"mimeType":mimeType,
                                          @"iconName":iconName};
            RunBlockOnMainThread(resultBlock, itemDetails);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

// Developer note: this is exactly the same as a standard copy, but it uses a copy reference instead of a path.
- (void)copyItemFromReference:(NSString *)reference
                       toPath:(NSString *)path
                  resultBlock:(void (^)(CLDItem *))resultBlock
                 failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(reference);
    NSParameterAssert(path);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"root"] = self.accessMode;
    parameters[@"from_copy_ref"] = reference;
    parameters[@"to_path"] = path;
    
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointContentAPI path:@"Fileops/Copy"];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:parameters];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDItem *copiedItem = [CLDItem itemWithDictionary:object session:self];
        if (copiedItem) {
            RunBlockOnMainThread(resultBlock, copiedItem);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        if (error.statusCode == 403) {
            NSString *failureReason = [CLDError localizedFailureReasonForCode:CLDErrorCodeResourceAlreadyExists, CLDLocalizedString(@"That file")];
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeResourceAlreadyExists
                                                              userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}]);
        } else {
            RunBlockOnMainThread(failureBlock, error);
        }
    }];
}








#pragma mark - Moving items

- (void)moveItem:(CLDItem *)item
          toPath:(NSString *)path
     resultBlock:(void (^)(CLDItem *))resultBlock
    failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSParameterAssert(path);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"root"] = self.accessMode;
    parameters[@"from_path"] = item.path;
    parameters[@"to_path"] = path;
    
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"Fileops/Move"];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:parameters];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDItem *movedItem = [CLDItem itemWithDictionary:object session:self];
        if (movedItem) {
            RunBlockOnMainThread(resultBlock, movedItem);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        if (error.statusCode == 403) {
            NSString *failureReason = [CLDError localizedFailureReasonForCode:CLDErrorCodeResourceAlreadyExists,
                                       item.type == CLDItemTypeFile ? CLDLocalizedString(@"That file") : CLDLocalizedString(@"That folder")];
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeResourceAlreadyExists
                                                              userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}]);
        } else {
            RunBlockOnMainThread(failureBlock, error);
        }
    }];
}








#pragma mark - Renaming items

- (void)renameItem:(CLDItem *)item
              name:(NSString *)name
       resultBlock:(void (^)(CLDItem *))resultBlock
      failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSParameterAssert(name);
    
    NSString *path = [item.path stringByDeletingLastPathComponent];
    path = [path stringByAppendingPathComponent:name];
    
    [self moveItem:item toPath:path resultBlock:resultBlock failureBlock:failureBlock];
}








#pragma mark - Deleting items

- (void)deleteItem:(CLDItem *)item
       resultBlock:(void (^)(CLDItem *))resultBlock
      failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"root"] = self.accessMode;
    parameters[@"path"] = item.path;
    
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"Fileops/Delete"];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:parameters];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDItem *deletedItem = [CLDItem itemWithDictionary:object session:self];
        if (deletedItem) {
            RunBlockOnMainThread(resultBlock, deletedItem);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)undeleteItem:(CLDItem *)item
         resultBlock:(void (^)(CLDItem *))resultBlock
        failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"root"] = self.accessMode;
    parameters[@"path"] = item.path;
    
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"UndeleteTree"];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:parameters];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDItem *deletedItem = [CLDItem itemWithDictionary:object session:self];
        if (deletedItem) {
            RunBlockOnMainThread(resultBlock, deletedItem);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}











#pragma mark - Creating folders

- (void)createFolderAtPath:(NSString *)path
               resultBlock:(void (^)(CLDItem *))resultBlock
              failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(path);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"root"] = self.accessMode;
    parameters[@"path"] = path;
    
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"Fileops/CreateFolder"];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:parameters];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDItem *newFolderItem = [CLDItem itemWithDictionary:object session:self];
        if (newFolderItem) {
            RunBlockOnMainThread(resultBlock, newFolderItem);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        if (error.statusCode == 403) {
            NSString *failureReason = [CLDError localizedFailureReasonForCode:CLDErrorCodeResourceAlreadyExists, CLDLocalizedString(@"That folder")];
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeResourceAlreadyExists
                                                              userInfo:@{NSLocalizedFailureReasonErrorKey : failureReason}]);
        } else {
            RunBlockOnMainThread(failureBlock, error);
        }
    }];
}











#pragma mark - Item revisions

- (void)fetchRevisionsForItem:(CLDItem *)item resultBlock:(void (^)(NSArray *))resultBlock failureBlock:(void (^)(NSError *))failureBlock {
    [self fetchRevisionsForItem:item revisionLimit:7 resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)fetchRevisionsForItem:(CLDItem *)item
                revisionLimit:(NSUInteger)limit
                  resultBlock:(void (^)(NSArray *))resultBlock
                 failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSParameterAssert(item.type == CLDItemTypeFile);
    
    NSDictionary *query = @{@"rev_limit":@(limit)};
    NSString *urlString = [NSString stringWithFormat:@"Revisions/%@/%@", self.accessMode, item.trimmedPath];
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:urlString query:query];
    NSURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        NSMutableArray *revisionItems = [NSMutableArray new];
        for (NSDictionary *itemDictionary in object) {
            CLDItem *item = [CLDItem itemWithDictionary:itemDictionary session:self];
            if (item) [revisionItems addObject:item];
        }
        RunBlockOnMainThread(resultBlock, [NSArray arrayWithArray:revisionItems]);
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)restoreItem:(CLDItem *)item
        resultBlock:(void (^)(CLDItem *))resultBlock
       failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSParameterAssert(item.revision);
    NSParameterAssert(item.type == CLDItemTypeFile);
    
    NSString *urlString = [NSString stringWithFormat:@"Restore/%@/%@", self.accessMode, item.trimmedPath];
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:urlString];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:@{@"rev":item.revision}];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDItem *restoredItem = [CLDItem itemWithDictionary:object session:self];
        if (restoredItem) {
            RunBlockOnMainThread(resultBlock, restoredItem);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeResourceNotFound]);
    }];
}











#pragma mark - Public Links

- (void)fetchPublicLinksWithResultBlock:(void (^)(NSArray *))resultBlock
                           failureBlock:(void (^)(NSError *))failureBlock {
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"ListLinks"];
    NSURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    [self _performJSONRequest:request successBlock:^(id object) {
        if ([object isKindOfClass:[NSArray class]]) {
            NSMutableArray *links = [NSMutableArray new];
            for (NSDictionary *linkDictionary in object) {
                CLDLink *link = [CLDLink linkWithDictionary:linkDictionary session:self];
                if (link) [links addObject:link];
            }
            RunBlockOnMainThread(resultBlock, [NSArray arrayWithArray:links]);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)fetchPublicLinkForItem:(CLDItem *)item
                   resultBlock:(void (^)(CLDLink *))resultBlock
                  failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSString *urlString = [NSString stringWithFormat:@"Shares/%@/%@", self.accessMode, item.trimmedPath];
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:urlString];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDLink *link = [CLDLink linkWithDictionary:object session:self];
        if (link) {
            RunBlockOnMainThread(resultBlock, link);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)deletePublicLink:(CLDLink *)link
             resultBlock:(void (^)())resultBlock
            failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(link);
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"DeleteLink"];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:@{@"shareid":link.shareId}];
    [self _performRequest:request successBlock:^(NSData *data) {
        RunBlockOnMainThread(resultBlock);
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}











#pragma mark - Upload Links (Upload2Me)

- (void)fetchUploadLinksWithResultBlock:(void (^)(NSArray *))resultBlock
                           failureBlock:(void (^)(NSError *))failureBlock {
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"ListUploadLinks"];
    NSURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    [self _performJSONRequest:request successBlock:^(id object) {
        if ([object isKindOfClass:[NSArray class]]) {
            NSMutableArray *links = [NSMutableArray new];
            for (NSDictionary *linkDictionary in object) {
                CLDLink *link = [CLDLink uploadLinkWithDictionary:linkDictionary session:self];
                if (link) [links addObject:link];
            }
            RunBlockOnMainThread(resultBlock, [NSArray arrayWithArray:links]);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)fetchUploadLinkForItem:(CLDItem *)item
                   resultBlock:(void (^)(CLDLink *))resultBlock
                  failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSParameterAssert(item.type == CLDItemTypeFolder);
    NSString *urlString = [NSString stringWithFormat:@"UploadLink/%@/%@", self.accessMode, item.trimmedPath];
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:urlString];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    [self _performJSONRequest:request successBlock:^(id object) {
        CLDLink *link = [CLDLink uploadLinkWithDictionary:object session:self];
        if (link) {
            RunBlockOnMainThread(resultBlock, link);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)deleteUploadLink:(CLDLink *)link
             resultBlock:(void (^)())resultBlock
            failureBlock:(void (^)(NSError *))failureBlock {
    [self deletePublicLink:link resultBlock:resultBlock failureBlock:failureBlock];
}











#pragma mark - Shared Folders

- (void)fetchSharedItemsWithResultBlock:(void (^)(NSArray *))resultBlock
                           failureBlock:(void (^)(NSError *))failureBlock {
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"ListSharedFolders"];
    NSURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    [self _performJSONRequest:request successBlock:^(id object) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *folders = [NSMutableArray new];
            for (NSString *shareId in object) {
                NSMutableDictionary *folderDictionary = [object[shareId] mutableCopy];
                folderDictionary[@"shareid"] = shareId;
                CLDSharedFolder *folder = [CLDSharedFolder sharedFolderWithDictionary:folderDictionary];
                if (folder) [folders addObject:folder];
            }
            RunBlockOnMainThread(resultBlock, folders);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)shareItem:(CLDItem *)item
        withEmail:(NSString *)email
      resultBlock:(void (^)(NSString *))resultBlock
     failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSParameterAssert(email);
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"ShareFolder"];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self _postDataWithDictionary:@{@"to_email":email}];
    [self _performJSONRequest:request successBlock:^(id object) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            NSString *requestId = object[@"req_id"];
            RunBlockOnMainThread(resultBlock, requestId);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}











#pragma mark - Search

- (void)searchItem:(CLDItem *)item
             query:(NSString *)query
       resultBlock:(void (^)(NSArray *))resultBlock
      failureBlock:(void (^)(NSError *))failureBlock {
    [self searchItem:item query:query limit:1000 resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)searchItem:(CLDItem *)item
             query:(NSString *)query
             limit:(NSUInteger)limit
       resultBlock:(void (^)(NSArray *))resultBlock
      failureBlock:(void (^)(NSError *))failureBlock {
    [self searchItem:item query:query limit:limit mimeType:nil resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)searchItem:(CLDItem *)item
             query:(NSString *)query
             limit:(NSUInteger)limit
          mimeType:(NSString *)mimeType
       resultBlock:(void (^)(NSArray *))resultBlock
      failureBlock:(void (^)(NSError *))failureBlock {
    [self searchItem:item query:query limit:limit mimeType:mimeType includeDeletedItems:NO resultBlock:resultBlock failureBlock:failureBlock];
}

- (void)searchItem:(CLDItem *)item
             query:(NSString *)query
             limit:(NSUInteger)limit
          mimeType:(NSString *)mimeType
includeDeletedItems:(BOOL)includeDeletedItems
       resultBlock:(void (^)(NSArray *))resultBlock
      failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(query);
    NSParameterAssert(query.length >= 3);
    NSParameterAssert(query.length <= 20);
    NSParameterAssert(limit >= 1);
    NSParameterAssert(limit <= 25000);
    NSString *urlString = [NSString stringWithFormat:@"Search/<mode>/%@", item.trimmedPath];
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:urlString];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    if (query) parameters[@"query"] = query;
    parameters[@"file_limit"] = [NSNumber numberWithUnsignedInteger:limit];
    if (mimeType) parameters[@"mime_type"] = mimeType;
    parameters[@"include_deleted"] = [NSNumber numberWithBool:includeDeletedItems];
    request.HTTPBody = [self _postDataWithDictionary:parameters];
    
    [self _performJSONRequest:request successBlock:^(id object) {
        if ([object isKindOfClass:[NSArray class]]) {
            NSMutableArray *items = [NSMutableArray new];
            for (NSDictionary *itemDictionary in object) {
                CLDItem *item = [CLDItem itemWithDictionary:itemDictionary session:self];
                if (item) [items addObject:item];
            }
            RunBlockOnMainThread(resultBlock, items);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
    
}











#pragma mark - Accessing items

- (void)fetchThumbnailForItem:(CLDItem *)item
                       format:(CLDItemThumbnailFormat)format
                         size:(CLDItemThumbnailSize)size
                   cropToSize:(BOOL)cropToSize
                  resultBlock:(void (^)(CLDImage *))resultBlock
                 failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    
    NSString *urlString = [NSString stringWithFormat:@"Thumbnails/<mode>/%@", item.trimmedPath];
    NSMutableDictionary *query = [NSMutableDictionary new];
    switch (format) {
        case CLDItemThumbnailFormatJPEG: query[@"format"] = @"jpeg"; break;
        case CLDItemThumbnailFormatPNG: query[@"format"] = @"png"; break;
    }
    switch (size) {
        case CLDItemThumbnailSizeXS: query[@"size"] = @"xs"; break;
        case CLDItemThumbnailSizeS: query[@"size"] = @"s"; break;
        case CLDItemThumbnailSizeM: query[@"size"] = @"m"; break;
        case CLDItemThumbnailSizeL: query[@"size"] = @"l"; break;
        case CLDItemThumbnailSizeXL: query[@"size"] = @"xl"; break;
    }
    query[@"crop"] = @(cropToSize);
    
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:urlString query:query];
    NSURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    
    [self _performRequest:request successBlock:^(NSData *data) {
        CLDImage *thumbnail = [[CLDImage alloc] initWithData:data];
        if (thumbnail) {
            RunBlockOnMainThread(resultBlock, thumbnail);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        if (error.statusCode == 415) {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeServerCouldNotCreateThumbnail]);
        } else {
            RunBlockOnMainThread(failureBlock, error);
        }
    }];
}

- (void)fetchURLForItem:(CLDItem *)item
    transcodeIfPossible:(BOOL)transcode
            resultBlock:(void(^)(NSURL *url, NSURL *transcodingURL, NSDate *expireDate))resultBlock
           failureBlock:(void(^)(NSError *error))failureBlock {
    NSParameterAssert(item);
    NSParameterAssert(item.type == CLDItemTypeFile);
    
    NSString *urlString = [NSString stringWithFormat:@"Media/<mode>/%@", item.trimmedPath];
    NSURL *url = [self _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:urlString];
    NSMutableURLRequest *request = [self _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    
    if (transcode) {
        NSDictionary *params = @{@"transcoding":@"true"};
        request.HTTPBody = [self _postDataWithDictionary:params];
    }
    
    [self _performJSONRequest:request successBlock:^(id object) {
        if ([object isKindOfClass:[NSDictionary class]] &&
            object[@"url"] && object[@"expires"]) {
            NSURL *url = [NSURL URLWithString:object[@"url"]];
            NSURL *transcodingURL = object[@"transcode_url"] ? [NSURL URLWithString:object[@"transcode_url"]] : nil;
            NSDate *date = [[NSDateFormatter serviceDateFormatter] dateFromString:object[@"expires"]];
            RunBlockOnMainThread(resultBlock, url, transcodingURL, date);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}











#pragma mark - Transfering files

- (CLDTransfer *)downloadItem:(CLDItem *)item
               cellularAccess:(BOOL)cellularAccess
                     priority:(CLDTransferPriority)priority
                  resultBlock:(void (^)(NSURL *))resultBlock
                 failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSError *error = nil;
    CLDTransfer *transfer = [self.transferManager scheduleDownloadForItem:item
                                                               background:NO
                                                           cellularAccess:cellularAccess
                                                                 priority:priority
                                                                    error:&error];
    if (transfer) {
        transfer.downloadResultBlock = resultBlock;
        transfer.failureBlock = failureBlock;
    } else {
        RunBlockOnMainThread(failureBlock, error);
    }
    return transfer;
}

- (CLDTransfer *)uploadItem:(CLDItem *)item
            shouldOverwrite:(BOOL)overwrite
             cellularAccess:(BOOL)cellularAccess
                   priority:(CLDTransferPriority)priority
                resultBlock:(void (^)(CLDItem *))resultBlock
               failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(item);
    NSError *error = nil;
    CLDTransfer *transfer = [self.transferManager scheduleUploadForItem:item
                                                              overwrite:overwrite
                                                             background:NO
                                                         cellularAccess:cellularAccess
                                                               priority:priority
                                                                  error:&error];
    if (transfer) {
        transfer.uploadResultBlock = resultBlock;
        transfer.failureBlock = failureBlock;
    } else {
        RunBlockOnMainThread(failureBlock, error);
    }
    return transfer;
}

- (CLDTransfer *)scheduleDownloadForItem:(CLDItem *)item
                          cellularAccess:(BOOL)cellularAccess
                                priority:(CLDTransferPriority)priority
                                   error:(NSError *__autoreleasing *)error {
    NSParameterAssert(item);
    return [self.transferManager scheduleDownloadForItem:item
                                              background:YES
                                          cellularAccess:cellularAccess
                                                priority:priority
                                                   error:&*error];
}

- (CLDTransfer *)scheduleUploadForItem:(CLDItem *)item
                       shouldOverwrite:(BOOL)overwrite
                        cellularAccess:(BOOL)cellularAccess
                              priority:(CLDTransferPriority)priority
                                 error:(NSError *__autoreleasing *)error {
    NSParameterAssert(item);
    return [self.transferManager scheduleUploadForItem:item
                                             overwrite:overwrite
                                            background:YES
                                        cellularAccess:cellularAccess
                                              priority:priority
                                                 error:&*error];
}

+ (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSString *sessionIdentifier = identifier;
    if ([sessionIdentifier hasSuffix:@"_cellularAccess"]) {
        NSRange range = [sessionIdentifier rangeOfString:@"_cellularAccess"];
        sessionIdentifier = [sessionIdentifier substringToIndex:range.location];
    }
    CLDSession *session = [self sessionWithIdentifier:sessionIdentifier];
    if (session) {
        if ([sessionIdentifier hasSuffix:@"_cellularAccess"]) {
            session.transferManager.backgroundEventsWithCellularAccessCompletionHandler = completionHandler;
        } else {
            session.transferManager.backgroundEventsCompletionHandler = completionHandler;
        }
    }
}











#pragma mark - Polling for updates

- (void)startPollingForDeltaUpdatesWithResultBlock:(void (^)())resultBlock failureBlock:(void (^)(NSError *))failureBlock {
    [NSException raise:NSGenericException format:@"startPollingForDeltaUpdatesWithResultBlock:failureBlock: is not yet implemented."];
}

- (void)stopPollingForDeltaUpdates {
    [NSException raise:NSGenericException format:@"stopPollingForDeltaUpdates is not yet implemented."];
}











#pragma mark - Private methods

// convenience method to get strings for sandbox and full access modes
- (NSString *)accessMode {
    return self.sandbox ? [self _accessModeSandbox] : [self _accessModeFullAccess];
}

// perform a service request and parse the JSON response
- (void)_performJSONRequest:(NSURLRequest *)request
              successBlock:(void(^)(id object))successBlock
              failureBlock:(void(^)(CLDError *error))failureBlock {
    [self _performRequest:request
            successBlock:^(NSData *data) {
                NSError *error = nil;
                id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                if (error == nil) {
                    RunBlock(successBlock, object);
                } else {
                    RunBlock(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
                }
            }
            failureBlock:failureBlock];
}

// perform service request with success and failure blocks
- (void)_performRequest:(NSURLRequest *)request
          successBlock:(void(^)(NSData *data))successBlock
          failureBlock:(void(^)(CLDError *error))failureBlock {
    
    if (!self.isLinked) {
        RunBlock(failureBlock, [CLDError errorWithCode:CLDErrorCodeSessionNotLinked]);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // check if the token is still valid
        [self _refreshCredentialsIfNeeded];
        
        [self incrementNumberOfActiveConnections];
        [[self.urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [self decrementNumberOfActiveConnections];
            NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            switch (statusCode) {
                case NSNotFound:
                    RunBlock(failureBlock, [CLDError errorWithCode:CLDErrorCodeUnknownError]);
                    break;
                    
                case 200:
                    RunBlock(successBlock, data);
                    break;
                    
                case 401:
                    RunBlock(failureBlock, [self _errorFromStatusCode:statusCode error:error]);
                    [self unlinkSessionWithResultBlock:NULL failureBlock:NULL];
                    break;
                    
                default:
                    RunBlock(failureBlock, [self _errorFromStatusCode:statusCode error:error]);
                    break;
            }
        }] resume];
    });
}

// generate api URL
- (NSURL *)_serviceURLForEndpoint:(CLDSessionEndpoint)endpoint path:(NSString *)path {
    return [self _serviceURLForEndpoint:endpoint path:path query:nil];
}
- (NSURL *)_serviceURLForEndpoint:(CLDSessionEndpoint)endpoint path:(NSString *)path query:(NSDictionary *)queryParameters {
    
//    path = [path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    if ([path hasPrefix:@"/"]) path = [path substringFromIndex:1];
    path = [path stringByReplacingOccurrencesOfString:@"<mode>" withString:self.accessMode];
    
    NSURLComponents *components = [NSURLComponents new];
    components.scheme = [self _apiScheme];
    components.host = (endpoint == CLDSessionEndpointPublicAPI) ? [self _apiHost] : [self _apiContentHost];
    components.path = [NSString stringWithFormat:@"/%@/%@", [self _apiVersion], path];
    
    if (queryParameters) {
        NSMutableString *query = [NSMutableString new];
        for (NSString *key in queryParameters) {
            id value = queryParameters[key];
            
            // This little dance is required for the BOOL parameters to be converted to "true" or "false" strings
            // The double comparison with bool and char is required to satisfy both iOS 7 and 8
            if ([value isKindOfClass:[NSNumber class]]) {
                char *valueType = (char*)[value objCType];
                char *boolType = (char*)@encode(BOOL);
                char *charType = (char*)@encode(char);
                if (strcmp(valueType, boolType) == 0 || strcmp(valueType, charType) == 0) {
                    value = [value boolValue]==YES ? @"true" : @"false";
                } else {
                    value = [value stringValue];
                }
            } else if ([value isKindOfClass:[NSString class]]) {
                value = [self _escapedURLQueryArgumentFromString:value];
            }
            
            [query appendFormat:@"%@=%@&", key, value];
        }
        components.percentEncodedQuery = [query stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    }
    
    return components.URL;
}

// escape string so it can be safely used in query strings
- (NSString *)_escapedURLQueryArgumentFromString:(NSString *)string {
    // Encode all the reserved characters, per RFC 3986
    // (<http://www.ietf.org/rfc/rfc3986.txt>)
    CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                  (__bridge CFStringRef)string,
                                                                  NULL,
                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                  kCFStringEncodingUTF8);
    return (__bridge_transfer NSString *) escaped;
}

// generate a signed mutable URL request
- (NSMutableURLRequest *)_signedMutableURLRequestWithURL:(NSURL *)url {
    NSParameterAssert(url);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    if (self.credentials) {
        NSString *authorization = [NSString stringWithFormat:@"%@ %@", self.credentials.tokenType, self.credentials.accessToken];
        [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    }
    return request;
}

// This method is used to generate CLDError instances for standard API error codes
- (CLDError *)_errorFromStatusCode:(NSInteger)statusCode {
    return [self _errorFromStatusCode:statusCode error:nil];
}

// This method is used to generate CLDError instances for standard API error codes
// Optional error parameter is used to attempt to figure out more information
- (CLDError *)_errorFromStatusCode:(NSInteger)statusCode error:(NSError *)error {
    CLDError *_error = nil;
    
    // let's try to figure out the error from the status code
    if (statusCode > 0 && statusCode != NSNotFound) {
        switch (statusCode) {
            case 200: break; // 200 = OK -> no error!
                //		case 400: break; // BAD REQUEST
            case 401: _error = [CLDError errorWithCode:CLDErrorCodeUnauthorized userInfo:@{@"status_code": @(statusCode)}]; break; // UNAUTHORIZED
            case 403: _error = [CLDError errorWithCode:CLDErrorCodeAccessForbidden userInfo:@{@"status_code": @(statusCode)}]; break; // FORBIDDEN
            case 404: _error = [CLDError errorWithCode:CLDErrorCodeResourceNotFound userInfo:@{@"status_code": @(statusCode)}]; break; // NOT FOUND
                //		case 405: break; // METHOD NOT ALLOWED (wrong http method)
            case 406: _error = [CLDError errorWithCode:CLDErrorCodeTooManyRecords userInfo:@{@"status_code": @(statusCode)}]; break; // NOT ACCEPTABLE (usually when there are more than 10k records)
                //		case 500: break; // INTERNAL SERVER ERROR
            case 507: _error = [CLDError errorWithCode:CLDErrorCodeOverQuota userInfo:@{@"status_code": @(statusCode)}]; break; // OVER QUOTA
            default: _error = [CLDError errorWithCode:CLDErrorCodeUnknownError userInfo:@{@"status_code": @(statusCode)}]; break;
        }
        
    } else if (error) {
        // no status code? let's see the error
        if ([error.domain isEqualToString:NSURLErrorDomain]) {
            _error = [CLDError errorWithCode:CLDErrorCodeConnectionFailed userInfo:@{NSUnderlyingErrorKey: error}];
        } else {
            _error = [CLDError errorWithCode:CLDErrorCodeUnknownError userInfo:@{NSUnderlyingErrorKey: error}];
        }
        
    } /*else {
        _error = [CLDError errorWithCode:CLDErrorCodeUnknownError];
    }*/
    
    return _error;
}

// Generate a standard POST string using an NSDictionary and converts it to NSData
- (NSData *)_postDataWithDictionary:(NSDictionary *)dictionary {
    NSMutableString *mutableString = [NSMutableString new];
    for (NSString *key in dictionary) {
        NSString *value;
        if ([dictionary[key] isKindOfClass:[NSNumber class]]) {
            if ([dictionary[key] class] == [[NSNumber numberWithBool:YES] class]) {
                value = [dictionary[key] boolValue]==YES ? @"true" : @"false";
            } else {
                value = [dictionary[key] stringValue];
            }
        } else {
            value = dictionary[key];
        }
        [mutableString appendFormat:@"%@=%@&",
         [self _escapedURLQueryArgumentFromString:key],
         [self _escapedURLQueryArgumentFromString:value]];
    }
    NSString *postString = [mutableString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    return [postString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
