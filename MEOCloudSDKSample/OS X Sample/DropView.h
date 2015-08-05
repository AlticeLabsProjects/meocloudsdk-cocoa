//
//  DropView.h
//  MEOCloudSDKSample
//
//  Created by Paulo F. Andrade on 04/08/15.
//  Copyright (c) 2015 SAPO. All rights reserved.
//

@protocol DropViewDelegate;


@interface DropView : NSView

@property (nonatomic, weak) IBOutlet id<DropViewDelegate> delegate;

@end


@protocol DropViewDelegate <NSObject>

- (void)dropViewReceivedDropForFileURL:(NSURL *)fileURL;
@optional
- (BOOL)dropView:(DropView *)view shouldAcceptDragOperationForFileURL:(NSURL *)fileURL;

@end
