//
//  MCTransferManager.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

#import "CLDTransferManager.h"

NSString* const kCLDTransferAddedNotification = @"kCLDTransferAddedNotification";
NSString* const kCLDTransferRemovedNotification = @"kCLDTransferRemovedNotification";
NSString* const kCLDTransferStartedNotification = @"kCLDTransferStartedNotification";
NSString* const kCLDTransferSuspendedNotification = @"kCLDTransferSuspendedNotification";
NSString* const kCLDTransferFinishedNotification = @"kCLDTransferFinishedNotification";
NSString* const kCLDTransferUpdatedProgressNotification = @"kCLDTransferUpdatedProgressNotification";
NSString* const kCLDTransferKey = @"kCLDTransferKey";

// CLDTransfer category to expose private properties
@interface CLDTransfer (TransferManager)
@property (readwrite, nonatomic) BOOL allowsCellularAccess;
@property (readwrite, nonatomic) CLDTransferPriority priority;
@property (readwrite, nonatomic) CLDTransferType type;
@property (readwrite, strong, nonatomic) NSURLSession *urlSession;
@property (readwrite, weak, nonatomic) CLDTransferManager *manager;
@end

// CLDTransferOperation category to expose private properties and methods
@interface CLDTransferOperation (TransferManager)
@property (readwrite, strong, nonatomic) NSURL *temporaryDownloadedFileURL;
- (void)finishOperationWithError:(NSError *)error;
- (void)addReceivedData:(NSData *)data;
@end

@interface CLDTransferManager () <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>
@property (readwrite, weak, nonatomic) CLDSession *session;
//@property (readwrite, strong, nonatomic) NSURLSession *backgroundURLSession;
@property (readwrite, strong, nonatomic) NSURLSession *foregroundURLSession;
//@property (readwrite, strong, nonatomic) NSURLSession *backgroundURLSessionWithCellularAccess;
@property (readwrite, strong, nonatomic) NSURLSession *foregroundURLSessionWithCellularAccess;
@property (readwrite, strong, nonatomic) NSMutableArray *transfers;
@property (readwrite, strong, nonatomic) NSOperationQueue *highPriorityOperationQueue;
@property (readwrite, strong, nonatomic) NSOperationQueue *normalPriorityOperationQueue;
@property (readwrite, strong, nonatomic) NSMutableArray *operationDump;
@property (readwrite, copy, nonatomic) CLDTransferBackgroundEventsCompletionHandler backgroundEventsCompletionHandler;
@property (readwrite, copy, nonatomic) CLDTransferBackgroundEventsCompletionHandler backgroundEventsWithCellularAccessCompletionHandler;
@end

@implementation CLDTransferManager {
    NSUInteger _backgroundTaskIdentifier;
}

#pragma mark - Initialization

- (instancetype)initWithSession:(CLDSession *)session {
    NSParameterAssert(session);
    self = [super init];
    if (self) {
        self.session = session;
        
        [self _createURLSessions];
        
        self.transfers = [NSMutableArray new];
        self.highPriorityOperationQueue = [NSOperationQueue new];
        self.highPriorityOperationQueue.maxConcurrentOperationCount = 1;
        self.normalPriorityOperationQueue = [NSOperationQueue new];
        self.normalPriorityOperationQueue.maxConcurrentOperationCount = 1;
        self.operationDump = [NSMutableArray new];
        
        [self _loadTransfersIfTheyExist];
        
        [self _registerForApplicationStateChangeNotification];
        
        _backgroundTaskIdentifier = NSNotFound;
        [self _registerForTransferNotifications];
    }
    return self;
}

- (void)dealloc {
    [self _unregisterForTransferNotifications];
}

#pragma mark - Loading / saving transfers

- (NSURL *)_transfersArchiveURL {
    NSURL *applicationSupport = [CLDUtil applicationSupportDirectory];
    NSString *fileName = [NSString stringWithFormat:@"pt.meo.cloud.sdk.%@.transfers", self.session.sessionIdentifier];
    return [applicationSupport URLByAppendingPathComponent:fileName];
}

- (void)_loadTransfersIfTheyExist {
    NSString *filePath = [self _transfersArchiveURL].path;
    NSArray *transfers = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    for (CLDTransfer *transfer in transfers) {
        transfer.manager = self;
        
        // only create/add operations for pending or executing transfers
        if (transfer.state == CLDTransferStatePending || transfer.state == CLDTransferStateTransfering) {
            [self _addOperationsForTransfer:transfer];
        }
    }
    if (transfers) self.transfers = [transfers mutableCopy];
}

- (BOOL)save {
//#ifdef DEBUG
//    NSDate *date = [NSDate date];
//#endif
    @try {
        NSString *filePath = [self _transfersArchiveURL].path;
        [NSKeyedArchiver archiveRootObject:self.transfers toFile:filePath];
    }
    @catch (NSException *exception) {
        CLDLog(@"Could not save. Error: %@", exception.description);
    }
//#ifdef DEBUG
//    double elapsedTime = [[NSDate date] timeIntervalSinceDate:date];
//    CLDLog(@"Saved transfer list. Took %f seconds", elapsedTime);
//#endif
}

#pragma mark - Handle background notifications

- (void)_registerForApplicationStateChangeNotification {
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleApplicationStateChangeNotification:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
#else
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleApplicationStateChangeNotification:)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
#endif
}

- (void)_handleApplicationStateChangeNotification:(NSNotification *)notification {
#if TARGET_OS_IPHONE
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if ([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification] && state == UIApplicationStateBackground) {
        [self save];
    }
#else
    [self save];
#endif
}

#pragma mark - Handle transfer notifications

- (void)_registerForTransferNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleTransferNotification:)
                                                 name:kCLDTransferStartedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleTransferNotification:)
                                                 name:kCLDTransferFinishedNotification
                                               object:nil];
}

- (void)_unregisterForTransferNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCLDTransferStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCLDTransferFinishedNotification object:nil];
}

- (void)_handleTransferNotification:(NSNotification *)notification {
    @synchronized(self) {
        if ([notification.name isEqualToString:kCLDTransferStartedNotification]) {
            [self beginBackgroundTaskIfNeeded:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self save];
                });
            }];
        } else if ([notification.name isEqualToString:kCLDTransferFinishedNotification]) {

            BOOL hasPendingTransfer = NO;
            for (CLDTransfer *transfer in self.transfers) {
                if (transfer.state == CLDTransferStatePending || transfer.state == CLDTransferStateTransfering) {
                    hasPendingTransfer = YES;
                    break;
                }
            }
            if (hasPendingTransfer == NO) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self endBackgroundTaskIfNeeded];
                });
            }
        }
    }
}

- (void)beginBackgroundTaskIfNeeded:(void (^)(void))expirationHandler
{
#if TARGET_OS_IPHONE
    if (_backgroundTaskIdentifier == NSNotFound) {
        _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            if(expirationHandler) expirationHandler();
        }];
    }
#endif
}

- (void)endBackgroundTaskIfNeeded
{
#if TARGET_OS_IPHONE
    if (_backgroundTaskIdentifier != NSNotFound) {
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
        _backgroundTaskIdentifier = NSNotFound;
    }
#endif
}

#pragma mark - Creating / removing transfers

- (void)_addTransfer:(CLDTransfer *)transfer {
    NSParameterAssert(transfer);
    [self.transfers addObject:transfer];
    [self _addOperationsForTransfer:transfer];
    [CLDUtil postNotificationNamed:kCLDTransferAddedNotification object:self userInfo:@{kCLDTransferKey:transfer}];
    [self save];
}

- (void)_addOperationsForTransfer:(CLDTransfer *)transfer {
    NSParameterAssert(transfer.manager == self);
    NSOperationQueue *queue;
    if (transfer.priority == CLDTransferPriorityHigh) queue = self.highPriorityOperationQueue;
    else queue = self.normalPriorityOperationQueue;
    NSArray *operations = transfer.operations;
    if (queue.operationCount > 0) {
        [(NSOperation *)operations.firstObject addDependency:queue.operations.lastObject];
    }
    [queue addOperations:operations waitUntilFinished:NO];
}

- (void)_removeTransfer:(CLDTransfer *)transfer {
    NSParameterAssert(transfer);
    if ([self.transfers containsObject:transfer]) {
        [self.transfers removeObject:transfer];
        [CLDUtil postNotificationNamed:kCLDTransferRemovedNotification object:self userInfo:@{kCLDTransferKey:transfer}];
    }
    [self save];
}

- (CLDTransfer *)scheduleUploadForItem:(CLDItem *)item
                             overwrite:(BOOL)overwrite
                            background:(BOOL)background
                        cellularAccess:(BOOL)cellularAccess
                              priority:(CLDTransferPriority)priority
                                 error:(NSError *__autoreleasing *)error {
    NSParameterAssert(item);
    if (!item.hollow || !item.uploadURL) {
        if (error) *error = [CLDError errorWithCode:CLDErrorCodeInvalidItem];
        return nil;
    }
    CLDTransfer *transfer = [[CLDTransfer alloc] initWithManager:self];
    transfer.type = CLDTransferTypeUpload;
    transfer.item = item;
    transfer.shouldOverwrite = overwrite;
    transfer.backgroundTransfer = background;
    transfer.allowsCellularAccess = cellularAccess;
    transfer.priority = priority;
    [self _addTransfer:transfer];
    return transfer;
}

- (CLDTransfer *)scheduleDownloadForItem:(CLDItem *)item
                              background:(BOOL)background
                          cellularAccess:(BOOL)cellularAccess
                                priority:(CLDTransferPriority)priority
                                   error:(NSError *__autoreleasing *)error {
    NSParameterAssert(item);
    if (!item.path) {
        if (error) *error = [CLDError errorWithCode:CLDErrorCodeInvalidItem];
        return nil;
    }
    CLDTransfer *transfer = [[CLDTransfer alloc] initWithManager:self];
    transfer.type = CLDTransferTypeDownload;
    transfer.item = item;
    transfer.backgroundTransfer = background;
    transfer.allowsCellularAccess = cellularAccess;
    transfer.priority = priority;
    [self _addTransfer:transfer];
    return transfer;
}

#pragma mark - Obtaining transfers

- (NSArray *)transfersOfType:(CLDTransferType)type {
    NSMutableArray *transfers = self.transfers;
    if (type != CLDTransferTypeAll) {
        transfers = [NSMutableArray new];
        for (CLDTransfer *transfer in self.transfers) {
            if (transfer.type == type) {
                [transfers addObject:transfer];
            }
        }
    }
    return [NSArray arrayWithArray:transfers];
}

#pragma mark - Connections

- (void)_createURLSessions {
    @synchronized(self) {
        
        NSDictionary *additionalHeaders = [self.session _signedMutableURLRequestWithURL:[NSURL URLWithString:@""]].allHTTPHeaderFields;
        
//        // create background session
//        NSURLSessionConfiguration *backgroundConfiguration;
//        if (CLD_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
//            backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.session.sessionIdentifier];
//        } else {
//            backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:self.session.sessionIdentifier];
//        }
//        backgroundConfiguration.allowsCellularAccess = NO;
//        backgroundConfiguration.HTTPAdditionalHeaders = additionalHeaders;
//        NSURLSession *backgroundURLSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:nil];
//        
//        // create background session with cellular access
//        NSURLSessionConfiguration *backgroundConfigurationWithCellularAccess;
//        NSString *sessionIdentifier = [NSString stringWithFormat:@"%@_cellularAccess", self.session.sessionIdentifier];
//        if (CLD_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
//            backgroundConfigurationWithCellularAccess = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionIdentifier];
//        } else {
//            backgroundConfigurationWithCellularAccess = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionIdentifier];
//        }
//        backgroundConfiguration.allowsCellularAccess = YES;
//        backgroundConfiguration.HTTPAdditionalHeaders = additionalHeaders;
//        NSURLSession *backgroundURLSessionWithCellularAccess = [NSURLSession sessionWithConfiguration:backgroundConfigurationWithCellularAccess delegate:self delegateQueue:nil];
        
        // create foreground session
        NSURLSessionConfiguration *foregroundConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        foregroundConfiguration.allowsCellularAccess = NO;
        foregroundConfiguration.HTTPAdditionalHeaders = additionalHeaders;
        NSURLSession *foregroundURLSession = [NSURLSession sessionWithConfiguration:foregroundConfiguration delegate:self delegateQueue:nil];
        
        // create foreground session with cellular access
        NSURLSessionConfiguration *foregroundConfigurationWithCellularAccess = [NSURLSessionConfiguration defaultSessionConfiguration];
        foregroundConfiguration.allowsCellularAccess = YES;
        foregroundConfiguration.HTTPAdditionalHeaders = additionalHeaders;
        NSURLSession *foregroundURLSessionWithCellularAccess = [NSURLSession sessionWithConfiguration:foregroundConfigurationWithCellularAccess delegate:self delegateQueue:nil];
        
//        [self.backgroundURLSession invalidateAndCancel];
//        self.backgroundURLSession = backgroundURLSession;
//        
//        [self.backgroundURLSessionWithCellularAccess invalidateAndCancel];
//        self.backgroundURLSessionWithCellularAccess = backgroundURLSessionWithCellularAccess;
        
        [self.foregroundURLSession invalidateAndCancel];
        self.foregroundURLSession = foregroundURLSession;
        
        [self.foregroundURLSessionWithCellularAccess invalidateAndCancel];
        self.foregroundURLSessionWithCellularAccess = foregroundURLSessionWithCellularAccess;
        
    }
}

- (NSURLSession *)urlSessionForTransfer:(CLDTransfer *)transfer {
//    if (transfer.isBackgroundTransfer) {
//        if (transfer.allowsCellularAccess) {
//            return self.backgroundURLSessionWithCellularAccess;
//        } else {
//            return self.backgroundURLSession;
//        }
//    } else {
        if (transfer.allowsCellularAccess) {
            return self.foregroundURLSessionWithCellularAccess;
        } else {
            return self.foregroundURLSession;
        }
//    }
}

#pragma mark - NSURLSessionDelegate methods

- (CLDTransferOperation *)_operationForTask:(NSURLSessionTask *)task {
    CLDTransferOperation *operation = nil;
    NSArray *queues = @[self.highPriorityOperationQueue, self.normalPriorityOperationQueue];
    for (NSOperationQueue *queue in queues) {
        for (CLDTransferOperation *o in queue.operations) {
            if (o.task == task) {
                operation = o;
                break;
            }
        }
        if (operation) break;
    }
    return operation;
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
//    CLDTransferBackgroundEventsCompletionHandler block;
//    if (session == self.backgroundURLSession) {
//        block = self.backgroundEventsCompletionHandler;
//    } else if (session == self.backgroundURLSessionWithCellularAccess) {
//        block = self.backgroundEventsWithCellularAccessCompletionHandler;
//    }
//    if (block) {
//        dispatch_async(dispatch_get_main_queue(), block);
//    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    CLDTransferOperation *operation = [self _operationForTask:task];
    if (operation) {
        [operation finishOperationWithError:error];
    } else {
        CLDLog(@"Received URLSession:task:didCompleteWithError: for a non-existing task!");
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    CLDTransferOperation *operation = [self _operationForTask:dataTask];
    if (operation.transfer.type == CLDTransferTypeUpload) {
        [operation addReceivedData:data];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    CLDTransferOperation *operation = [self _operationForTask:downloadTask];
    if (operation) {
        NSString *tempFileName = [NSString stringWithFormat:@"pt.meo.cloud.sdk.dl.%@.tmp", operation.transfer.transferIdentifier];
        NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
        NSURL *tempFileLocation = [NSURL fileURLWithPath:tempFilePath];
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:tempFileLocation error:&error];
        operation.temporaryDownloadedFileURL = [tempFileLocation fileReferenceURL];
    } else {
        CLDLog(@"Received URLSession:downloadTask:didFinishDownloadingToURL: for a non-existing task!");
    }
}

#pragma mark - Clearing transfers

- (void)_clearTransferWithState:(CLDTransferState)state {
    NSMutableArray *transfersToRemove = [NSMutableArray new];
    for (CLDTransfer *transfer in self.transfers) {
        if (transfer.state == state) {
            [transfersToRemove addObject:transfer];
        }
    }
    for (CLDTransfer *transfer in transfersToRemove) {
        if (state != CLDTransferStateFailed && state != CLDTransferStateFinished) {
            [transfer cancel];
        }
        [self _removeTransfer:transfer];
    }
}

- (void)clearTransfer:(CLDTransfer *)transfer {
    if (transfer && (transfer.state == CLDTransferStateFailed || transfer.state == CLDTransferStateFinished)) {
        [self _removeTransfer:transfer];
    }
}

- (void)clearFailedTransfers {
    [self _clearTransferWithState:CLDTransferStateFailed];
}

- (void)clearFinishedTransfers {
    [self _clearTransferWithState:CLDTransferStateFinished];
}

#pragma mark - Cancelling everything

- (void)cancelAndRemoveAllTransfers {
    for (CLDTransfer *transfer in self.transfers) {
        [transfer cancel];
    }
    [self.transfers removeAllObjects];
}



@end
