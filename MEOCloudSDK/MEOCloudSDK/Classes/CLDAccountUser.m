//
//  CLDAccountUser.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 17/03/14.
//
//

#import "CLDAccountUser.h"

@interface CLDAccountUser ()
@property (readwrite, nonatomic, getter=isActive) BOOL active;
@property (readwrite, nonatomic, getter=isTrial) BOOL trial;
@property (readwrite, strong, nonatomic) NSDecimalNumber *quotaTotal;
@property (readwrite, strong, nonatomic) NSDecimalNumber *quotaUsedNormal;
@property (readwrite, strong, nonatomic) NSDecimalNumber *quotaUsedShared;
@property (readwrite, strong, nonatomic) NSString *referralCode;
@property (readwrite, strong, nonatomic) NSURL *referralURL;
@property (readwrite, strong, nonatomic) NSDate *createDate;
@property (readwrite, strong, nonatomic) NSDate *lastEventDate;
@end

@implementation CLDAccountUser

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    _active = [aDecoder decodeBoolForKey:@"active"];
    _trial = [aDecoder decodeBoolForKey:@"trial"];
    _quotaTotal = [aDecoder decodeObjectForKey:@"quotaTotal"];
    _quotaUsedNormal = [aDecoder decodeObjectForKey:@"quotaUsedNormal"];
    _quotaUsedShared = [aDecoder decodeObjectForKey:@"quotaUsedShared"];
    _referralCode = [aDecoder decodeObjectForKey:@"referralCode"];
    _referralURL = [aDecoder decodeObjectForKey:@"referralURL"];
    _createDate = [aDecoder decodeObjectForKey:@"createDate"];
    _lastEventDate = [aDecoder decodeObjectForKey:@"lastEventDate"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeBool:self.isActive forKey:@"active"];
    [aCoder encodeBool:self.isTrial forKey:@"trial"];
    [aCoder encodeObject:self.quotaTotal forKey:@"quotaTotal"];
    [aCoder encodeObject:self.quotaUsedNormal forKey:@"quotaUsedNormal"];
    [aCoder encodeObject:self.quotaUsedShared forKey:@"quotaUsedShared"];
    [aCoder encodeObject:self.referralCode forKey:@"referralCode"];
    [aCoder encodeObject:self.referralURL forKey:@"referralURL"];
    [aCoder encodeObject:self.createDate forKey:@"createDate"];
    [aCoder encodeObject:self.lastEventDate forKey:@"lastEventDate"];
}

#pragma mark - Dynamic properties

- (NSDecimalNumber *)quotaAvailable {
    return [self.quotaTotal decimalNumberBySubtracting:self.quotaUsed];
}

- (NSDecimalNumber *)quotaUsed {
    return [self.quotaUsedNormal decimalNumberByAdding:self.quotaUsedShared];
}

#pragma mark - Private methods

+ (instancetype)userWithDictionary:(NSDictionary *)dictionary {
    CLDAccountUser *user = [super userWithDictionary:dictionary];
    
    if (user) {
        
        BOOL active = [dictionary[@"active"] boolValue];
        user.active = active;
        
        BOOL trial = [dictionary[@"trial"] boolValue];
        user.trial = trial;
        
        NSDictionary *quotaInfo = dictionary[@"quota_info"];
        NSDecimalNumber *quotaTotal = [NSDecimalNumber decimalNumberWithDecimal:[quotaInfo[@"quota"] decimalValue]];
        NSDecimalNumber *quotaUsedNormal = [NSDecimalNumber decimalNumberWithDecimal:[quotaInfo[@"normal"] decimalValue]];
        NSDecimalNumber *quotaUsedShared = [NSDecimalNumber decimalNumberWithDecimal:[quotaInfo[@"shared"] decimalValue]];
        user.quotaTotal = quotaTotal;
        user.quotaUsedNormal = quotaUsedNormal;
        user.quotaUsedShared = quotaUsedShared;
        
        NSString *referralCode = dictionary[@"referral_code"];
        user.referralCode = referralCode;
        
        NSString *referralLink = dictionary[@"referral_link"];
        if (referralLink) {
            NSURL *referralURL = [NSURL URLWithString:referralLink];
            user.referralURL = referralURL;
        }
        
        NSString *createDateString = dictionary[@"created_on"];
        if (createDateString) {
            NSDate *createDate = [[NSDateFormatter serviceDateFormatter] dateFromString:createDateString];
            user.createDate = createDate;
        }
        
        NSString *lastEventDateString = dictionary[@"last_event"];
        if (lastEventDateString) {
            NSDate *lastEventDate = [[NSDateFormatter serviceDateFormatter] dateFromString:lastEventDateString];
            user.lastEventDate = lastEventDate;
        }
        
    }
    
    return user;
}

@end
