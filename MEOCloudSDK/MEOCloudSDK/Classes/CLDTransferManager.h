//
//  MCTransferManager.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/03/14.
//
//

#import <MEOCloudSDK/CLDTransfer.h>

@class CLDSession;

FOUNDATION_EXPORT NSString* const kCLDTransferAddedNotification;
FOUNDATION_EXPORT NSString* const kCLDTransferRemovedNotification;
FOUNDATION_EXPORT NSString* const kCLDTransferStartedNotification;
FOUNDATION_EXPORT NSString* const kCLDTransferSuspendedNotification;
FOUNDATION_EXPORT NSString* const kCLDTransferFinishedNotification;
FOUNDATION_EXPORT NSString* const kCLDTransferUpdatedProgressNotification;
FOUNDATION_EXPORT NSString* const kCLDTransferKey;

/**
 This class is used to manage all transfers created by instances of `CLDSession`.
 */
@interface CLDTransferManager : NSObject

////////////////////////////////////////////////////////////////////////////////
/// @name Manager configuration
////////////////////////////////////////////////////////////////////////////////

/**
 The session whose transfers are being managed.
 @since 1.0
 */
@property (readonly, weak, nonatomic) CLDSession *session;

////////////////////////////////////////////////////////////////////////////////
/// @name Identifying transfers
////////////////////////////////////////////////////////////////////////////////

/**
 Returns an array of all active and queued transfers.
 @param type    The type of transfer to list.
 @return An `NSArray` containing instances of <CLDTransfer>.
 @see transfersOfType:session:
 @since 1.0
 */
- (NSArray *)transfersOfType:(CLDTransferType)type;

////////////////////////////////////////////////////////////////////////////////
/// @name Clearing transfers
////////////////////////////////////////////////////////////////////////////////

/**
 Clears a failed or finished transfer from the list.
 @note If you wish to remove a pending or ongoing transfer, that transfer must first be cancelled.
 @param transfer    The transfer to be cleared.
 @since 1.0
 */
- (void)clearTransfer:(CLDTransfer *)transfer;

/**
 Clears all failed transfers from the list.
 @since 1.0
 */
- (void)clearFailedTransfers;

/**
 Clears all finished transfers from the list.
 @since 1.0
 */
- (void)clearFinishedTransfers;

@end
