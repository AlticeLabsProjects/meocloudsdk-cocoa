//
//  MCLink.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

@class CLDItem;

/**
 This class is used to represent a public or upload link (Upload2Me).
 These are quite similar in structure, although serve two very different purposes:
 
 - Public links are used to publicly share a specific file or directory.
 - Upload links allow other users (even ones withou an account created) to upload files to a folder using their web browser.
 */
@interface CLDLink : NSObject <NSCoding>

/**
 The identifier of the session this link belongs to.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *sessionIdentifier;

/**
 `BOOL` stating whether this instance is a public link or an upload link (Upload2Me).
 @since 1.0
 */
@property (readonly, nonatomic, getter = isUploadLink) BOOL uploadLink;

/**
 The URL, usually pointing to a web page representing the content.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSURL *shareURL;

/**
 The download URL.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSURL *downloadURL;

/**
 An optional short URL pointing to the same web page as `shareURL`.
 @see -fetchShortURLWithResultBlock:failureBlock:
 @see -deleteShortURLWithResultBlock:failureBlock:
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSURL *shortURL;

/**
 The share ID.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *shareId;

/**
 Expiration date of the link.
 @see -setExpireDate:resultBlock:failureBlock:
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDate *expireDate;

/**
 Number of visists the link got.
 @since 1.0
 */
@property (readonly, nonatomic) NSUInteger visits;

/**
 The item being shared.
 @note Due to server limitations, this property only contains data when listing links. Creating a new link does not return any item metadata.
 @since 1.0
 */
@property (readonly, strong, nonatomic) CLDItem *item;

/**
 Changes the expire date of the receiver.
 @param expireDate      The new expire date.
 @param resultBlock     The block to be executed once the new expire date is set.
 @param failureBlock    The block to be executed if the new expire date could not be set. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)setExpireDate:(NSDate *)expireDate resultBlock:(void(^)())resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Removes the expire date of the receiver.
 @param resultBlock     The block to be executed once the expire date is removed
 @param failureBlock    The block to be executed if the  expire date could not be removed. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)removeExpireDateWithResultBlock:(void(^)())resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Fetches a short URL from the server and assigns it to the `shortURL` property.
 @note For convenience, `resultBlock` also passes the new URL as an argument.
 @param resultBlock     The block to be executed once the URL is fetched. This block takes an `NSURL` argument.
 @param failureBlock    The block to be executed if the URL could not be fetched. This block takes an `NSError` argument containing the error.
 @see -deleteShortURLWithResultBlock:failureBlock:
 @since 1.0
 */
- (void)fetchShortURLWithResultBlock:(void(^)(NSURL *shortURL))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Deletes a short URL from the server.
 @note The `shortURL` is changed immediately. The blocks are only useful for confirmation that the change has been sucessfully made on the server.
 @param resultBlock     The block to be executed once the URL is deleted.
 @param failureBlock    The block to be executed if the URL could not be deleted. This block takes an `NSError` argument containing the error.
 @see -fetchShortURLWithResultBlock:failureBlock:
 @since 1.0
 */
- (void)deleteShortURLWithResultBlock:(void(^)())resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

@end
