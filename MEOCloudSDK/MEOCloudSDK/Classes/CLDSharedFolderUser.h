//
//  CLDFolderUser.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 17/03/14.
//
//

#import <MEOCloudSDK/CLDUser.h>

@class CLDSharedFolder;

/**
 This subclass of <CLDUser> is used to represent users belonging to a shared folder.
 
 For more information about shared folders see the documentation for <CLDSharedFolder>.
 */
@interface CLDSharedFolderUser : CLDUser

/**
 `BOOL` stating the ownership of this user regarding the shared folder it belongs to.
 @see folder
 @since 1.0
 */
@property (readonly, nonatomic, getter = isOwner) BOOL owner;

/**
 `BOOL` stating whether the user is the same as the one making the request (ie. the owner of this session)
 @since 1.0
 */
@property (readonly, nonatomic, getter = isUser) BOOL user;

/**
 The shared folder this user belongs to.
 @since 1.0
 */
@property (readonly, weak, nonatomic) CLDSharedFolder *folder;

/**
 `BOOL` stating whether or not this user has accepted the invite request.
 @since 1.0
 */
@property (readonly, nonatomic) BOOL accepted;

/**
 The invite request ID, in case the user has not yet registered.
 You can use this to revoke an invitation.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *inviteRequestId;

/**
 The date and time of the invite request.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDate *inviteRequestDate;

@end
