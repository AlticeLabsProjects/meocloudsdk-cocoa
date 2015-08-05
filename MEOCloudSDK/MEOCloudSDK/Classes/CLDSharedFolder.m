//
//  CLDSharedFolder.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 17/03/14.
//
//

#import "CLDSharedFolder.h"

@interface CLDSharedFolder ()
@property (readwrite, strong, nonatomic) NSString *shareId;
@property (readwrite, nonatomic, getter=isOwner) BOOL owner;
@property (readwrite, strong, nonatomic) NSString *path;
@property (readwrite, strong, nonatomic) NSArray *users;
@end

@implementation CLDSharedFolder

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _shareId = [aDecoder decodeObjectForKey:@"shareId"];
    _owner = [aDecoder decodeBoolForKey:@"owner"];
    _path = [aDecoder decodeObjectForKey:@"path"];
    _users = [aDecoder decodeObjectForKey:@"users"];
    if (self.users) {
        for (CLDSharedFolderUser *user in self.users) {
            user.folder = self;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.shareId forKey:@"shareId"];
    [aCoder encodeBool:self.isOwner forKey:@"owner"];
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeObject:self.users forKey:@"users"];
}

#pragma mark - Private methods

+ (instancetype)sharedFolderWithDictionary:(NSDictionary *)dictionary {
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    CLDSharedFolder *folder = [[self alloc] init];
    folder.shareId = dictionary[@"shareid"] ?: dictionary[@"link_shareid"];
    folder.owner = [dictionary[@"is_owner"] boolValue];
    folder.path = dictionary[@"shared_folder_path"];
    
    // folders & invitees
    NSMutableArray *users = [NSMutableArray new];
    for (NSDictionary *userDictionary in dictionary[@"users"]) {
        CLDSharedFolderUser *user = [CLDSharedFolderUser userWithDictionary:userDictionary];
        user.folder = folder;
        user.accepted = YES;
        if (user) [users addObject:user];
    }
    for (NSDictionary *userDictionary in dictionary[@"invitees"]) {
        CLDSharedFolderUser *user = [CLDSharedFolderUser userWithDictionary:userDictionary];
        user.folder = folder;
        user.accepted = NO;
        if (user) [users addObject:user];
    }
    folder.users = [NSArray arrayWithArray:users];
    
    return folder;
}

@end
