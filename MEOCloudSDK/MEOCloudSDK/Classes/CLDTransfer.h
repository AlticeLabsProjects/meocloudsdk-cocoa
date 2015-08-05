//
//  MCTransfer.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

@class CLDItem;

/**
 Types of transfers.
 @since 1.0
 */
typedef NS_ENUM(NSUInteger, CLDTransferType) {
    /**
     Both upload and download transfers.
     @since 1.0
     */
    CLDTransferTypeAll,
    /**
     Download transfers.
     @since 1.0
     */
    CLDTransferTypeDownload,
    /**
     Upload transfers.
     @since 1.0
     */
    CLDTransferTypeUpload
};

/**
 States of transfers.
 @since 1.0
 */
typedef NS_ENUM(NSUInteger, CLDTransferState) {
    /**
     Transfer is pending.
     @since 1.0
     */
    CLDTransferStatePending,
    /**
     Transfer is currently executing
     @since 1.0
     */
    CLDTransferStateTransfering,
    /**
     Transfer is suspended (paused).
     @since 1.0
     */
    CLDTransferStateSuspended,
    /**
     Transfer failed. See `error` to find out more.
     @since 1.0
     */
    CLDTransferStateFailed,
    /**
     Transfer finished successfully.
     @since 1.0
     */
    CLDTransferStateFinished
};

/**
 Possible priority values for transfers.
 @since 1.0
 */
typedef NS_ENUM(NSInteger, CLDTransferPriority){
    /**
     Low priority. Transfers with this priority will be executed in the same queue as CLDTransferPriorityNormal, but will only start if
     no other transfers are pending.
     @since 1.0
     */
    CLDTransferPriorityLow = -10,
    /**
     Normal priority. Transfers with this priority will be executed in the same queue as CLDTransferPriorityLow, but will start first.
     @since 1.0
     */
    CLDTransferPriorityNormal = 0,
    /**
     High priority. Transfers with this priority will be executed in a separate queue.
     @since 1.0
     */
    CLDTransferPriorityHigh = 10
};

/**
 This class is used to represent download and upload transfers.
 Transfers are created automatically by <CLDSession>.
 */
@interface CLDTransfer : NSObject <NSCoding>

////////////////////////////////////////////////////////////////////////////////
/// @name Identifying transfers
////////////////////////////////////////////////////////////////////////////////

/**
 The identifier of the session this transfer belongs to.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSString *sessionIdentifier;

////////////////////////////////////////////////////////////////////////////////
/// @name Transfer settings
////////////////////////////////////////////////////////////////////////////////

/**
 If the transfer is an upload, use this to decide if the file whould be overwritten.
 Default value is `NO`.
 @since 1.0
 */
@property (readwrite, nonatomic) BOOL shouldOverwrite;

/**
 `BOOL` stating whether or not this transfer should use cellular access.
 Default value is `YES`.
 @since 1.0
 */
@property (readonly, nonatomic) BOOL allowsCellularAccess;

/**
 The priority for the transfer.
 Default value is `CLDTransferPriorityNormal`.
 @since 1.0
 */
@property (readonly, nonatomic) CLDTransferPriority priority;

////////////////////////////////////////////////////////////////////////////////
/// @name Types of transfers
////////////////////////////////////////////////////////////////////////////////

/**
 Transfer type, either `CLDTransferTypeDownload` or `CLDTransferTypeUpload`.
 @since 1.0
 */
@property (readonly, nonatomic) CLDTransferType type;

/**
 `BOOL` stating if the transfer will be done in the background, possibly while the app is not running.
 @since 1.0
 */
@property (readonly, nonatomic, getter = isBackgroundTransfer) BOOL backgroundTransfer;


////////////////////////////////////////////////////////////////////////////////
/// @name Transfer information
////////////////////////////////////////////////////////////////////////////////

/**
 The transfer's current state.
 @note This property is KVO compliant.
 @since 1.0
 */
@property (readonly, nonatomic) CLDTransferState state;

/**
 The item being transfered.
 @since 1.0
 */
@property (readonly, strong, nonatomic) CLDItem *item;

/**
 Amount of bytes transfered.
 @note This property is KVO compliant.
 @since 1.0
 */
@property (readonly, nonatomic) uint64_t bytesTransfered;

/**
 Total amount of bytes to be transfered.
 @note This property is KVO compliant.
 @since 1.0
 */
@property (readonly, nonatomic) uint64_t bytesTotal;

/**
 The last known speed about this transfer, recorded in bytes per second.
 @note This property is KVO compliant.
 @since 1.0
 */
@property (readonly, nonatomic) double lastRecordedSpeed;

/**
 The error, in case the transfer failed.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSError *error;

/**
 The URL for the downloaded file.
 @warning This URL points to a temporary location. You should subscribe to the notifications defined in `CLDTransferManager`.
 @note This property is `nil` until the transfer is finished.
 @since 1.0
 */
@property (readonly, strong, nonatomic) NSURL *downloadedFileURL;

/**
 An instance of `CLDItem` representing the information about the uploaded item.
 @note This property is `nil` until the transfer is finished.
 @since 1.0
 */
@property (readonly, strong, nonatomic) CLDItem *uploadedItem;


////////////////////////////////////////////////////////////////////////////////
/// @name Actions
////////////////////////////////////////////////////////////////////////////////

/**
 Cancels the transfer.
 @note This does not remove the transfer from it's manager.
 @since 1.0
 */
- (void)cancel;

/**
 Retries to transfer the file.
 @note Calling this method only produces any kind of action if the transfer state is `CLDTransferStateFailed`.
 @since 1.0
 */
- (void)retry;

@end
