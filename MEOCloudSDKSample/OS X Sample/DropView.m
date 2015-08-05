//
//  DropView.m
//  MEOCloudSDKSample
//
//  Created by Paulo F. Andrade on 04/08/15.
//  Copyright (c) 2015 SAPO. All rights reserved.
//

#import "DropView.h"

@interface DropView ()

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

@end


@implementation DropView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.borderWidth = 5.0;
    self.layer.borderColor = [NSColor lightGrayColor].CGColor;
    self.layer.cornerRadius = 5.0;
    
    [self registerForDraggedTypes:@[(NSString *)kUTTypeFileURL]];
}

#pragma mark - Properties

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    
    self.layer.borderColor = (highlighted) ? [NSColor grayColor].CGColor : [NSColor lightGrayColor].CGColor;
}

#pragma mark - Destination Operations

- (BOOL)shouldAcceptDrag:(id <NSDraggingInfo>)sender
{
    NSURL *url = [NSURL URLFromPasteboard:[sender draggingPasteboard]];
    if ( [url isFileURL] ) {
        
        BOOL accept = YES;
        if ([self.delegate respondsToSelector:@selector(dropView:shouldAcceptDragOperationForFileURL:)]) {
            accept = [self.delegate dropView:self shouldAcceptDragOperationForFileURL:url];
        }
        return accept;
    }
    return NO;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    /*------------------------------------------------------
     method called whenever a drag enters our drop zone
     --------------------------------------------------------*/
    
    BOOL accept = [self shouldAcceptDrag:sender];
    if (accept) {
        //highlight our drop zone
        self.highlighted = YES;
        
        //accept data as a copy operation
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    /*------------------------------------------------------
     method called whenever a drag exits our drop zone
     --------------------------------------------------------*/
    //remove highlight of the drop zone
    self.highlighted = NO;
    
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    /*------------------------------------------------------
     method to determine if we can accept the drop
     --------------------------------------------------------*/
    //finished with the drag so remove any highlighting
    self.highlighted = NO;
    
    
    //check to see if we can accept the data
    return [self shouldAcceptDrag:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    /*------------------------------------------------------
     method that should handle the drop data
     --------------------------------------------------------*/
    NSURL *url = [NSURL URLFromPasteboard:[sender draggingPasteboard]];
    if ( [url isFileURL] ) {
        [self.delegate dropViewReceivedDropForFileURL:url];
    }
    return YES;
}


@end
