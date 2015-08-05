//
//  CLDFolderUser.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 17/03/14.
//
//

#import "CLDSharedFolderUser.h"

@interface CLDSharedFolderUser ()
@property (readwrite, nonatomic, getter=isOwner) BOOL owner;
@property (readwrite, nonatomic, getter=isUser) BOOL user;
@property (readwrite, nonatomic) BOOL accepted;
@property (readwrite, weak, nonatomic) CLDSharedFolder *folder;
@property (readwrite, strong, nonatomic) NSString *inviteRequestId;
@property (readwrite, strong, nonatomic) NSDate *inviteRequestDate;
@end

@implementation CLDSharedFolderUser

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    _owner = [aDecoder decodeBoolForKey:@"owner"];
    _user = [aDecoder decodeBoolForKey:@"user"];
    _accepted = [aDecoder decodeBoolForKey:@"accepted"];
    _inviteRequestId = [aDecoder decodeObjectForKey:@"inviteRequestId"];
    _inviteRequestDate = [aDecoder decodeObjectForKey:@"inviteRequestDate"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeBool:self.isOwner forKey:@"owner"];
    [aCoder encodeBool:self.isUser forKey:@"user"];
    [aCoder encodeBool:self.accepted forKey:@"accepted"];
    [aCoder encodeObject:self.inviteRequestId forKey:@"inviteRequestId"];
    [aCoder encodeObject:self.inviteRequestDate forKey:@"inviteRequestDate"];
}

#pragma mark - Private methods

+ (instancetype)userWithDictionary:(NSDictionary *)dictionary {
    CLDSharedFolderUser *user = [super userWithDictionary:dictionary];
    if (user) {
        user.owner = [dictionary[@"owner"] boolValue];
        user.user = [dictionary[@"user"] boolValue];
        user.inviteRequestId = dictionary[@"req_id"];
        user.inviteRequestDate = [[NSDateFormatter serviceDateFormatter] dateFromString:dictionary[@"date"]];
    }
    return user;
}

@end
