//
//  CLDTransferOperation.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 16/07/14.
//
//

typedef NS_ENUM(NSUInteger, CLDTransferOperationState) {
    CLDTransferOperationStatePending,
    CLDTransferOperationStateExecuting,
    CLDTransferOperationStateCancelled,
    CLDTransferOperationStateFinished
};

@class CLDTransfer;

@interface CLDTransferOperation : NSOperation

@property (readonly, weak, nonatomic) CLDTransfer *transfer;
@property (readonly, strong, nonatomic) NSURLSessionTask *task;
@property (readonly) CLDTransferOperationState state;

+ (instancetype)downloadOperationForTransfer:(CLDTransfer *)transfer taskIdentifier:(NSUInteger)taskIdentifier;
+ (instancetype)uploadOperationForTransfer:(CLDTransfer *)transfer chunkOffset:(uint64_t)offset taskIdentifier:(NSUInteger)taskIdentifier;
@end
