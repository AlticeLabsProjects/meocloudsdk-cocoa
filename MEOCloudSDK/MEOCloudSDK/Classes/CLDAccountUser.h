//
//  CLDAccountUser.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 17/03/14.
//
//

#import <MEOCloudSDK/CLDUser.h>

/**
 This subclass of <CLDUser> is used to represent a user's account information.
 */
@interface CLDAccountUser : CLDUser

/**
 `BOOL` stating if the user's account is currently active.
 @since 1.0
 */
@property (readonly, nonatomic, getter = isActive) BOOL active;

/**
 `BOOL` stating if the user's account is still in trial.
 @since 1.0
 */
@property (readonly, nonatomic, getter = isTrial) BOOL trial;

/**
 Total quota available to the user.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDecimalNumber *quotaTotal;

/**
 Available free space on the user's account.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDecimalNumber *quotaAvailable;

/**
 Total used quota with both normal and shared content.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDecimalNumber *quotaUsed;

/**
 Total used quota with normal content.
 @see quotaUsed
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDecimalNumber *quotaUsedNormal;

/**
 Total used quota with shared content.
 @see quotaUsed
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDecimalNumber *quotaUsedShared;

/**
 The user's referral code.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *referralCode;

/**
 The user's referral URL. Use this if you want to invite others using this user's referral code.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSURL *referralURL;

/**
 The date when the user signed up.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDate *createDate;

/**
 The date of the user's last event.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDate *lastEventDate;

@end
