//
//  ViewController.m
//  MEOCloudSDKSample
//
//  Created by Paulo F. Andrade on 04/08/15.
//  Copyright (c) 2015 SAPO. All rights reserved.
//

#import "ViewController.h"
#import "MyCLDSession.h"
#import "DropView.h"

@interface ViewController () <DropViewDelegate>

@property (nonatomic, weak) IBOutlet NSButton *linkButton;
@property (nonatomic, copy) CLDSessionValidateCallbackURLBlock validateBlock;
@property (weak) IBOutlet NSTextField *accountLabel;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

@property (nonatomic, strong) CLDTransfer *currentTransfer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleURLEvent:reply:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
    
    MyCLDSession *session = [MyCLDSession sessionWithIdentifier:@"samplex"];
    [CLDSession setDefaultSession:session];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferRemovedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferSuspendedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferUpdatedProgressNotification object:nil];
    
    [self updateUI];
}

- (void)handleNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:kCLDTransferUpdatedProgressNotification]) {
        CLDTransfer *transfer = notification.userInfo[kCLDTransferKey];
        NSLog(@"[N][%@][%llu/%llu@%lu]", notification.name, transfer.bytesTransfered,
              transfer.bytesTotal, (unsigned long)transfer.lastRecordedSpeed);
        self.progressIndicator.hidden = NO;
        self.progressIndicator.minValue = 0;
        self.progressIndicator.maxValue = transfer.bytesTotal;
        self.progressIndicator.doubleValue = transfer.bytesTransfered;
        
    }
    else {
        NSLog(@"[N][%@][%@][%@]", notification.name, notification.object, notification.userInfo[kCLDTransferKey]);
    }
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event reply:(NSAppleEventDescriptor *)reply
{
    NSString *urlAddress = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlAddress];
    
    if (self.validateBlock && url) {
        self.validateBlock(url);
    }
}


#pragma mark - Actions
- (IBAction)linkButtonClicked:(id)sender
{
    if ([CLDSession defaultSession].isLinked) {
        [[CLDSession defaultSession] unlinkSessionWithResultBlock:^{
            [self updateUI];
        } failureBlock:^(NSError *error) {
            NSLog(@"Could not unlink session! DAFUQ?!");
        }];
    } else {
        CLDSessionConfiguration *configuration = [CLDSessionConfiguration configurationWithConsumerKey:@"d42da7cc-d9ed-467b-9dc3-761250be0d13"
                                                                                        consumerSecret:@"116296771878230290028098339677999070328"
                                                                                           callbackURL:[NSURL URLWithString:@"x-meocloudsdk-osxsample://meocloudsdk/oauth"]
                                                                                               sandbox:NO];
        [[CLDSession defaultSession] linkSessionWithConfiguration:configuration
                                                         URLBlock:^(NSURL *url, CLDSessionValidateCallbackURLBlock validateCallbackURL) {
                                                             self.validateBlock = validateCallbackURL;
                                                             [[NSWorkspace sharedWorkspace] openURL:url];
                                                         }
                                                      resultBlock:^{
                                                          NSLog(@"Linked!");
                                                          [self updateUI];
                                                          self.validateBlock = nil;
                                                      } failureBlock:^(NSError *error) {
                                                          NSLog(@"Link failed! %@", error);
                                                          NSAlert *alert = [NSAlert alertWithError:error];
                                                          [alert runModal];
                                                          [self updateUI];
                                                          self.validateBlock = nil;
                                                      }];
        
        
    }
}



- (void)updateUI {
    if ([CLDSession defaultSession].isLinked) {
        self.linkButton.title = @"Unlink";
        self.statusLabel.stringValue = (self.currentTransfer == nil) ? @"Drop a file here to upload" : @"Uploading";
        [[CLDSession defaultSession] fetchAccountInformationWithResultBlock:^(CLDAccountUser *user) {
            self.accountLabel.stringValue = [NSString stringWithFormat:@"Linked with account: %@", user.name];
        } failureBlock:^(NSError *error) {
            NSLog(@"Could not fetch account information: %@", error);
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
        }];
        
    } else {
        self.linkButton.title = @"Link";
        self.accountLabel.stringValue = @"";
        self.statusLabel.stringValue = @"No account linked";
    }
}

#pragma mark - DropView delegate

- (BOOL)dropView:(DropView *)view shouldAcceptDragOperationForFileURL:(NSURL *)fileURL
{
    return [CLDSession defaultSession].isLinked;
}

- (void)dropViewReceivedDropForFileURL:(NSURL *)fileURL
{
    CLDItem *item = [CLDItem itemForUploadingWithURL:fileURL path:[fileURL lastPathComponent] revision:nil];
    self.currentTransfer = [[CLDSession defaultSession] uploadItem:item shouldOverwrite:YES cellularAccess:NO priority:CLDTransferPriorityNormal
                                resultBlock:^(CLDItem *newItem) {
                                    NSLog(@"Upload finished!");
                                    self.currentTransfer = nil;
                                    [self updateUI];
                                    self.progressIndicator.hidden = YES;
                                }
                               failureBlock:^(NSError *error) {
                                   NSLog(@"Upload failed %@", error);
                                   self.currentTransfer = nil;
                                   [self updateUI];
                                   self.progressIndicator.hidden = YES;
                                   [[NSAlert alertWithError:error] runModal];

                               }];
    [self updateUI];
}


@end
