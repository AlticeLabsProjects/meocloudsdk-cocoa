//
//  MCSession.h
//  MCSession
//
//  Created by Hugo Sousa on 06/03/14.
//
//

#import <MEOCloudSDK/CLDAccountUser.h>
#import <MEOCloudSDK/CLDItem.h>
#import <MEOCloudSDK/CLDLink.h>
#import <MEOCloudSDK/CLDSessionConfiguration.h>
#import <MEOCloudSDK/CLDTransferManager.h>
#import <MEOCloudSDK/CLDTransfer.h>

#ifndef CLDImage

#if TARGET_OS_IPHONE
#define CLDImage UIImage
#else
#define CLDImage NSImage
#endif

#endif

/**
 Image format for item thumbnails.
 @since 1.0
 */
typedef NS_ENUM(NSUInteger, CLDItemThumbnailFormat) {
    /**
     JPEG format.
     @since 1.0
     */
    CLDItemThumbnailFormatJPEG,
    /**
     PNG format.
     @since 1.0
     */
    CLDItemThumbnailFormatPNG
};

/**
 Image size for item thumbnails.
 
 Please note that these sizes are in pixels, not points.
 @since 1.0
 */
typedef NS_ENUM(NSUInteger, CLDItemThumbnailSize) {
    /**
     XS - 32x32 pixels.
     @since 1.0
     */
    CLDItemThumbnailSizeXS,
    /**
     S - 64x64 pixels.
     @since 1.0
     */
    CLDItemThumbnailSizeS,
    /**
     M - 120x120 pixels.
     @since 1.0
     */
    CLDItemThumbnailSizeM,
    /**
     L - 640x480 pixels.
     @since 1.0
     */
    CLDItemThumbnailSizeL,
    /**
     XL - 1024x768 pixels.
     @since 1.0
     */
    CLDItemThumbnailSizeXL
};

/**
 Available streaming protocols.
 @since 1.0
 */
typedef NS_ENUM(NSUInteger, CLDItemStreamingProtocol) {
    /**
     HTTP Live Streaming.
     @since 1.0
     */
    CLDItemStreamingProtocolHLS,
    /**
     Real Time Messaging Protocol.
     @since 1.0
     */
    CLDItemStreamingProtocolRTMP,
    /**
     Real Time Streaming Protocol.
     @since 1.0
     */
    CLDItemStreamingProtocolRTSP,
    /**
     Smooth Streaming.
     @since 1.0
     */
    CLDItemStreamingProtocolSS
};

/**
 Options for fetching items.
 @since 1.0
 */
typedef NS_OPTIONS(NSInteger, CLDSessionFetchItemOptions) {
    /**
     No options
     @since 1.0
     */
    CLDSessionFetchItemOptionNone = 0,
    /**
     List contents of items that are folders.
     @note This is not recursive (i.e. sub-items that are folders will not have their contents populated).
     @since 1.0
     */
    CLDSessionFetchItemOptionListContents = 1 << 0,
    /**
     Include items that were previously deleted.
     @since 1.0
     */
    CLDSessionFetchItemOptionIncludeDeletedItems = 1 << 1
};

/**
 Possible network states.
 @since 1.0
 */
typedef NS_ENUM(NSUInteger, CLDSessionNetworkState) {
    /**
     No connections are currently active.
     @since 1.0
     */
    CLDSessionNetworkStateInactive,
    /**
     The session is currently requesting information from the server.
     @since 1.0
     */
    CLDSessionNetworkStateActive,
};

/**
 Block passed in <fetchAuthenticationURLWithURLBlock:resultBlock:failureBlock:>.
 This block validates an URL and tries to link the session with a user account.
 
 @param url   The URL to validate OAuth authentication.
 
 @return `YES` if the URL is valid and the server returned a valid OAuth 2.0 token.
 @see -fetchAuthenticationURLWithURLBlock:resultBlock:failureBlock:
 @since 1.0
 */
typedef BOOL(^CLDSessionValidateCallbackURLBlock)(NSURL *url);

/**
 A `CLDSession` allows you to easily interact with MEO Cloud's API with block-based methods.
 
 For most apps, you will only need one CLDSession (usually a singleton). You can use <defaultSession> along with <setDefaultSession:> to quickly achieve this.
 @warning All instances must be created with <sessionWithIdentifier:>. Calling `init` will raise an exception.
 */
@interface CLDSession : NSObject


////////////////////////////////////////////////////////////////////////////////
/// @name Creating a CLDSession
////////////////////////////////////////////////////////////////////////////////

/**
 Default method for obtaining / creating instances of `CLDSession` objects.
 
 @note If you call this method and a session with `identifier` already exists in memory, that instance is returned.
 
 @param identifier       The session identifier. Use the same identifier across app runs to always access the same instance.
 @warning `identifier`, `consumerKey`, `consumerSecret` and `callbackURL` must not be `nil`.
 
 @return A new `CLDSession` initialized with the given identifier, consumer key, consumer secret and callback URL.
 @since 1.0
 */
+ (instancetype)sessionWithIdentifier:(NSString *)identifier;

/**
 The session identifier
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *sessionIdentifier;

/**
 Returns YES if sandbox mode is turned on for this CLDSession. (read-only)
 @since 1.0
 */
@property (readonly, nonatomic, getter = isSandbox) BOOL sandbox;


////////////////////////////////////////////////////////////////////////////////
/// @name Default Session
////////////////////////////////////////////////////////////////////////////////

/**
 Returns a shared `CLDSession` or nil, if none was set.
 
 Default sessions must be set with <setDefaultSession:>.
 @return The default CLDSession.
 @since 1.0
 */
+ (CLDSession *)defaultSession;

/**
 Sets the shared `CLDSession` to be used in <defaultSession>.
 @param session The `CLDSession`.
 @since 1.0
 */
+ (void)setDefaultSession:(CLDSession *)session;


////////////////////////////////////////////////////////////////////////////////
/// @name Authentication
////////////////////////////////////////////////////////////////////////////////

/**
 Checks if the session is linked with a user account.
 @see -fetchAccountInformationWithResultBlock:failureBlock:
 @return `YES` if the session is linked.
 @since 1.0
 */
@property (readonly, nonatomic, getter = isLinked) BOOL linked;

#if TARGET_OS_IPHONE
/**
 Begins the OAuth 2.0 authentication process by showing a webview on a new `UIWindow` (iOS) or calling the default web browser (Mac).
 
 If you want to display the authentication webview yourself see <fetchAuthenticationURLWithResultBlock:> for a more customized solution.
 
 @param configuration   The configuration settings used to link the session.
 @param resultBlock     The block to be executed once the authentication process finished successfully.
 @param failureBlock    The block to be executed if authentication failed. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)linkSessionWithConfiguration:(CLDSessionConfiguration *)configuration
                         resultBlock:(void(^)())resultBlock
                        failureBlock:(void(^)(NSError *error))failureBlock;
#endif
/**
 Begins a low-level OAuth 2.0 authentication process by providing an URL to be used in any webview or browser.
 
 Call this method to obtain a valid `NSURL` in `URLBlock` to call in a webview or browser.
 Then, each time the browser tries to make a new request (for example, in `UIWebViewDelegate`'s `webView:shouldStartLoadWithRequest:navigationType:`)
 you should call `validateCallbackURL(url)`, passing the URL in the request.
 
 If the block returns `YES` the session will then try to obtain a valid access token in the background and call `resultBlock` or `failureBlock`
 when it finishes.
 
 If successfull, when `resultBlock` is executed the `CLDSession` will already be linked to the user account.
 
 @param configuration   The configuration settings used to link the session.
 @param URLBlock        The block to be executed once the URL is fetched. This block takes two arguments: the authentication URL and a `CLDSessionValidateCallbackURLBlock` block.
 @param resultBlock     The block to be executed once the authentication process finished successfully.
 @param failureBlock    The block to be executed if the URL could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)linkSessionWithConfiguration:(CLDSessionConfiguration *)configuration
                            URLBlock:(void(^)(NSURL *url, CLDSessionValidateCallbackURLBlock validateCallbackURL))URLBlock
                         resultBlock:(void(^)())resultBlock
                        failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Removes all authentication information from the session.
 
 @warning All transfers in progress or queued up will be cancelled.
 
 @param resultBlock  The block to be executed once the session is unliked
 @param failureBlock The block to be executed if the session could not be unlinked. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)unlinkSessionWithResultBlock:(void(^)())resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Fetches account information for the currently linked user.
 
 @param resultBlock  The block to be executed once the information is fetched. This block takes an <CLDAccountUser> argument containing the account information.
 @param failureBlock The block to be executed if account information could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchAccountInformationWithResultBlock:(void(^)(CLDAccountUser *user))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Network Information
////////////////////////////////////////////////////////////////////////////////

@property (readonly, atomic) CLDSessionNetworkState networkState;


////////////////////////////////////////////////////////////////////////////////
/// @name Fetching item information
////////////////////////////////////////////////////////////////////////////////

/**
 The default limit of items to be obtained. Default value is 10000 and maximum value is 25000.
 @see fetchItem:options:resultBlock:failureBlock:
 @since 1.0
 */
@property (nonatomic) NSUInteger itemLimit;

/**
 Fetches information about an item.
 
 @param item         An instance of <CLDItem>.
 @param options      Bitmask of options for fetching items. For a list of valid constants, see <CLDSessionFetchItemOptions>
 @param resultBlock  The block to be executed once the item information is fetched. This block takes an <CLDItem> argument containing the item.
 @param failureBlock The block to be executed if the item information could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchItem:(CLDItem *)item options:(CLDSessionFetchItemOptions)options resultBlock:(void(^)(CLDItem *item))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Copying items
////////////////////////////////////////////////////////////////////////////////

/**
 Copies an item to a specified path.
 
 @param item         The item to be copied.
 @param path         The destination path of the item. This path should contain the destination item's name.
 @param resultBlock  The block to be executed once the item is copied. This block takes an <CLDItem> argument containing the copied item.
 @param failureBlock The block to be executed if the item could not be copied. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)copyItem:(CLDItem *)item toPath:(NSString *)path resultBlock:(void(^)(CLDItem *newItem))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Fetches an reference code that can be given to another user to quickly copy a file or folder into their MEOCloud folder.
 To copy a file or folder using a reference use <copyItemFromReference:toPath:resultBlock:failureBlock:>.
 
 @param item         The item to be copied
 @param resultBlock  The block to be executed once the reference is successfully obtained. This block takes two arguments: an `NSString` with the reference code and an `NSDate` with the code expiration date.
 @param failureBlock The block to be executed if the reference code could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchCopyReferenceForItem:(CLDItem *)item resultBlock:(void(^)(NSString *reference, NSDate *expireDate))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Fetches information about an item to be copied using a reference code.
 Use this method for when you want to display some information to the user about the item about to be copied.
 
 @param reference    The reference code for the item.
 @param resultBlock  The block to be executed once the item's metadata is fetched. This block takes an `NSDictionary` argument containing the item's metadata.
 The dictionary keys match <CLDItem>'s property names and can be safely fetched using `[itemInfo objectForKey:NSStringFromSelector(@selector(name))]`.
 
 Currently available items are:
 
  - *itemType*
  - *size*
  - *sizeString*
  - *name*
  - *mimeType*
  - *iconName*
 
 @param failureBlock The block to be executed if the information could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchItemDetailsFromReference:(NSString *)reference resultBlock:(void(^)(NSDictionary *itemInfo))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Copies an item from a reference code to a specified path.
 
 @param reference    The reference code for the item to be copied.
 @param path         The destination path for the item. This path should contain the destination item's name.
 @param resultBlock  The block to be executed once the item is copied. This block takes an <CLDItem> argument containing the copied item.
 @param failureBlock The block to be executed if the item could not be copied. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)copyItemFromReference:(NSString *)reference toPath:(NSString *)path resultBlock:(void(^)(CLDItem *newItem))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Moving items
////////////////////////////////////////////////////////////////////////////////

/**
 Moves an item to a specified path.
 
 @param item         The item to be moved.
 @param path         The destination path of the item. This path should contain the destination item's name.
 @param resultBlock  The block to be executed once the item is moved. This block takes an <CLDItem> argument containing the moved item.
 @param failureBlock The block to be executed if the item could not be moved. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)moveItem:(CLDItem *)item toPath:(NSString *)path resultBlock:(void(^)(CLDItem *newItem))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Renaming items
////////////////////////////////////////////////////////////////////////////////

/**
 Renames an item.
 
 @param item         The item to be renamed.
 @param name         The new name for the item. This should include any extension, if applicable.
 @param resultBlock  The block to be executed once the item is renamed. This block takes an <CLDItem> argument containing the renamed item.
 @param failureBlock The block to be executed if the item could not be renamed. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)renameItem:(CLDItem *)item name:(NSString *)name resultBlock:(void(^)(CLDItem *renamedItem))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Deleting items
////////////////////////////////////////////////////////////////////////////////

/**
 Deletes an item.
 
 @param item         The item to be deleted.
 @param resultBlock  The block to be executed once the item is deleted. This block takes an <CLDItem> argument containing the deleted item.
 @param failureBlock The block to be executed if the item could not be deleted. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)deleteItem:(CLDItem *)item resultBlock:(void(^)(CLDItem *deletedItem))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Restores a previously deleted item. Use <restoreItem:resultBlock:failureBlock:> instead if you want to restore an item to a specific revision.
 
 @param item         The item to be deleted.
 @param resultBlock  The block to be executed once the item is deleted. This block takes an <CLDItem> argument containing the restored item.
 @param failureBlock The block to be executed if the item could not be restored. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)undeleteItem:(CLDItem *)item resultBlock:(void(^)(CLDItem *restoredItem))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Creating folders
////////////////////////////////////////////////////////////////////////////////

/**
 Creates a new folder on a specified path.
 
 @param path         The path where the folder should be created. This path must contain the folder's name.
 @param resultBlock  The block to be executed once the folder is created. This block takes an <CLDItem> argument containing the newly created folder.
 @param failureBlock The block to be executed if the folder could not be created. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)createFolderAtPath:(NSString *)path resultBlock:(void(^)(CLDItem *newFolder))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Item revisions
////////////////////////////////////////////////////////////////////////////////

/**
 Fetches a list of available revisions for a specified item.
 
 @note The API currently returns a maximum number of 7 revisions per item, along with a 30 day limit.
 
 @param item         The item whose revisions should be fetched.
 @param resultBlock  The block to be executed once the item revisions are fetched. This block takes an `NSArray` argument containing the array of revision items. Each item is an instance of <CLDItem> and can be used directly in <restoreItem:resultBlock:failureBlock:>.
 @param failureBlock The block to be executed if the item revisions could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchRevisionsForItem:(CLDItem *)item resultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Fetches a list of available revisions for a specified item.
 
 This method allows you to specify how many revisions should be returned in `resultBlock`.
 
 @note The API currently returns a maximum number of 7 revisions per item, along with a 30 day limit.
 
 @param item         The item whose revisions should be fetched.
 @param limit        Maximum number of revisions to be fetched.
 @param resultBlock  The block to be executed once the item revisions are fetched. This block takes an `NSArray` argument containing the array of revision items. Each item is an instance of <CLDItem> and can be used directly in <restoreItem:resultBlock:failureBlock:>.
 @param failureBlock The block to be executed if the item revisions could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchRevisionsForItem:(CLDItem *)item revisionLimit:(NSUInteger)limit resultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Restores an item to a specified revision.
 
 Items can obtained from <fetchRevisionsForItem:revisionLimit:resultBlock:failureBlock:> or created with [CLDItem itemWithPath:revision:].
 
 @param item         The item to be restored
 @param resultBlock  The block to be executed once the item is restored. This block takes an <CLDItem> argument containing the restored item.
 @param failureBlock The block to be executed if the item could not be restored. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)restoreItem:(CLDItem *)item resultBlock:(void(^)(CLDItem *restoredItem))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Public links
////////////////////////////////////////////////////////////////////////////////

/**
 Fetches all public links associated with a user account.
 
 @param resultBlock  The block to be executed once the links are fetched. This block takes an `NSArray` argument containing the array of links. Each link is an instance of <CLDLink>.
 @param failureBlock The block to be executed if the links could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchPublicLinksWithResultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Fetches a public link for a specific item. If an link was previously created on this or another device, the same link will be returned here.
 
 @param item         The item whose public link should be fetched.
 @param resultBlock  The block to be executed once the link is fetched. This block takes an <CLDLink> argument containing the public link.
 @param failureBlock The block to be executed if the link could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchPublicLinkForItem:(CLDItem *)item resultBlock:(void(^)(CLDLink *link))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Deletes and invalidates a public link.
 
 @param link         The link to be deleted.
 @param resultBlock  The block to be executed once the link is deleted.
 @param failureBlock The block to be executed if the link could not be deleted. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)deletePublicLink:(CLDLink *)link resultBlock:(void(^)())resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Upload Links (Upload2Me)
////////////////////////////////////////////////////////////////////////////////

/**
 Fetches all upload links associated with a user account.
 
 @param resultBlock  The block to be executed once the links are fetched. This block takes an `NSArray` argument containing the array of links. Each link is an instance of <CLDLink>.
 @param failureBlock The block to be executed if the links could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchUploadLinksWithResultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Fetches an upload link for a specific item. If an link was previously created on this or another device, the same link will be returned here.
 
 @param item         The item whose upload link should be fetched.
 @param resultBlock  The block to be executed once the link is fetched. This block takes an <CLDLink> argument containing the upload link.
 @param failureBlock The block to be executed if the link could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchUploadLinkForItem:(CLDItem *)item resultBlock:(void(^)(CLDLink *link))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Deletes and invalidates an upload link.
 
 @param link         The link to be deleted.
 @param resultBlock  The block to be executed once the link is deleted.
 @param failureBlock The block to be executed if the link could not be deleted. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)deleteUploadLink:(CLDLink *)link resultBlock:(void(^)())resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Shared folders
////////////////////////////////////////////////////////////////////////////////

/**
 Fetches a list with all currently shared folders.
 
 @param resultBlock  The block to be executed once the list is fetched. This block takes an `NSArray` argument containing the list of folders. Each folder is an instance of <CLDSharedFolder>.
 @param failureBlock The block to be executed if the list of folders could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchSharedItemsWithResultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Sends an invitation to share a folder to a specified e-mail address.
 
 @param item         The folder to be shared.
 @param email        The e-mail where the invite should be sent.
 @param resultBlock  The block to be executed if the invite is sent successfully. This block takes an `NSString` argument containing the request ID.
 @param failureBlock The block to be executed if the invite could not be sent. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)shareItem:(CLDItem *)item withEmail:(NSString *)email resultBlock:(void(^)(NSString *inviteRequestId))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Searching items
////////////////////////////////////////////////////////////////////////////////

/**
 Performs a search on a given path with a specified query string.
 
 This method does not specify a mime-type or include deleted items.
 
 The maximum number of items returned is 1000. Call <searchPath:query:limit:resultBlock:failureBlock:> instead if you would like to customize this.
 
 @param item         The item where you want to perform the search. Must be of type `CLDItemTypeFolder`.
 @param query        The query string to be searched. Must be between 3 and 20 characters.
 @param resultBlock  The block to be executed once the search is performed. This block takes an `NSArray` argument containig the search results. Each item is an instance of <CLDItem>.
 @param failureBlock The block to be executed if the search could not be performed. This block takes an `NSError` argument containing the error.
 @see -searchPath:query:limit:resultBlock:failureBlock:
 @see -searchPath:query:limit:mimeType:resultBlock:failureBlock:
 @see -searchPath:query:limit:mimeType:includeDeletedItems:resultBlock:failureBlock:
 @since 1.0
 */
- (void)searchItem:(CLDItem *)item query:(NSString *)query resultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Performs a search on a given path with a specified query string.
 
 This method does not specify a mime-type or include deleted items.
 
 @param item         The item where you want to perform the search. Must be of type `CLDItemTypeFolder`.
 @param query        The query string to be searched. Must be between 3 and 20 characters.
 @param limit        The maximum number of items to be returned. Must be between 1 and 25000.
 @param resultBlock  The block to be executed once the search is performed. This block takes an `NSArray` argument containig the search results. Each item is an instance of <CLDItem>.
 @param failureBlock The block to be executed if the search could not be performed. This block takes an `NSError` argument containing the error.
 @see -searchPath:query:resultBlock:failureBlock:
 @see -searchPath:query:limit:mimeType:resultBlock:failureBlock:
 @see -searchPath:query:limit:mimeType:includeDeletedItems:resultBlock:failureBlock:
 @since 1.0
 */
- (void)searchItem:(CLDItem *)item query:(NSString *)query limit:(NSUInteger)limit resultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Performs a search on a given path with a specified query string and mime-type.
 
 This method does not include deleted items.
 
 @param item         The item where you want to perform the search. Must be of type `CLDItemTypeFolder`.
 @param query        The query string to be searched. Must be between 3 and 20 characters.
 @param limit        The maximum number of items to be returned. Must be between 1 and 25000.
 @param mimeType     The mime-type that should be returned.
 @param resultBlock  The block to be executed once the search is performed. This block takes an `NSArray` argument containig the search results. Each item is an instance of <CLDItem>.
 @param failureBlock The block to be executed if the search could not be performed. This block takes an `NSError` argument containing the error.
 @see -searchPath:query:resultBlock:failureBlock:
 @see -searchPath:query:limit:resultBlock:failureBlock:
 @see -searchPath:query:limit:mimeType:includeDeletedItems:resultBlock:failureBlock:
 @since 1.0
 */
- (void)searchItem:(CLDItem *)item query:(NSString *)query limit:(NSUInteger)limit mimeType:(NSString *)mimeType resultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Performs a search on a given path with a specified query string and mime-type.
 
 This method allows you to specify whether you want to include deleted items or not.
 
 @param item         The item where you want to perform the search. Must be of type `CLDItemTypeFolder`.
 @param query                The query string to be searched. Must be between 3 and 20 characters.
 @param limit                The maximum number of items to be returned. Must be between 1 and 25000.
 @param mimeType             The mime-type that should be returned.
 @param includeDeletedItems  `BOOL` stating if the search results should include previously deleted items.
 @param resultBlock          The block to be executed once the search is performed. This block takes an `NSArray` argument containig the search results. Each item is an instance of <CLDItem>.
 @param failureBlock         The block to be executed if the search could not be performed. This block takes an `NSError` argument containing the error.
 @see -searchPath:query:resultBlock:failureBlock:
 @see -searchPath:query:limit:resultBlock:failureBlock:
 @see -searchPath:query:limit:mimeType:resultBlock:failureBlock:
 @since 1.0
 */
- (void)searchItem:(CLDItem *)item query:(NSString *)query limit:(NSUInteger)limit mimeType:(NSString *)mimeType includeDeletedItems:(BOOL)includeDeletedItems resultBlock:(void(^)(NSArray *items))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Accessing items
////////////////////////////////////////////////////////////////////////////////

/**
 Fetches a thumbnail for an item with a specific format and size.
 
 @note If you want to view a photo, please note that this method will never return the full size **original** image. For displaying a full resolution image you should use <fetchURLForItem:resultBlock:failureblock:>.
 
 @param item         The item whose thumbnail should be fetched.
 @param format       The format of the thumbnail.
 @param size         The size of the thumbnail.
 @param cropToSize   `BOOL` stating if the thumbnail should be cropped to the chosen size.
 @param resultBlock  The block to be executed once the thumbnail is fetched. This block takes an `UIImage` argument containing the thumbnail.
 @param failureBlock The block to be executed if the thumbnail could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchThumbnailForItem:(CLDItem *)item format:(CLDItemThumbnailFormat)format size:(CLDItemThumbnailSize)size cropToSize:(BOOL)cropToSize resultBlock:(void(^)(CLDImage *thumbnail))resultBlock failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Fetches a direct `NSURL` to download a file. This is useful if you want to download files yourself or if you want to share a direct link between apps without the user having to authenticate again on another device or app.
 
 @param item         The item whose URL should be fetched. Must be of type `CLDItemTypeFile`.
 @param transcode    `BOOL` stating if a transcoding URL should be returned, when available. Please note that passing `YES` may result in longer response times.
 @param resultBlock  The block to be executed once the URL is fetched. This block takes two arguments: an `NSURL` containing the URL and and `NSDate` with the URL's expiration date.
 @param failureBlock The block to be executed if the URL could not be fetched. This block takes an `NSError` argument containing the error.
 @since 1.0
 */
- (void)fetchURLForItem:(CLDItem *)item
    transcodeIfPossible:(BOOL)transcode
            resultBlock:(void(^)(NSURL *url, NSURL *transcodingURL, NSDate *expireDate))resultBlock
           failureBlock:(void(^)(NSError *error))failureBlock;


////////////////////////////////////////////////////////////////////////////////
/// @name Transfering files
////////////////////////////////////////////////////////////////////////////////

/**
 The transfer manager for this session.
 @since 1.0
 */
@property (readonly, strong, nonatomic) CLDTransferManager *transferManager;

/**
 Downloads a file to a temporary location.
 
 To check the progress of a download transfer you may periodically check it's value or subscribe to the notifications posted by <CLDTransferManager>.
 
 @warning You should open or move the file in `resultBlock` or it will be deleted shortly after the block finishes executing.
 
 @param item            The item to be downloaded.
 @param cellularAccess  `BOOL` stating whether or not the transfer should be performed using cellular data.
 @param priority        The transfer priority.
 @param resultBlock     The block to be executed once the file is downloaded. This block takes an `NSURL` argument with the path to the temporary file.
 @param failureBlock    The block to be executed if the file could not be downloaded. This block takes an `NSError` argument with the error.
 
 @return An instance of <CLDTransfer> that can be cancelled at any time. Please note that, when you cancel an item, failureBlock does not get called.
 @since 1.0
 */
- (CLDTransfer *)downloadItem:(CLDItem *)item
               cellularAccess:(BOOL)cellularAccess
                     priority:(CLDTransferPriority)priority
                  resultBlock:(void(^)(NSURL *fileURL))resultBlock
                 failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Uploads a new item to a specific location. The item should be created with a convenience <CLDItem> class method.
 
 To check the progress of a upload transfer you may periodically check it's value or subscribe to the notifications posted by <CLDTransferManager>.
  
 @param item            The item to be uploaded.
 @param overwrite       `BOOL` stating if the file should be rewritten, in case it already exists on the server.
 @param cellularAccess  `BOOL` stating whether or not the transfer should be performed using cellular data.
 @param priority        The transfer priority.
 @param resultBlock     The block to be executed once the file is uploaded. This block takes an <CLDItem> argument containing the uploaded item.
 @param failureBlock    The block to be executed if the file could not be uploaded. This block takes an `NSError` argument with the error.
 
 @return An instance of <CLDTransfer> that can be cancelled at any time. Please note that, when you cancel an item, failureBlock does not get called.
 @since 1.0
 */
- (CLDTransfer *)uploadItem:(CLDItem *)item
            shouldOverwrite:(BOOL)overwrite
             cellularAccess:(BOOL)cellularAccess
                   priority:(CLDTransferPriority)priority
                resultBlock:(void(^)(CLDItem *newItem))resultBlock
               failureBlock:(void(^)(NSError *error))failureBlock;

/**
 Schedules a new download transfer for a specific file.
 
 This method works differently than <downloadItem:resultBlock:failureBlock:> in that transfers are added to a queue and performed even when the app is not running using `NSURLSessionDownloadTask`.
 
 Because your app execution might be interrupted before a download is finished, background transfers cannot be block-based.
 Instead, notifications are posted by <CLDTransferManager> when the transfers start and finish.
 You can also subscribe to KVO changes on the `state` property of any transfer.
 
 When a transfer finishes you should copy, open or move the file immediately or it will be deleted shortly after the respective notification is posted.
 
 @warning To use this method you must implement the forward method <handleEventsForBackgroundURLSession:completionHandler:> in your app delegate.
 
 @param item            The item to be downloaded.
 @param cellularAccess  `BOOL` stating whether or not the transfer should be performed using cellular data.
 @param priority        The transfer priority.
 @param error           Out parameter with an error, in case the download could not be scheduled.
 
 @return An instance of <CLDTransfer> that can be tracked or cancelled at any time.
 @see +handleEventsForBackgroundURLSession:completionHandler:
 @since 1.0
 */
- (CLDTransfer *)scheduleDownloadForItem:(CLDItem *)item
                          cellularAccess:(BOOL)cellularAccess
                                priority:(CLDTransferPriority)priority
                                   error:(NSError **)error;

/**
 Schedules a new upload transfer for a specific file. The item should be created with a convenience <CLDItem> class method.
 
 This method works differently than <uploadItem:shouldOverwrite:resultBlock:failureBlock:> in that transfers are adde to a queue and performed even when the app is not running using `NSURLSessionUploadTask`.
 
 Because your app execution might be interrupted before an upload is finished, background transfers cannot be block-based.
 Instead, notifications are posted by <CLDTransferManager> when the transfers start and finish.
 
 @warning To use this method you must implement the forward method <handleEventsForBackgroundURLSession:completionHandler:> in your app delegate.
 
 @param item            The item to be uploaded.
 @param overwrite       `BOOL` stating if the file should be rewritten, in case it already exists on the server.
 @param cellularAccess  `BOOL` stating whether or not the transfer should be performed using cellular data.
 @param priority        The transfer priority.
 @param error           Out parameter with an error, in case the upload could not be scheduled.
 
 @return An instance of <CLDTransfer> that can be tracked or cancelled at any time.
 @see +handleEventsForBackgroundURLSession:completionHandler:
 @since 1.0
 */
- (CLDTransfer *)scheduleUploadForItem:(CLDItem *)item
                       shouldOverwrite:(BOOL)overwrite
                        cellularAccess:(BOOL)cellularAccess
                              priority:(CLDTransferPriority)priority
                                 error:(NSError **)error;

/**
 Forward method that informs the `CLDSession` class that events related to transfers are waiting to be processed.
 
 This is a forward method that must be implemented if you want to use background transfers.
 To do this, simply call it in your AppDelegate's `application:handleEventsForBackgroundURLSession:completionHandler:` implementation with the parameters already provided there.
 
 @param identifier        The `identifier` parameter in `application:handleEventsForBackgroundURLSession:completionHandler:`.
 @param completionHandler The `completionHandler` parameter in `application:handleEventsForBackgroundURLSession:completionHandler:`.
 @see -scheduleDownloadForItem:error:
 @see -scheduleUploadForItem:shouldOverwrite:error:
 @since 1.0
 */
+ (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;


@end