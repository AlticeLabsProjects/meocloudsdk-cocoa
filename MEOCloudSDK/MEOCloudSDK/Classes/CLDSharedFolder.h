//
//  CLDSharedFolder.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 17/03/14.
//
//

/**
 This class is used to represent a shared folder.
 
 Please note that this is not the same as having an instance of <CLDFolderItem> with `folderType=CLDFolderTypeShared`.
 Instances of `CLDSharedFolder`are obtained differently and only contain metadata about that sharing and users, not about the shared folder itself.
 */
@interface CLDSharedFolder : NSObject <NSCoding>

/**
 The share ID.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *shareId;

/**
 `BOOL` stating if the session's user is the owner of the shared folder.
 @since 1.0
 */
@property (readonly, nonatomic, getter=isOwner) BOOL owner;

/**
 The shared folder's path in the user's MEO Cloud account.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *path;

/**
 List of users who have access to the folder, including the owner.
 Each entry is an instance of <CLDSharedFolderUser>.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSArray *users;

@end
