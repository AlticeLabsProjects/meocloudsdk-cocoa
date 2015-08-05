//
//  MCItem.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

@class ALAsset;

/**
 Item type.
 @since 1.0
 */
typedef NS_ENUM(NSUInteger, CLDItemType) {
    /**
     A file.
     @since 1.0
     */
    CLDItemTypeFile,
    /**
     A folder.
     @since 1.0
     */
    CLDItemTypeFolder
};

/**
 Folder type.
 @since 1.0
 */
typedef NS_ENUM(NSUInteger, CLDItemFolderType) {
    /**
     Unknown folder type. If you receive items from the server with this type, please make sure the framework is updated to the latest version.
     @since 1.0
     */
    CLDItemFolderTypeUnknown,
    /**
     A normal folder is a folder owned by the user.
     @since 1.0
     */
    CLDItemFolderTypeNormal,
    /**
     A folder shared with or by the user.
     @see isOwner
     @since 1.0
     */
    CLDItemFolderTypeShared
};

/**
 This class is used to represent an item's metadata.
 An item may be a file or a folder in a user's MEO Cloud account.
 
 See <itemType> and cast your item to <CLDFileItem> or <CLDFolderItem> accordingly.
 @since 1.0
 */
@interface CLDItem : NSObject <NSCoding>


////////////////////////////////////////////////////////////////////////////////
/// @name Generic Properties
////////////////////////////////////////////////////////////////////////////////

/**
 The identifier of the session this item belongs to.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *sessionIdentifier;

/**
 The item's type.
 @since 1.0
 */
@property (readonly, nonatomic) CLDItemType type;

/**
 `BOOL` stating whether the item is hollow. A hollow item is one that was created using one of the convenience class methods such as <rootItem>.
 All items returned in result blocks will have this property set to `NO`.
 @since 1.0
 */
@property (readonly, nonatomic) BOOL hollow;

/**
 `BOOL` stating whether the item is included in the sandbox.
 @since 1.0
 */
@property (readonly, nonatomic, getter = isSandbox) BOOL sandbox;

/**
 The item's revision hash.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *revision;

/**
 The item's path, including the file/folder's name and extension.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *path;

/**
 The item's file/folder name and extension.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *name;

/**
 Date of the last modification made to the item
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDate *lastModified;

/**
 Date of the last modification made to the file/folder (mtime).
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSDate *lastModifiedMTime;

/**
 `BOOL` stating whether the item has a public link already generated.
 @since 1.0
 */
@property (readonly, nonatomic) BOOL hasPublicLink;

/**
 `BOOL` statint whether the item has an upload link already generated.
 @since 1.0
 */
@property (readonly, nonatomic) BOOL hasUploadLink;

/**
 `BOOL` stating whether the item has been deleted.
 @since 1.0
 */
@property (readonly, nonatomic, getter = isDeleted) BOOL deleted;


////////////////////////////////////////////////////////////////////////////////
/// @name File-specific Properties
////////////////////////////////////////////////////////////////////////////////

/**
 Size of the file, in bytes.
 @since 1.0
 */
@property (readonly, nonatomic) uint64_t size;

/**
 `BOOL` stating if the server generated a thumbnail for this file.
 @since 1.0
 */
@property (readonly, nonatomic) BOOL hasThumbnail;

/**
 The file's mime type.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *mimeType;


////////////////////////////////////////////////////////////////////////////////
/// @name Folder-specific Properties
////////////////////////////////////////////////////////////////////////////////

/**
 The type of folder. For a list of possible types see <CLDItemFolderType>.
 @since 1.0
 */
@property (readonly, nonatomic) CLDItemFolderType folderType;

/**
 The folder hash.
 
 If this property is not `nil` when requesting item information and the item's contents are unchanged, you will receive the same item back.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *folderHash;

/**
 `BOOL` stating if the folder belongs to the user.
 @since 1.0
 */
@property (readonly, nonatomic, getter = isOwner) BOOL owner;

/**
 List of items contained in the folder.
 
 @warning An empty array or nil does not necessarily mean the folder is empty. A folder may be fetched from a server and not display it's contents due to filtering and/or API limitations.
 @see [CLDSession fetchItem:options:resultBlock:failureBlock:]
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSArray *contents;


////////////////////////////////////////////////////////////////////////////////
/// @name Icons
////////////////////////////////////////////////////////////////////////////////

/**
 String representation of the icon that should represent the item.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *iconName;


////////////////////////////////////////////////////////////////////////////////
/// @name Convenience methods
////////////////////////////////////////////////////////////////////////////////

/**
 Convenience method for creating a hollow item representing the user's root folder.
 
 @return A new instance of `CLDItem`.
 @since 1.0
 */
+ (instancetype)rootFolderItem;

/**
 Convenience method to create a hollow item with a specific path.
 
 @param path The item's path.
 
 @return A new instance of `CLDItem`.
 @since 1.0
 */
+ (instancetype)itemWithPath:(NSString *)path;

/**
 Convenience method to create a hollow item with a specific path and revision hash.
 
 @param path     The item's path.
 @param revision The item's revision hash.
 
 @return A new instance of `CLDItem`.
 @since 1.0
 */
+ (instancetype)itemWithPath:(NSString *)path revision:(NSString *)revision;

/**
 Convenience method to create a hollow item with a specific path, revision hash and type.
 
 @param path     The item's path.
 @param revision The item's revision hash.
 @param type     The item's type.
 
 @return A new instance of `CLDItem`.
 @since 1.0
 */
+ (instancetype)itemWithPath:(NSString *)path revision:(NSString *)revision type:(CLDItemType)type;

/**
 Convenience method to create a hollow item with a specific path, revision hash, type and folder type.
 
 @param path        The item's path.
 @param revision    The item's revision hash.
 @param type        The item's type.
 @param folderType  The item's folder type.
 
 @return A new instance of `CLDItem`.
 @since 1.0
 */
+ (instancetype)itemWithPath:(NSString *)path revision:(NSString *)revision type:(CLDItemType)type folderType:(CLDItemFolderType)folderType;

/**
 Convenience method to create a hollow item specifically for uploads.
 
 @param url      The URL with the file or asset location.
 @param path     The item's path.
 @param revision The item's revision hash.
 
 @return A new instance of `CLDItem`.
 @since 1.0
 */
+ (instancetype)itemForUploadingWithURL:(NSURL *)url
                                   path:(NSString *)path
                               revision:(NSString *)revision;

#if TARGET_OS_IPHONE
/**
 Convenience method to create a hollow item specifically for uploading assets from the user's library.
 
 @param asset    The asset to be uploaded.
 @param path     The item's path.
 @param revision The item's revision hash.
 
 @return A new instance of `CLDItem`.
 @since 1.0
 */
+ (instancetype)itemForUploadingWithAsset:(ALAsset *)asset
                                     path:(NSString *)path
                                 revision:(NSString *)revision;

#endif

@end
