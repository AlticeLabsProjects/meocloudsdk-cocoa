//
//  MCLink.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

#import "CLDLink.h"
#import "CLDItem.h"

@interface CLDLink ()
@property (readwrite, strong, nonatomic) NSString *sessionIdentifier;
@property (readwrite, nonatomic, getter = isUploadLink) BOOL uploadLink;
@property (readwrite, strong, nonatomic) NSURL *shareURL;
@property (readwrite, strong, nonatomic) NSURL *downloadURL;
@property (readwrite, strong, nonatomic) NSURL *shortURL;
@property (readwrite, strong, nonatomic) NSString *shareId;
@property (readwrite, strong, nonatomic) NSDate *expireDate;
@property (readwrite, nonatomic) NSUInteger visits;
@property (readwrite, strong, nonatomic) CLDItem *item;
@end

@implementation CLDLink

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _sessionIdentifier = [aDecoder decodeObjectForKey:@"sessionIdentifier"];
    _uploadLink = [aDecoder decodeBoolForKey:@"uploadLink"];
    _shareURL = [aDecoder decodeObjectForKey:@"shareURL"];
    _downloadURL = [aDecoder decodeObjectForKey:@"downloadURL"];
    _shortURL = [aDecoder decodeObjectForKey:@"shortURL"];
    _shareId = [aDecoder decodeObjectForKey:@"shareId"];
    _expireDate = [aDecoder decodeObjectForKey:@"expireDate"];
    _visits = [aDecoder decodeIntegerForKey:@"visits"];
    _item = [aDecoder decodeObjectForKey:@"item"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.sessionIdentifier forKey:@"sessionIdentifier"];
    [aCoder encodeBool:self.isUploadLink forKey:@"uploadLink"];
    [aCoder encodeObject:self.shareURL forKey:@"shareURL"];
    [aCoder encodeObject:self.downloadURL forKey:@"downloadURL"];
    [aCoder encodeObject:self.shortURL forKey:@"shortURL"];
    [aCoder encodeObject:self.shareId forKey:@"shareId"];
    [aCoder encodeObject:self.expireDate forKey:@"expireDate"];
    [aCoder encodeInteger:self.visits forKey:@"visits"];
    [aCoder encodeObject:self.item forKey:@"item"];
}

#pragma mark - Expire date

- (void)setExpireDate:(NSDate *)expireDate resultBlock:(void (^)())resultBlock failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(expireDate);
    NSAssert([expireDate compare:[NSDate date]] == NSOrderedDescending, @"expireDate must be in the future. :-)");
    NSParameterAssert(self.shareId);
    CLDSession *session = [CLDSession sessionWithIdentifier:self.sessionIdentifier];
    NSURL *url = [session _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"SetLinkTTL"];
    NSMutableURLRequest *request = [session _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [session _postDataWithDictionary:@{@"ttl":[NSString stringWithFormat:@"%d", (int)[expireDate timeIntervalSinceNow]],
                                                          @"shareid":self.shareId}];
    [session _performRequest:request successBlock:^(NSData *data) {
        RunBlockOnMainThread(resultBlock);
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)removeExpireDateWithResultBlock:(void(^)())resultBlock failureBlock:(void(^)(NSError *error))failureBlock
{
    CLDSession *session = [CLDSession sessionWithIdentifier:self.sessionIdentifier];
    NSURL *url = [session _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"RemoveLinkTTL"];
    NSMutableURLRequest *request = [session _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [session _postDataWithDictionary:@{@"shareid":self.shareId}];
    [session _performRequest:request successBlock:^(NSData *data) {
        RunBlockOnMainThread(resultBlock);
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

#pragma mark - ShortURL

- (void)fetchShortURLWithResultBlock:(void (^)(NSURL *))resultBlock failureBlock:(void (^)(NSError *))failureBlock {
    NSParameterAssert(self.shareId);
    CLDSession *session = [CLDSession sessionWithIdentifier:self.sessionIdentifier];
    NSURL *url = [session _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:@"ShortenLinkURL"];
    NSMutableURLRequest *request = [session _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [session _postDataWithDictionary:@{@"shareid":self.shareId}];
    [session _performJSONRequest:request successBlock:^(id object) {
        if ([object isKindOfClass:[NSDictionary class]] && object[@"url"]) {
            self.shortURL = object[@"url"];
            RunBlockOnMainThread(resultBlock, self.shortURL);
        } else {
            RunBlockOnMainThread(failureBlock, [CLDError errorWithCode:CLDErrorCodeInvalidResponse]);
        }
    } failureBlock:^(CLDError *error) {
        RunBlockOnMainThread(failureBlock, error);
    }];
}

- (void)deleteShortURLWithResultBlock:(void (^)())resultBlock failureBlock:(void (^)(NSError *))failureBlock {
    if (!self.shortURL) {
        RunBlockOnMainThread(resultBlock);
        return;
    } else {
        NSString *shortURLIdentifier = [[[self.shortURL host] componentsSeparatedByString:@"."] firstObject];
        NSString *path = [NSString stringWithFormat:@"DestroyShortURL/%@", shortURLIdentifier];
        CLDSession *session = [CLDSession sessionWithIdentifier:self.sessionIdentifier];
        NSURL *url = [session _serviceURLForEndpoint:CLDSessionEndpointPublicAPI path:path];
        NSMutableURLRequest *request = [session _signedMutableURLRequestWithURL:url];
        request.HTTPMethod = @"POST";
        [session _performJSONRequest:request successBlock:^(id object) {
            RunBlockOnMainThread(resultBlock);
        } failureBlock:^(CLDError *error) {
            RunBlockOnMainThread(failureBlock, error);
        }];
    }
}

#pragma mark - Private methods

// link from list
//{
//    "url":"https://meocloud.pt/link/48a65fea-abdb-4718-bbd9-0e271b79ff47/resigned-meostories_1.0.140627.0.ipa/",
//    "url_download": "https://cld.pt/dl/download/c25c988d-ebf0-41bf-81af-a840d75a77ed/bird.avi",
//    "shareid":"48a65fea-abdb-4718-bbd9-0e271b79ff47",
//    "expiry":1404568810,
//    "visits":2,
//    "metadata":{
//        "bytes":4956351,
//        "thumb_exists":false,
//        "rev":"9f1b6ecc-fe03-11e3-bd76-e0db550199f4",
//        "modified":"Fri, 27 Jun 2014 14:02:05 +0000",
//        "is_link":true,
//        "mime_type":"application/octet-stream",
//        "path":"/resigned-meostories_1.0.140627.0.ipa",
//        "is_dir":false,
//        "icon":"page_white.gif",
//        "root":"meocloud",
//        "client_mtime":"Fri, 27 Jun 2014 13:59:45 +0000",
//        "size":"4.73 MB"
//    }
//    "absolute_path":"/Projects/SAPO/Storyteller/IPAs/release/resigned-meostories_1.0.140627.0.ipa",
//    "path":"/resigned-meostories_1.0.140627.0.ipa",
//}

// link just created
//{
//    "url": "https://meocloud.pt/link/c25c988d-ebf0-41bf-81af-a840d75a77ed/bird.avi/",
//    "url_download": "https://cld.pt/dl/download/c25c988d-ebf0-41bf-81af-a840d75a77ed/bird.avi",
//    "link_shareid": "c25c988d-ebf0-41bf-81af-a840d75a77ed",
//    "expires": "Sat, 01 Jan 3042 00:00:00 +0000"
//}

+ (instancetype)linkWithDictionary:(NSDictionary *)dictionary session:(CLDSession *)session {
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    
    CLDLink *link = [self new];
    link.sessionIdentifier = session.sessionIdentifier;
    link.uploadLink = NO;
    
    link.shareURL = [NSURL URLWithString:dictionary[@"url"]];
    link.downloadURL = [NSURL URLWithString:dictionary[@"url_download"]];
    
    if (dictionary[@"shorturl"]) link.shortURL = [NSURL URLWithString:dictionary[@"shorturl"]];
    else if (dictionary[@"short_url"]) link.shortURL = [NSURL URLWithString:dictionary[@"short_url"]];
    else if (dictionary[@"url_short"]) link.shortURL = [NSURL URLWithString:dictionary[@"url_short"]];
    
    link.shareId = dictionary[@"shareid"];
    if (dictionary[@"expires"]) {
        link.expireDate = [[NSDateFormatter serviceDateFormatter] dateFromString:dictionary[@"expires"]];
    } else if (dictionary[@"expiry"]) {
        link.expireDate = [NSDate dateWithTimeIntervalSince1970:[dictionary[@"expiry"] doubleValue]];
    }
    link.visits = [dictionary[@"visits"] unsignedIntegerValue];
    if (dictionary[@"metadata"]) {
        link.item = [CLDItem itemWithDictionary:dictionary[@"metadata"] session:session];
    } else if (dictionary[@"absolute_path"]) {
        link.item = [CLDItem itemWithPath:dictionary[@"absolute_path"]];
    }
    
    return link;
}

+ (instancetype)uploadLinkWithDictionary:(NSDictionary *)dictionary session:(CLDSession *)session {
    CLDLink *link = [self linkWithDictionary:dictionary session:session];
    link.uploadLink = YES;
    return link;
}

@end
