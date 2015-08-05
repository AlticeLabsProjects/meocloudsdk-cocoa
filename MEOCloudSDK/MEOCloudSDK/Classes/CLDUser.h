//
//  MCUser.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

/**
 Model class representing a generic user, composed of only a name, email and user ID.
 
 This class is usually not used directly, but through the following subclasses: <CLDAccountUser> and <CLDFolderUser>.
 */
@interface CLDUser : NSObject <NSCoding>

/**
 The user's name.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *name;

/**
 The user's e-mail address.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *email;

/**
 The user ID.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *userId;

@end
