//
//  MCTransfer.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

#import "CLDTransfer.h"

static void *kCLDTransferKVOContext = &kCLDTransferKVOContext;

@interface CLDTransferManager (Transfer)
@property (readwrite, strong, nonatomic) NSMutableArray *operationDump;
- (NSURLSession *)urlSessionForTransfer:(CLDTransfer *)transfer;
- (void)_addOperationsForTransfer:(CLDTransfer *)transfer;
- (void)_removeTransfer:(CLDTransfer *)transfer;
@end

@interface CLDTransfer ()
// public properties
@property (readwrite, strong, nonatomic) NSString *sessionIdentifier;
@property (readwrite, nonatomic) BOOL allowsCellularAccess;
@property (readwrite, nonatomic) CLDTransferPriority priority;
@property (readwrite, nonatomic) CLDTransferType type;
@property (readwrite, nonatomic, getter = isBackgroundTransfer) BOOL backgroundTransfer;
@property (readwrite, nonatomic) CLDTransferState state;
@property (readwrite, strong, nonatomic) CLDItem *item;
@property (readwrite, nonatomic) uint64_t bytesTransfered;
@property (readwrite, nonatomic) uint64_t bytesTotal;
@property (readwrite, nonatomic) double lastRecordedSpeed;
@property (readwrite, strong, nonatomic) NSError *error;
@property (readwrite, strong, nonatomic) NSURL *downloadedFileURL;
@property (readwrite, strong, nonatomic) CLDItem *uploadedItem;

// project properties
@property (readwrite, strong, nonatomic) NSString *transferIdentifier;
@property (readonly, strong, nonatomic) NSURLSession *urlSession;
@property (readwrite, strong, nonatomic) NSString *uploadIdentifier;
@property (readwrite, strong, nonatomic) NSArray *operations;
@property (readwrite, copy, nonatomic) CLDTransferDownloadResultBlock downloadResultBlock;
@property (readwrite, copy, nonatomic) CLDTransferUploadResultBlock uploadResultBlock;
@property (readwrite, copy, nonatomic) CLDTransferFailureBlock failureBlock;

// private properties
@property (readwrite, weak, nonatomic) CLDTransferManager *manager;
@property (readwrite, strong, nonatomic) NSMutableArray *taskIdentifiers;
@property (readwrite, nonatomic) NSUInteger chunkSize;
@property (readwrite, nonatomic) NSUInteger chunkIndexOffset;
@property (readwrite, strong, nonatomic) NSProgress *progress;
@property (readwrite, strong, nonatomic) NSMutableArray *operationsBeingObserved;
@end

@implementation CLDTransfer {
//    NSDate *_lastProgressUpdateDate;
//    double _lastMeasuredSpeed;
}

#pragma mark - Initialization

- (instancetype)initWithManager:(CLDTransferManager *)manager {
    NSParameterAssert(manager);
    NSParameterAssert(manager.session);
    self = [super init];
    if (self) {
        _manager = manager;
        _sessionIdentifier = manager.session.sessionIdentifier;
    }
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    _sessionIdentifier = [aDecoder decodeObjectForKey:@"sessionIdentifier"];
    _shouldOverwrite = [aDecoder decodeBoolForKey:@"shouldOverwrite"];
    _allowsCellularAccess = [aDecoder decodeBoolForKey:@"allowsCellularAccess"];
    _priority = [aDecoder decodeIntegerForKey:@"priority"];
    _type = [aDecoder decodeIntegerForKey:@"type"];
    _backgroundTransfer = [aDecoder decodeBoolForKey:@"backgroundTransfer"];
    _state = [aDecoder decodeIntegerForKey:@"state"];
    _item = [aDecoder decodeObjectForKey:@"item"];
    _bytesTransfered = [aDecoder decodeInt64ForKey:@"bytesTransfered"];
    _bytesTotal = [aDecoder decodeInt64ForKey:@"bytesTotal"];
    _lastRecordedSpeed = [aDecoder decodeDoubleForKey:@"lastRecordedSpeed"];
    _error = [aDecoder decodeObjectForKey:@"error"];
    _taskIdentifiers = [aDecoder decodeObjectForKey:@"taskIdentifiers"];
    _chunkSize = [aDecoder decodeIntegerForKey:@"chunkSize"];
    _chunkIndexOffset = [aDecoder decodeIntegerForKey:@"chunkIndexOffset"];
    _uploadIdentifier = [aDecoder decodeObjectForKey:@"uploadIdentifier"];
    _uploadedItem = [aDecoder decodeObjectForKey:@"uploadedItem"];
    _downloadedFileURL = [aDecoder decodeObjectForKey:@"downloadedFileURL"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.sessionIdentifier forKey:@"sessionIdentifier"];
    [aCoder encodeBool:self.shouldOverwrite forKey:@"shouldOverwrite"];
    [aCoder encodeBool:self.allowsCellularAccess forKey:@"allowsCellularAccess"];
    [aCoder encodeInteger:self.priority forKey:@"priority"];
    [aCoder encodeInteger:self.type forKey:@"type"];
    [aCoder encodeBool:self.isBackgroundTransfer forKey:@"backgroundTransfer"];
    [aCoder encodeInteger:self.state forKey:@"state"];
    [aCoder encodeObject:self.item forKey:@"item"];
    [aCoder encodeInt64:self.bytesTransfered forKey:@"bytesTransfered"];
    [aCoder encodeInt64:self.bytesTotal forKey:@"bytesTotal"];
    [aCoder encodeDouble:self.lastRecordedSpeed forKey:@"lastRecordedSpeed"];
    [aCoder encodeObject:self.error forKey:@"error"];
    [aCoder encodeObject:self.taskIdentifiers forKey:@"taskIdentifiers"];
    [aCoder encodeInteger:self.chunkSize forKey:@"chunkSize"];
    [aCoder encodeInteger:self.chunkIndexOffset forKey:@"chunkIndexOffset"];
    [aCoder encodeObject:self.uploadIdentifier forKey:@"uploadIdentifier"];
    [aCoder encodeObject:self.uploadedItem forKey:@"uploadedItem"];
    [aCoder encodeObject:self.downloadedFileURL forKey:@"downloadedFileURL"];
}

#pragma mark - Identifying transfers

- (NSString *)transferIdentifier {
    if (!_transferIdentifier) {
        _transferIdentifier = [NSString stringWithFormat:@"%@.%@", self.sessionIdentifier, [CLDUtil generateIdentifier]];
    }
    return _transferIdentifier;
}

#pragma mark - Properties

- (void)setState:(CLDTransferState)state {
    _state = state;
    switch (state) {
        case CLDTransferStatePending:
            break;
            
        case CLDTransferStateTransfering:
            [CLDUtil postNotificationNamed:kCLDTransferStartedNotification object:self.manager userInfo:@{kCLDTransferKey:self}];
            break;
            
        case CLDTransferStateSuspended:
            [CLDUtil postNotificationNamed:kCLDTransferSuspendedNotification object:self.manager userInfo:@{kCLDTransferKey:self}];
            break;
            
        case CLDTransferStateFailed: {
            [CLDUtil postNotificationNamed:kCLDTransferFinishedNotification object:self.manager userInfo:@{kCLDTransferKey:self}];
            RunBlockOnMainThread(self.failureBlock, self.error);
            break;
        }
            
        case CLDTransferStateFinished: {
            NSString *filePath = self.downloadedFileURL.filePathURL.path;
            [CLDUtil postNotificationNamed:kCLDTransferFinishedNotification object:self.manager userInfo:@{kCLDTransferKey:self} synchronous:YES];
            if (self.type == CLDTransferTypeDownload) {
                RunBlockSynchronouslyOnMainThread(self.downloadResultBlock, self.downloadedFileURL);
                if ([filePath isEqual:self.downloadedFileURL.filePathURL.path]) {
                    NSError *error = nil;
                    [[NSFileManager defaultManager] removeItemAtURL:self.downloadedFileURL error:&error];
                    if (error) CLDLog(@"Error deleting temporary downloaded file: %@", error.userInfo[NSLocalizedFailureReasonErrorKey]);
                    else CLDLog(@"Deleted temporary file at location: %@", self.downloadedFileURL);
                } else {
                    CLDLog(@"Temporary file was moved!");
                }
            } else {
                RunBlockOnMainThread(self.uploadResultBlock, self.uploadedItem);
            }
            break;
        }
    }
    
    // save state to disk
    [self.manager save];
}

- (void)setItem:(CLDItem *)item {
    if (_item) return;
    _item = item;
    if (self.type == CLDTransferTypeUpload) {
        self.bytesTotal = _item.size;
    }
}

- (void)setBytesTransfered:(uint64_t)bytesTransfered {
    _bytesTransfered = bytesTransfered;
    self.progress.completedUnitCount = _bytesTransfered;
    [CLDUtil postNotificationNamed:kCLDTransferUpdatedProgressNotification object:self.manager userInfo:@{kCLDTransferKey:self}];
}

- (void)setBytesTotal:(uint64_t)bytesTotal {
    _bytesTotal = bytesTotal;
    self.progress.totalUnitCount = _bytesTotal;
}

- (double)lastRecordedSpeed {
    return _lastRecordedSpeed;
}

- (NSURLSession *)urlSession {
    if (self.manager) {
        return [self.manager urlSessionForTransfer:self];
    } else {
        return nil;
    }
}

- (NSProgress *)progress {
    if (_progress) return _progress;
    else {
        _progress = [NSProgress progressWithTotalUnitCount:self.bytesTotal];
        _progress.cancellable = YES;
        _progress.pausable = NO;
        _progress.kind = NSProgressKindFile;
        return _progress;
    }
}

- (NSMutableArray *)operationsBeingObserved {
    @synchronized(self) {
        if (!_operationsBeingObserved) {
            _operationsBeingObserved = [NSMutableArray new];
        }
        return _operationsBeingObserved;
    }
}

#pragma mark - Transfer update

- (void)updateWithByteOffset:(int64_t)byteOffset
             bytesTransfered:(int64_t)bytesTransfered
totalBytesExpectedToTransfer:(int64_t)totalBytesExpectedToTransfer {
//    int64_t bytesTransferedThisTime = bytesTransfered - (self.bytesTransfered - byteOffset);
//    NSDate *now = [NSDate date];
//    if (_lastProgressUpdateDate) {
//        NSTimeInterval _secondsPassed = [now timeIntervalSinceDate:_lastProgressUpdateDate];
//        double currentSpeed = bytesTransferedThisTime / _secondsPassed;
//        if (_lastMeasuredSpeed > 0) {
//            CGFloat _smoothingFactor = 0.005f;
//            self.lastRecordedSpeed = _smoothingFactor * _lastMeasuredSpeed + (1-_smoothingFactor) * self.lastRecordedSpeed;
//        }
//        _lastMeasuredSpeed = currentSpeed;
////        NSLog(@"Thead %@ [%llu][%f] \t\t [%f][%f] \t\t %f KBps", [NSThread currentThread],
////              bytesTransferedThisTime, _secondsPassed, currentSpeed, self.lastRecordedSpeed,
////              ((double)self.lastRecordedSpeed / (double)1024));
//    }
//    _lastProgressUpdateDate = now;
    self.bytesTransfered = byteOffset + bytesTransfered;
}

#pragma mark - Operations

- (NSUInteger)chunkSize {
    if (_chunkSize == NSNotFound || _chunkSize == 0) {
//#ifdef DEBUG
//        _chunkSize = 4*1024;
//#else
        _chunkSize = 4*1024*1024;
//#endif
    }
    return _chunkSize;
}

- (NSUInteger)_numberOfRequiredOperations {
    if (self.type == CLDTransferTypeUpload) {
        return ceil((double)self.bytesTotal / (double)self.chunkSize) + 1; // we always need one more operation for the commit request
    } else {
        return 1;
    }
}

- (NSArray *)operations {
    @synchronized(self) {
        if (_operations) return _operations;
        NSUInteger numberOfRequiredOperations = [self _numberOfRequiredOperations];
        NSMutableArray *operations = [NSMutableArray new];
        CLDTransferOperation *previousOperation = nil;
        for (NSUInteger chunkIndex = self.chunkIndexOffset; chunkIndex < numberOfRequiredOperations; chunkIndex++) {
            NSUInteger taskIdentifier = NSNotFound;
            if (self.taskIdentifiers.count > chunkIndex) taskIdentifier = [self.taskIdentifiers[chunkIndex] unsignedIntegerValue];
            CLDTransferOperation *operation;
            if (self.type == CLDTransferTypeDownload) {
                operation = [CLDTransferOperation downloadOperationForTransfer:self
                                                                taskIdentifier:taskIdentifier];
            } else {
                operation = [CLDTransferOperation uploadOperationForTransfer:self
                                                                 chunkOffset:chunkIndex * self.chunkSize
                                                              taskIdentifier:taskIdentifier];
            }
            if (self.priority == CLDTransferPriorityLow) operation.queuePriority = NSOperationQueuePriorityLow;
            [self beginObservingOperation:operation];
            [operations addObject:operation];
            if (previousOperation) {
                [operation addDependency:previousOperation];
            }
            previousOperation = operation;
        }
        _operations = [operations copy];
        return _operations;
    }
}

- (NSMutableArray *)taskIdentifiers {
    @synchronized(self) {
        if (!_taskIdentifiers) _taskIdentifiers = [NSMutableArray new];
        return _taskIdentifiers;
    }
}

- (void)updateTaskIdentifier:(NSUInteger)taskIdentifier forChunkOffset:(uint64_t)chunkOffset {
    uint64_t chunkIndex = chunkOffset / self.chunkSize;
    [self updateTaskIdentifier:taskIdentifier forChunkIndex:(NSUInteger)chunkIndex];
}

- (void)updateTaskIdentifier:(NSUInteger)taskIdentifier forChunkIndex:(NSUInteger)chunkIndex {
    @synchronized(self) {
        while ((NSInteger)self.taskIdentifiers.count-(NSInteger)1 < chunkIndex) {
            [self.taskIdentifiers addObject:@(NSNotFound)];
        }
        self.taskIdentifiers[chunkIndex] = @(taskIdentifier);
    }
}

#pragma mark - Observing operations

- (void)beginObservingOperation:(CLDTransferOperation *)operation {
    @synchronized(self) {
        if (![self.operationsBeingObserved containsObject:operation]) {
            [operation addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:kCLDTransferKVOContext];
            [self.operationsBeingObserved addObject:operation];
        }
    }
}

- (void)endObservingOperation:(CLDTransferOperation *)operation {
    @synchronized(self) {
        if ([self.operationsBeingObserved containsObject:operation]) {
            [operation removeObserver:self forKeyPath:@"state"];
            [self.operationsBeingObserved removeObject:operation];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == kCLDTransferKVOContext) {
        if ([self.operations containsObject:object]) {
            CLDTransferOperation *operation = (CLDTransferOperation *)object;
            switch (operation.state) {
                case CLDTransferOperationStateExecuting: {
                    if (self.state != CLDTransferStateTransfering) self.state = CLDTransferStateTransfering;
                    break;
                }
                case CLDTransferOperationStateFinished: {
                    self.chunkIndexOffset++;
                    [self endObservingOperation:operation];
                    if (self.chunkIndexOffset == [self _numberOfRequiredOperations]) {
                        self.state = CLDTransferStateFinished;
                    }
                    [self.manager save];
                    break;
                }
                    
                case CLDTransferOperationStateCancelled: {
                    [self endObservingOperation:operation];
                }
                    
                default:
                    break;
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Actions

- (void)_cancelOperations {
    for (CLDTransferOperation *operation in self.operations) {
        [operation cancel];
    }
    [self.manager.operationDump addObjectsFromArray:self.operations];
    _operations = nil;
}

- (void)cancelWithError:(NSError *)error {
    [self _cancelOperations];
    self.error = error;
    self.state = CLDTransferStateFailed;
}

- (void)cancel {
    [self cancelWithError:[CLDError errorWithCode:CLDErrorCancelledByUser]];
}

- (void)retry {
    if (self.state == CLDTransferStateFailed) {
        self.error = nil;
        self.state = CLDTransferStatePending;
        self.uploadIdentifier = nil;
        _bytesTransfered = 0;
        _chunkIndexOffset = 0;
        [self _cancelOperations];
        [self.manager _addOperationsForTransfer:self];
    }
}

@end
