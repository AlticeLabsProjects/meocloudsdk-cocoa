//
//  CLDTransfer+Private.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 16/07/14.
//
//

#import <MEOCloudSDK/CLDTransfer.h>

@class CLDTransferManager;

typedef void(^CLDTransferDownloadResultBlock)(NSURL *fileURL);
typedef void(^CLDTransferUploadResultBlock)(CLDItem *newItem);
typedef void(^CLDTransferFailureBlock)(NSError *error);

@interface CLDTransfer (Private) <NSCoding>
@property (readwrite, strong, nonatomic) CLDItem *item;
@property (readwrite, nonatomic, getter = isBackgroundTransfer) BOOL backgroundTransfer;
@property (readwrite, strong, nonatomic) NSURL *downloadedFileURL;
@property (readwrite, strong, nonatomic) CLDItem *uploadedItem;

@property (readonly, strong, nonatomic) NSString *transferIdentifier;
@property (readonly, strong, nonatomic) NSURLSession *urlSession;
@property (readwrite, strong, nonatomic) NSString *uploadIdentifier;
@property (readonly, strong, nonatomic) NSArray *operations;
@property (readwrite, copy, nonatomic) CLDTransferDownloadResultBlock downloadResultBlock;
@property (readwrite, copy, nonatomic) CLDTransferUploadResultBlock uploadResultBlock;
@property (readwrite, copy, nonatomic) CLDTransferFailureBlock failureBlock;

- (instancetype)initWithManager:(CLDTransferManager *)manager;
- (void)cancelWithError:(NSError *)error;

@end