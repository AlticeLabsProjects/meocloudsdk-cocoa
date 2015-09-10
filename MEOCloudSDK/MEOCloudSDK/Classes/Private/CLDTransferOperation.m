//
//  CLDTransferOperation.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 16/07/14.
//
//

#import "CLDTransferOperation.h"

#if TARGET_OS_IPHONE
#import <AssetsLibrary/AssetsLibrary.h>
#endif
static void *kCLDTransferOperationKVOContext = &kCLDTransferOperationKVOContext;

@interface CLDTransfer (TransferOperation)
@property (readwrite, nonatomic) uint64_t bytesTotal;
@property (readonly, weak, nonatomic) CLDTransferManager *manager;
@property (readonly, nonatomic) NSUInteger chunkSize;
- (void)updateWithByteOffset:(int64_t)byteOffset bytesTransfered:(int64_t)bytesTransfered totalBytesExpectedToTransfer:(int64_t)totalBytesExpectedToTransfer;
- (void)updateTaskIdentifier:(NSUInteger)taskIdentifier forChunkOffset:(uint64_t)chunkOffset;
@end

@interface CLDTransferManager (TransferOperation)
@property (readonly, strong, nonatomic) NSURLSession *backgroundURLSession;
@property (readonly, strong, nonatomic) NSURLSession *foregroundURLSession;
//@property (readwrite, strong, nonatomic) NSURLSession *backgroundURLSessionWithCellularAccess;
//@property (readwrite, strong, nonatomic) NSURLSession *foregroundURLSessionWithCellularAccess;
@end

@interface CLDTransferOperation ()
@property (readwrite, weak, nonatomic) CLDTransfer *transfer;
@property (readwrite, strong, nonatomic) NSURLSessionTask *task;
@property (readwrite, nonatomic) NSUInteger taskIdentifier;
@property (readwrite) CLDTransferOperationState state;
@property (readwrite, nonatomic) uint64_t byteOffset;
@property (readwrite, strong, nonatomic) NSURL *temporaryDownloadedFileURL;
@property (readwrite, strong, nonatomic) NSMutableData *receivedData; // uploads only
@end

@implementation CLDTransferOperation {
    BOOL _isObservingTask;
    BOOL _didRegisterForBackgroundExecuting;
    NSUInteger _backgroundTaskIdentifier;
    NSCondition *_stateCondition;
    CLDTransferOperationState _state;
}

#pragma mark - Initialization

- (instancetype)initWithTransfer:(CLDTransfer *)transfer taskIdentifier:(NSUInteger)taskIdentifier {
    NSParameterAssert(transfer);
    NSParameterAssert(transfer.urlSession);
    self = [super init];
    if (self) {
        self.transfer = transfer;
        self.taskIdentifier = taskIdentifier;
        self.state = CLDTransferOperationStatePending;
        _stateCondition = [NSCondition new];
    }
    return self;
}

+ (instancetype)downloadOperationForTransfer:(CLDTransfer *)transfer taskIdentifier:(NSUInteger)taskIdentifier {
    return [[self alloc] initWithTransfer:transfer taskIdentifier:taskIdentifier];
}

+ (instancetype)uploadOperationForTransfer:(CLDTransfer *)transfer chunkOffset:(uint64_t)offset taskIdentifier:(NSUInteger)taskIdentifier {
    CLDTransferOperation *operation = [[self alloc] initWithTransfer:transfer taskIdentifier:taskIdentifier];
    operation.byteOffset = offset;
    return operation;
}

#pragma mark - Operation

- (void)main {
    // validate if the operation can be performed
    [self validate];
    
    self.state = CLDTransferOperationStateExecuting;
    
    // check if this session has a background task already running
//    NSURLSession *backgroundSession;
//    if (self.transfer.allowsCellularAccess) backgroundSession = self.transfer.manager.backgroundURLSessionWithCellularAccess;
//    else backgroundSession = self.transfer.manager.backgroundURLSession;
//    NSArray *tasks = [CLDUtil outstandingTasksForURLSession:backgroundSession];
//    for (NSURLSessionTask *task in tasks) {
//        if (task.taskIdentifier == self.taskIdentifier) {
//            self.task = task;
//            break;
//        }
//    }
    
    // no task running? Let's take care of that.
    if (!self.task) {
        switch (self.transfer.type) {
            case CLDTransferTypeDownload:
                [self createDownloadTask];
                break;
            case CLDTransferTypeUpload:
                [self createUploadTask];
                break;
            case CLDTransferTypeAll:
                return; // this should never happen!
        }
    }
    
    // we need this! :)
    [_stateCondition waitUntilDate:[NSDate distantFuture] whileCondition:^BOOL{
        return self.state == CLDTransferOperationStateExecuting;
    }];
}

- (void)validate {
    if (self.transfer == nil || self.transfer.transferIdentifier == nil) {
        CLDLog(@"Cancelled transfer operation because `transfer` was nil.");
        self.state = CLDTransferOperationStateCancelled;
    }
}

- (void)finishOperationWithError:(NSError *)error {
    switch (self.transfer.type) {
        case CLDTransferTypeDownload:
            [self finishDownloadWithError:error];
            break;
        case CLDTransferTypeUpload:
            [self finishUploadWithError:error];
            break;
        case CLDTransferTypeAll:
            return; // this should never happen!
    }
}

#pragma mark - Properties

- (CLDTransferOperationState)state {
    return _state;
}

- (void)setState:(CLDTransferOperationState)state {
    [_stateCondition signalWithBlock:^{
        _state = state;
    }];
}

- (void)setTask:(NSURLSessionTask *)task {
    @synchronized(self) {
        if (_task) [self endObservingTask:_task];
        _task = task;
        if (_task) [self beginObservingTask:_task];
    }
}

#if TARGET_OS_IPHONE
#pragma mark - Asset / File

- (ALAsset *)asset {
    NSCondition *condition = [NSCondition new];
    __block BOOL finishedFetch = NO;
    __block ALAsset *assetToReturn = nil;
    ALAssetsLibrary *library = [CLDUtil assetsLibrary];
    [library assetForURL:self.transfer.item.uploadURL resultBlock:^(ALAsset *asset) {
        [condition signalWithBlock:^{
            assetToReturn = asset;
            finishedFetch = YES;
        }];
    } failureBlock:^(NSError *error) {
        [condition signalWithBlock:^{
            finishedFetch = YES;
            CLDLog(@"Cancelling transfer because asset is no longer in library!");
            [self.transfer cancelWithError:[CLDError errorWithCode:CLDErrorCodeResourceNotFound]];
        }];
    }];
    [condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:5] whileCondition:^BOOL{ return !finishedFetch; }];
    return assetToReturn;
}
#endif

#pragma mark - Uploading

- (BOOL)_isChunkCommit {
    return !(self.byteOffset < self.transfer.item.size);
}

- (NSURL *)_temporaryChunkFileURL {
    NSString *fileName = [NSString stringWithFormat:@"pt.meo.cloud.sdk.transfer.%@.%lul", self.transfer.transferIdentifier, (unsigned long)self.byteOffset];
    NSURL *fileURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    return [fileURL URLByAppendingPathComponent:fileName];
}

- (void)createUploadTask {
    [self validate];
    
    // validate if upload path is available before uploading data
    // valid = if metadata fetch for that folder does not return CLDErrorCodeResourceNotFound
    NSCondition *condition = [NSCondition new];
    __block BOOL finished = NO;
    __block BOOL pathIsValid = NO;
    NSString *path = [self.transfer.item.path stringByDeletingLastPathComponent];
    CLDItem *item = [CLDItem itemWithPath:path];
    CLDSession *session = self.transfer.manager.session;
    [session fetchItem:item options:CLDSessionFetchItemOptionNone resultBlock:^(CLDItem *item) {
        [condition signalWithBlock:^{
            finished = YES;
            if (item.isDeleted == NO) {
                pathIsValid = YES;
            }
        }];
    } failureBlock:^(NSError *error) {
        [condition signalWithBlock:^{
            finished = YES;
            if (([error.domain isEqualToString:CLDErrorDomain] && error.code == CLDErrorCodeResourceNotFound) == NO) {
                pathIsValid = YES;
            }
        }];
    }];
    [condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:10] whileCondition:^BOOL{ return !finished; } timeOutBlock:^{
        // if the condition times out we assume the path is valid and let NSURLSession deal with the rest
        pathIsValid = YES;
    }];
    if (!pathIsValid) {
        CLDLog(@"Cancelling transfer because path for upload is invalid!");
        [self.transfer cancelWithError:[CLDError errorWithCode:CLDErrorCodeResourceNotFound]];
        return;
    }
    
    if ([self _isChunkCommit]) {
        [self createChunkCommitTask];
    } else {
        [self createChunkUploadTask];
    }
}

- (void)createChunkUploadTask {
    CLDItem *item = self.transfer.item;
    NSData *dataToSend = nil;
    
    // range of bytes to send
    uint64_t totalBytes = item.size;
    uint64_t chunkOffset = self.byteOffset;
    uint64_t chunkSize = (NSUInteger)((chunkOffset + self.transfer.chunkSize < totalBytes) ? self.transfer.chunkSize : totalBytes - chunkOffset);
    
    // temporary file URL
    NSURL *fileURL = [self _temporaryChunkFileURL];
    
    // temporary file already exists (from previous attempts)?
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path] == NO) {
        // is it a file or an asset?
        BOOL errorAccessingFileOrAsset = NO;
        if ([item.uploadURL isFileURL]) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL isDirectory = NO;
            BOOL fileExists = [fileManager fileExistsAtPath:item.uploadURL.path isDirectory:&isDirectory];
            if (fileExists && !isDirectory) {
                
                NSData *mappedFile = [NSData dataWithContentsOfURL:item.uploadURL options:NSDataReadingUncached|NSDataReadingMappedAlways error:nil];
                NSRange range = NSMakeRange((NSUInteger)chunkOffset, (NSUInteger)chunkSize);
                Byte *byteData = (Byte*)malloc(range.length);
                [mappedFile getBytes:byteData range:range];
                dataToSend = [NSData dataWithBytes:byteData length:(NSUInteger)chunkSize];
                free(byteData);
                
            } else {
                errorAccessingFileOrAsset = YES;
            }
            
        }
#if TARGET_OS_IPHONE
        else if ([item.uploadURL.scheme isEqualToString:@"assets-library"]) {
            ALAsset *asset = [self asset];
            if (asset) {
                ALAssetRepresentation *assetRepresentation = asset.defaultRepresentation;
                Byte *byteData = (Byte*)malloc((NSUInteger)chunkSize);
                NSError *error = nil;
                [assetRepresentation getBytes:byteData fromOffset:chunkOffset length:(NSUInteger)chunkSize error:&error];
                if (!error) {
                    dataToSend = [NSData dataWithBytes:byteData length:(NSUInteger)chunkSize];
                } else {
                    errorAccessingFileOrAsset = YES;
                }
                free(byteData);
            } else {
                errorAccessingFileOrAsset = YES;
            }
        }
#endif
        else {
            errorAccessingFileOrAsset = YES;
        }
        
        if (errorAccessingFileOrAsset || !dataToSend) {
            [self.transfer cancelWithError:[CLDError errorWithCode:CLDErrorCodeResourceNotFound]];
            return;
        }
        
        // save data to temporary file
        NSAssert([dataToSend writeToURL:fileURL atomically:YES], @"Could not create chunk file!");
    }
    
    // generate URL
    CLDSession *session = [CLDSession sessionWithIdentifier:self.transfer.sessionIdentifier];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    if (self.transfer.uploadIdentifier) parameters[@"upload_id"] = self.transfer.uploadIdentifier;
    parameters[@"offset"] = @(chunkOffset);
    NSURL *url = [session _serviceURLForEndpoint:CLDSessionEndpointContentAPI path:@"ChunkedUpload" query:parameters];
    
    // create request
    NSMutableURLRequest *request = [session _signedMutableURLRequestWithURL:url];
    request.HTTPMethod = @"PUT";
    request.allowsCellularAccess = self.transfer.allowsCellularAccess;
    
    // create task and assign it to property
    // hammered because https://devforums.apple.com/message/926113
    NSURLSessionTask *task = nil;
    while (task == nil) {
        task = [self.transfer.urlSession uploadTaskWithRequest:request fromFile:fileURL];
        if (task == nil) {
            sleep(1);
        }
    }
    self.task = task;
    
    [self.transfer updateTaskIdentifier:self.task.taskIdentifier forChunkOffset:self.byteOffset];
    [self.task resume];
}

- (void)createChunkCommitTask {
    // generate URL
    CLDSession *session = [CLDSession sessionWithIdentifier:self.transfer.sessionIdentifier];
    NSString *path = [NSString stringWithFormat:@"CommitChunkedUpload/<mode>/%@", self.transfer.item.trimmedPath];
    NSURL *url = [session _serviceURLForEndpoint:CLDSessionEndpointContentAPI path:path];
    
    // create request
    NSMutableURLRequest *request = [session _signedMutableURLRequestWithURL:url];
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    if (self.transfer.uploadIdentifier) parameters[@"upload_id"] = self.transfer.uploadIdentifier;
    if (self.transfer.shouldOverwrite) {
        parameters[@"overwrite"] = @(YES);
        if (self.transfer.item.revision) parameters[@"parent_rev"] = self.transfer.item.revision;
    } else {
//        parameters[@"overwrite"] = @(NO);
//        parameters[@"prevent_rename"] = @(YES);
    }
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    request.allowsCellularAccess = self.transfer.allowsCellularAccess;
    
    NSURL *fileURL = [self _temporaryChunkFileURL];
    NSData *dataToSend = [session _postDataWithDictionary:parameters];
    NSAssert([dataToSend writeToURL:fileURL atomically:YES], @"Could not create commit file!");
    
    // create task and assign it to property
    // hammered because https://devforums.apple.com/message/926113
    NSURLSessionTask *task = nil;
    while (task == nil) {
        task = [self.transfer.urlSession uploadTaskWithRequest:request fromFile:fileURL];
        if (task == nil) {
            sleep(1);
        }
    }
    self.task = task;
    
    [self.transfer updateTaskIdentifier:self.task.taskIdentifier forChunkOffset:self.byteOffset];
    [self.task resume];
}

- (void)addReceivedData:(NSData *)data {
    if (!self.receivedData) self.receivedData = [NSMutableData new];
    [self.receivedData appendData:data];
}

- (void)finishUploadWithError:(NSError *)error {
    
    if (error) {
        self.task = nil;
        if ([error.domain isEqualToString:NSURLErrorDomain]) {
            unsigned int sleepAmount;
            if (error.code == NSURLErrorNotConnectedToInternet) {
                CLDLog(@"Not connected to internet, retrying in 5 seconds...");
                sleepAmount = 5;
            } else {
                CLDLog(@"Failed to upload due to connectivity problems, retrying...");
                sleepAmount = 1;
            }
            sleep(sleepAmount);
            [self createUploadTask];
        } else {
            CLDLog(@"Task failed due to error: %@", error);
            
            // delete previously created temporary file
            [[NSFileManager defaultManager] removeItemAtURL:[self _temporaryChunkFileURL] error:nil];
            
            // cancel the transfer
            CLDSession *session = [CLDSession sessionWithIdentifier:self.transfer.sessionIdentifier];
            CLDError *standardError = [session _errorFromStatusCode:NSNotFound error:error];
            [self.transfer cancelWithError:standardError];
        }
    } else {
        
        // no error? delete previously created temporary file
        [[NSFileManager defaultManager] removeItemAtURL:[self _temporaryChunkFileURL] error:nil];
        
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.task.response;
        NSUInteger statusCode = response.statusCode;
        switch (statusCode) {
            case 200:
                if (self.receivedData) {
                    NSError *_error = nil;
                    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:self.receivedData options:0 error:&_error];
                    if (!_error) {
                        if ([self _isChunkCommit]) {
                            // generate item based on upload response
                            CLDSession *session = [CLDSession sessionWithIdentifier:self.transfer.sessionIdentifier];
                            self.transfer.uploadedItem = [CLDItem itemWithDictionary:response session:session];
                        } else {
                            // get upload_id
                            if (response[@"upload_id"]) self.transfer.uploadIdentifier = response[@"upload_id"];
                        }
                    }
                }
                self.state = CLDTransferOperationStateFinished;
                break;
                
            case 400:
                if ([self _isChunkCommit]) {
                    CLDLog(@"Upload ID not found on server. Sending a retry signal to the transfer! ");
                    [self.transfer cancel];
                    [self.transfer retry];
                } else {
                    CLDLog(@"Wrong chunk offset: skipping chunk!");
                    self.state = CLDTransferOperationStateFinished;
                }
                break;
                
            case 404:
                [self.transfer cancelWithError:[CLDError errorWithCode:CLDErrorCodeResourceNotFound]];
                break;
                
            case 406:
                [self.transfer cancelWithError:[CLDError errorWithCode:CLDErrorCodeInvalidParameters]];
                break;
                
            case 507:
                [self.transfer cancelWithError:[CLDError errorWithCode:CLDErrorCodeOverQuota]];
                break;
                
            default: {
                CLDSession *session = [CLDSession sessionWithIdentifier:self.transfer.sessionIdentifier];
                CLDError *standardError = [session _errorFromStatusCode:response.statusCode error:nil];
                [self.transfer cancelWithError:standardError];
                break;
            }
        }
        self.task = nil;
    }
}

#pragma mark - Downloading

- (void)createDownloadTask {
    [self createDownloadTaskWithResumeData:nil];
}

- (void)createDownloadTaskWithResumeData:(NSData *)data {
    [self validate];
    
    CLDItem *item = self.transfer.item;
    CLDSession *session = [CLDSession sessionWithIdentifier:self.transfer.sessionIdentifier];
    
    // generate URL
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (item.revision) params[@"rev"] = item.revision;
    NSString *path = [NSString stringWithFormat:@"/Files/<mode>/%@", item.trimmedPath];
    NSURL *url = [session _serviceURLForEndpoint:CLDSessionEndpointContentAPI path:path query:params];
    
    // generate request
    NSMutableURLRequest *request = [session _signedMutableURLRequestWithURL:url];
    request.allowsCellularAccess = self.transfer.allowsCellularAccess;
    
    // create task and assign it to property
    if (data) {
        self.task = [self.transfer.urlSession downloadTaskWithResumeData:data];
    } else {
        self.task = [self.transfer.urlSession downloadTaskWithRequest:request];
    }
    [self.transfer updateTaskIdentifier:self.task.taskIdentifier forChunkOffset:0];
    [self.task resume];
}

- (void)finishDownloadWithError:(NSError *)error {
    if (error) {
        if (error.userInfo[NSURLSessionDownloadTaskResumeData]) {
            CLDLog(@"Task failed with resume data. Attempting to resume...");
            [self createDownloadTaskWithResumeData:error.userInfo[NSURLSessionDownloadTaskResumeData]];
        } else if ([error.domain isEqualToString:NSURLErrorDomain]) {
            CLDLog(@"Failed to download due to connectivity problems, retrying...");
            sleep(1);
            [self createDownloadTask];
        } else {
            CLDLog(@"Task failed due to error: %@", error);
            CLDSession *session = [CLDSession sessionWithIdentifier:self.transfer.sessionIdentifier];
            CLDError *standardError = [session _errorFromStatusCode:NSNotFound error:error];
            [self.transfer cancelWithError:standardError];
        }
    } else {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.task.response;
        NSUInteger statusCode = response.statusCode;
        switch (statusCode) {
            case 200:
            case 206:
                self.transfer.downloadedFileURL = self.temporaryDownloadedFileURL;
                self.state = CLDTransferOperationStateFinished;
                break;
                
            default: {
                CLDSession *session = [CLDSession sessionWithIdentifier:self.transfer.sessionIdentifier];
                CLDError *standardError = [session _errorFromStatusCode:response.statusCode error:nil];
                [self.transfer cancelWithError:standardError];
                break;
            }
        }
    }
    
    self.task = nil;
}

#pragma mark - Task observing

- (void)beginObservingTask:(NSURLSessionTask *)task {
    @synchronized(self) {
        [task addObserver:self forKeyPath:@"countOfBytesReceived" options:NSKeyValueObservingOptionNew context:kCLDTransferOperationKVOContext];
        [task addObserver:self forKeyPath:@"countOfBytesSent" options:NSKeyValueObservingOptionNew context:kCLDTransferOperationKVOContext];
        [task addObserver:self forKeyPath:@"response" options:NSKeyValueObservingOptionNew context:kCLDTransferOperationKVOContext];
    }
}

- (void)endObservingTask:(NSURLSessionTask *)task {
    @synchronized(self) {
        [task removeObserver:self forKeyPath:@"countOfBytesReceived"];
        [task removeObserver:self forKeyPath:@"countOfBytesSent"];
        [task removeObserver:self forKeyPath:@"response"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == kCLDTransferOperationKVOContext) {
        
        NSURLSessionTask *task = object;
        
        if ([keyPath isEqualToString:@"response"]) {
            if (self.transfer.type == CLDTransferTypeDownload && self.transfer.bytesTotal == 0) {
                self.transfer.bytesTotal = task.response.expectedContentLength;
            }
        } else if (self.transfer.type == CLDTransferTypeDownload ||
                   (self.transfer.type == CLDTransferTypeUpload && ![self _isChunkCommit])) {
            int64_t bytesTransfered;
            int64_t bytesExpectedToTransfer;
            
            if (self.transfer.type == CLDTransferTypeDownload) {
                bytesTransfered = task.countOfBytesReceived;
                bytesExpectedToTransfer = task.countOfBytesExpectedToReceive;
            } else {
                bytesTransfered = task.countOfBytesSent;
                bytesExpectedToTransfer = task.countOfBytesExpectedToSend;
            }
            
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [weakSelf.transfer updateWithByteOffset:weakSelf.byteOffset
                                        bytesTransfered:bytesTransfered
                           totalBytesExpectedToTransfer:bytesExpectedToTransfer];
            });

        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Cancelling

- (void)cancel {
    [self.task cancel];
    self.state = CLDTransferOperationStateCancelled;
    [super cancel];
}

@end
