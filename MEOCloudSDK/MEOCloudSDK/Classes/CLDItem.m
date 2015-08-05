//
//  MCItem.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

#if TARGET_OS_IPHONE
@import AssetsLibrary;
#endif

#import "CLDItem.h"

#define CLDItemIconApplicationDMG @"aplication_dmg"
#define CLDItemIconApplicationEXE @"aplication_exe"
#define CLDItemIconAudioAAC @"audio_aac"
#define CLDItemIconAudioAIF @"audio_aif"
#define CLDItemIconAudioFLAC @"audio_flac"
#define CLDItemIconAudioM4A @"audio_m4a"
#define CLDItemIconAudioMP3 @"audio_mp3"
#define CLDItemIconAudioWAV @"audio_wav"
#define CLDItemIconCompressedRAR @"compressed_folder_rar"
#define CLDItemIconCompressedZIP @"compressed_folder_zip"
#define CLDItemIconImageBMP @"image_bmp"
#define CLDItemIconImageGIF @"image_gif"
#define CLDItemIconImageJPG @"image_jpg"
#define CLDItemIconImagePNG @"image_png"
#define CLDItemIconImagePSD @"image_psd"
#define CLDItemIconImageTIF @"image_tif"
#define CLDItemIconPresentationPDF @"presentation_pdf"
#define CLDItemIconPresentationPPS @"presentation_pps"
#define CLDItemIconPresentationPPT @"presentation_ppt"
#define CLDItemIconTextCSS @"text_css"
#define CLDItemIconTextDOC @"text_doc"
#define CLDItemIconTextHTM @"text_htm"
#define CLDItemIconTextICS @"text_ics"
#define CLDItemIconTextJS @"text_js"
#define CLDItemIconTextPHP @"text_php"
#define CLDItemIconTextRTF @"text_rtf"
#define CLDItemIconTextTXT @"text_txt"
#define CLDItemIconTextVOB @"text_vob"
#define CLDItemIconTextXLS @"text_xls"
#define CLDItemIconTextXML @"text_xml"
#define CLDItemIconVectorImageEPS @"vector_image_eps"
#define CLDItemIconVectorImageSVG @"vector_image_svg"
#define CLDItemIconVideo3GP @"video_3gp"
#define CLDItemIconVideoAVI @"video_avi"
#define CLDItemIconVideoFLV @"video_flv"
#define CLDItemIconVideoMKV @"video_mkv"
#define CLDItemIconVideoMOV @"video_mov"
#define CLDItemIconVideoMPG @"video_mpg"
#define CLDItemIconVideoSWF @"video_swf"
#define CLDItemIconVideoWMV @"video_wmv"

@interface CLDSession (CLDItem)
- (NSString *)_accessModeSandbox;
@end

@interface CLDItem ()
@property (readwrite, strong, nonatomic) NSString *sessionIdentifier;
@property (readwrite, nonatomic) CLDItemType type;
@property (readwrite, nonatomic) BOOL hollow;
@property (readwrite, nonatomic, getter = isSandbox) BOOL sandbox;
@property (readwrite, strong, nonatomic) NSString *revision;
@property (readwrite, strong, nonatomic) NSString *path;
@property (readwrite, strong, nonatomic) NSDate *lastModified;
@property (readwrite, strong, nonatomic) NSDate *lastModifiedMTime;
@property (readwrite, nonatomic) BOOL hasPublicLink;
@property (readwrite, nonatomic) BOOL hasUploadLink;
@property (readwrite, strong, nonatomic) NSString *iconName;
@property (readwrite, nonatomic) uint64_t size;
@property (readwrite, nonatomic) BOOL hasThumbnail;
@property (readwrite, nonatomic, getter = isDeleted) BOOL deleted;
@property (readwrite, strong, nonatomic) NSString *mimeType;
@property (readwrite, nonatomic) CLDItemFolderType folderType;
@property (readwrite, nonatomic, getter = isOwner) BOOL owner;
@property (readwrite, strong, nonatomic) NSArray *contents;
@property (readwrite, strong, nonatomic) NSString *folderHash;
@property (readwrite, strong, nonatomic) NSURL *uploadURL;
@end

@implementation CLDItem

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    _sessionIdentifier = [aDecoder decodeObjectForKey:@"sessionIdentifier"];
    _type = [aDecoder decodeIntegerForKey:@"type"];
    _hollow = [aDecoder decodeBoolForKey:@"hollow"];
    _sandbox = [aDecoder decodeBoolForKey:@"sandbox"];
    _revision = [aDecoder decodeObjectForKey:@"revision"];
    _path = [aDecoder decodeObjectForKey:@"path"];
    _lastModified = [aDecoder decodeObjectForKey:@"lastModified"];
    _lastModifiedMTime = [aDecoder decodeObjectForKey:@"lastModifiedMTime"];
    _hasPublicLink = [aDecoder decodeBoolForKey:@"hasPublicLink"];
    _iconName = [aDecoder decodeObjectForKey:@"iconName"];
    _size = [aDecoder decodeInt64ForKey:@"size"];
    _hasThumbnail = [aDecoder decodeBoolForKey:@"hasThumbnail"];
    _deleted = [aDecoder decodeBoolForKey:@"deleted"];
    _mimeType = [aDecoder decodeObjectForKey:@"mimeType"];
    _folderType = [aDecoder decodeIntegerForKey:@"folderType"];
    _owner = [aDecoder decodeBoolForKey:@"owner"];
    _contents = [aDecoder decodeObjectForKey:@"contents"];
    _uploadURL = [aDecoder decodeObjectForKey:@"uploadURL"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.sessionIdentifier forKey:@"sessionIdentifier"];
    [aCoder encodeInteger:self.type forKey:@"type"];
    [aCoder encodeBool:self.hollow forKey:@"hollow"];
    [aCoder encodeBool:self.isSandbox forKey:@"sandbox"];
    [aCoder encodeObject:self.revision forKey:@"revision"];
    [aCoder encodeObject:self.path forKey:@"path"];
    [aCoder encodeObject:self.lastModified forKey:@"lastModified"];
    [aCoder encodeObject:self.lastModifiedMTime forKey:@"lastModifiedMTime"];
    [aCoder encodeBool:self.hasPublicLink forKey:@"hasPublicLink"];
    [aCoder encodeObject:self.iconName forKey:@"iconName"];
    [aCoder encodeInt64:self.size forKey:@"size"];
    [aCoder encodeBool:self.hasThumbnail forKey:@"hasThumbnail"];
    [aCoder encodeBool:self.isDeleted forKey:@"deleted"];
    [aCoder encodeObject:self.mimeType forKey:@"mimeType"];
    [aCoder encodeInteger:self.folderType forKey:@"folderType"];
    [aCoder encodeBool:self.isOwner forKey:@"owner"];
    [aCoder encodeObject:self.contents forKey:@"contents"];
    [aCoder encodeObject:self.uploadURL forKey:@"uploadURL"];
}

#pragma mark - Dynamic properties

- (NSString *)name {
    if (self.path && self.path.length > 1) {
        NSString *path = [self.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        NSArray *items = [path componentsSeparatedByString:@"/"];
        return [items lastObject];
    } else {
        return nil;
    }
}

#pragma mark - Convenience methods

+ (instancetype)rootFolderItem {
    id root = [self new];
    ((CLDItem *)root).type = CLDItemTypeFolder;
    ((CLDItem *)root).path = @"/";
    ((CLDItem *)root).hollow = YES;
    return root;
}

+ (instancetype)itemWithPath:(NSString *)path {
    return [self itemWithPath:path revision:nil];
}

+ (instancetype)itemWithPath:(NSString *)path revision:(NSString *)revision {
    return [self itemWithPath:path revision:revision type:CLDItemTypeFile];
}

+ (instancetype)itemWithPath:(NSString *)path revision:(NSString *)revision type:(CLDItemType)type {
    CLDItemFolderType folderType = (type == CLDItemTypeFolder) ? CLDItemFolderTypeNormal : CLDItemFolderTypeUnknown;
    return [self itemWithPath:path revision:revision type:type folderType:folderType];
}

+ (instancetype)itemWithPath:(NSString *)path revision:(NSString *)revision type:(CLDItemType)type folderType:(CLDItemFolderType)folderType {
    NSParameterAssert(path);
    CLDItem *item = [self new];
    item.hollow = YES;
    item.path = path;
    item.revision = revision;
    item.type = type;
    item.folderType = folderType;
    return item;
}

+ (instancetype)itemForUploadingWithURL:(NSURL *)url path:(NSString *)path revision:(NSString *)revision {
    NSParameterAssert(url);
    NSString *urlScheme = [url scheme];
    NSParameterAssert([urlScheme isEqualToString:@"file"] || [urlScheme isEqualToString:@"assets-library"]);
    NSParameterAssert(path);
    
    // create item
    CLDItem *item = [self new];
    item.hollow = YES;
    item.type = CLDItemTypeFile;
    item.path = path;
    item.revision = revision;
    item.uploadURL = url;
    
    // file specific
    if ([urlScheme isEqualToString:@"file"]) {
        NSError *error = nil;
        NSData *mappedFile = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached|NSDataReadingMappedAlways error:&error];
        if (error) return nil;
        item.size = mappedFile.length;
    }
    
    return item;
}

#if TARGET_OS_IPHONE
+ (instancetype)itemForUploadingWithAsset:(ALAsset *)asset path:(NSString *)path revision:(NSString *)revision {
    NSParameterAssert(asset);
    NSParameterAssert([asset valueForProperty:ALAssetPropertyType] != ALAssetTypeUnknown);
    
    // create item with asset's URL
    NSURL *url = [asset valueForProperty:ALAssetPropertyAssetURL];
    CLDItem *item = [self itemForUploadingWithURL:url path:path revision:revision];
    
    // populate aditional information
    ALAssetRepresentation *defaultRepresentation = asset.defaultRepresentation;
    item.size = defaultRepresentation.size;
    NSString *assetType = [asset valueForProperty:ALAssetPropertyType];
    item.iconName = assetType == ALAssetTypePhoto ? CLDItemIconImageJPG : CLDItemIconVideoMPG;
    
    return item;
}
#endif

#pragma mark - Private methods

+ (instancetype)itemWithDictionary:(NSDictionary *)dictionary session:(CLDSession *)session {
    NSParameterAssert([dictionary isKindOfClass:[NSDictionary class]]);
    NSParameterAssert(session);
    
    CLDItem *item = [self new];
    item.sessionIdentifier = session.sessionIdentifier;
    
    // commmon
    item.revision = dictionary[@"rev"];
    item.path = dictionary[@"path"];
//    item.sizeString = dictionary[@"size"];
    item.size = [dictionary[@"bytes"] unsignedIntegerValue];
    item.iconName = dictionary[@"icon"];
    item.owner = [dictionary[@"is_owner"] boolValue];
    item.sandbox = [dictionary[@"root"] isEqualToString:[session _accessModeSandbox]];
    item.type = [dictionary[@"is_dir"] boolValue] ? CLDItemTypeFolder : CLDItemTypeFile;
    item.hasThumbnail = [dictionary[@"thumb_exists"] boolValue];
    item.lastModified = [[NSDateFormatter serviceDateFormatter] dateFromString:dictionary[@"modified"]];
    item.lastModifiedMTime = [[NSDateFormatter serviceDateFormatter] dateFromString:dictionary[@"client_mtime"]];
    item.deleted = [dictionary[@"is_deleted"] boolValue];
    item.hasPublicLink = [dictionary[@"is_link"] boolValue];
    
    // type-specific properties
    switch (item.type) {
        case CLDItemTypeFile: {
            item.mimeType = dictionary[@"mime_type"];
            break;
        }
            
        case CLDItemTypeFolder: {
            item.hasUploadLink = [dictionary[@"is_upload"] boolValue];
            NSString *folderType = dictionary[@"folder_type"];
            if (folderType == nil) {
                item.folderType = CLDItemFolderTypeNormal;
            } else if ([folderType isEqualToString:@"shared"]) {
                item.folderType = CLDItemFolderTypeShared;
            } else {
                item.folderType = CLDItemFolderTypeUnknown;
            }
            item.folderHash = dictionary[@"hash"];
            NSArray *contents = dictionary[@"contents"];
            if (contents) {
                NSMutableArray *contentItems = [NSMutableArray new];
                for (NSDictionary *contentItem in contents) {
                    [contentItems addObject:[self itemWithDictionary:contentItem session:session]];
                }
                item.contents = [NSArray arrayWithArray:contentItems];
            }
            break;
        }
    }
    
    return item;
}

- (NSString *)trimmedPath {
    return [self.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
}

@end
