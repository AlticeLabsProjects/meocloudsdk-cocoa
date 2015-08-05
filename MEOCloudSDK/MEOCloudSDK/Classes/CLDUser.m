//
//  MCUser.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

#import "CLDUser.h"

@interface CLDUser ()
@property (readwrite, strong, nonatomic) NSString *name;
@property (readwrite, strong, nonatomic) NSString *email;
@property (readwrite, strong, nonatomic) NSString *userId;
@end

@implementation CLDUser

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _name = [aDecoder decodeObjectForKey:@"name"];
    _email = [aDecoder decodeObjectForKey:@"email"];
    _userId = [aDecoder decodeObjectForKey:@"userId"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.email forKey:@"email"];
    [aCoder encodeObject:self.userId forKey:@"userId"];
}

#pragma mark - Private methods

+ (instancetype)userWithDictionary:(NSDictionary *)dictionary {
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    CLDUser *user = [[self alloc] init];
    if (user) {
        NSString *userId = dictionary[@"uid"];
        if (!userId) userId = dictionary[@"id"];
        user.userId = userId;
        
        NSString *name = dictionary[@"name"];
        if (!name) name = dictionary[@"display_name"];
        user.name = name;
        
        NSString *email = dictionary[@"email"];
        user.email = email;
    }
    return user;
}

@end
