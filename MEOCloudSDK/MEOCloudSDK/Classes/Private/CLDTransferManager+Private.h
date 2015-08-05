//
//  CLDTransferManager+Private.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 14/07/14.
//
//

#import <MEOCloudSDK/CLDTransferManager.h>

typedef void(^CLDTransferBackgroundEventsCompletionHandler)();

@interface CLDTransferManager (Private)
@property (readonly, strong, nonatomic) NSMutableArray *transfers;
@property (readwrite, copy, nonatomic) CLDTransferBackgroundEventsCompletionHandler backgroundEventsCompletionHandler;
@property (readwrite, copy, nonatomic) CLDTransferBackgroundEventsCompletionHandler backgroundEventsWithCellularAccessCompletionHandler;

- (instancetype)initWithSession:(CLDSession *)session;
- (BOOL)save;

// creating / adding transfers
- (CLDTransfer *)scheduleUploadForItem:(CLDItem *)item
                             overwrite:(BOOL)overwrite
                            background:(BOOL)background
                        cellularAccess:(BOOL)cellularAccess
                              priority:(CLDTransferPriority)priority
                                 error:(NSError **)error;
- (CLDTransfer *)scheduleDownloadForItem:(CLDItem *)item
                              background:(BOOL)background
                          cellularAccess:(BOOL)cellularAccess
                                priority:(CLDTransferPriority)priority
                                   error:(NSError **)error;
@end