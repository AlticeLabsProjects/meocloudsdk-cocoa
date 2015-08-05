//
//  ViewController.m
//  MEOCloudSDKSample
//
//  Created by Hugo Sousa on 13/03/14.
//  Copyright (c) 2014 SAPO. All rights reserved.
//

#import "ViewController.h"
#import "MyCLDSession.h"

@interface ViewController ()
//@property (strong, nonatomic) CLDSession *cld;
@property (copy, nonatomic) CLDSessionValidateCallbackURLBlock validateCallbackURL;
@property (weak, nonatomic) IBOutlet UILabel *someLabel;
@property (weak, nonatomic) IBOutlet UIButton *someButton;
- (IBAction)touchedSomeButton:(UIButton *)sender;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    MyCLDSession *session = [MyCLDSession sessionWithIdentifier:@"samplex"];
    [CLDSession setDefaultSession:session];
    
    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferRemovedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferSuspendedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferFinishedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kCLDTransferUpdatedProgressNotification object:nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateUI];
    
    [[CLDSession defaultSession] fetchAccountInformationWithResultBlock:^(CLDAccountUser *user) {
        NSLog(@"This account belongs to: %@", user.name);
    } failureBlock:^(NSError *error) {
        NSLog(@"Could not fetch account information: %@", error);
    }];
    
    // list items
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CLDItem *item = [CLDItem rootFolderItem];
//        [[CLDSession defaultSession] fetchItem:item options:CLDSessionFetchItemOptionNone resultBlock:^(CLDItem *item) {
//            NSLog(@"Fetched root folder! (%@)", item.folderHash);
//        } failureBlock:^(NSError *error) {
//            NSLog(@"Could not fetch root folder");
//        }];
//    });
    
    // copy item
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CLDItem *item = [CLDItem itemWithPath:@"/app-store-optimisation-cheat-sheet.pdf"];
//        [[CLDSession defaultSession] copyItem:item toPath:@"/copied.pdf" resultBlock:^(CLDItem *newItem) {
//            NSLog(@"Copied! (%@)", newItem.folderHash);
//        } failureBlock:^(NSError *error) {
//            NSLog(@"Could not copy file. Error: %@", error.description);
//        }];
//    });
    
    // rename item
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CLDItem *item = [CLDItem itemWithPath:@"/copied.pdf"];
//        NSString *newName = @"renamed file.pdf";
//        [[CLDSession defaultSession] renameItem:item name:newName resultBlock:^(CLDItem *renamedItem) {
//            NSLog(@"Renamed! (%@)", renamedItem.name);
//        } failureBlock:^(NSError *error) {
//            NSLog(@"Could not rename file. Error: %@", error.description);
//        }];
//    });
    
    // list public links
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[CLDSession defaultSession] fetchPublicLinksWithResultBlock:NULL failureBlock:NULL];
//    });
    
    // list shared folders
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[CLDSession defaultSession] fetchSharedItemsWithResultBlock:NULL failureBlock:NULL];
//    });
    
    // search
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CLDItem *root = [CLDItem rootFolderItem];
//        [[CLDSession defaultSession] searchItem:root query:nil limit:5 mimeType:@"image/*" includeDeletedItems:NO resultBlock:^(NSArray *items) {
//            NSLog(@"searched and got %d results!", items.count);
//        } failureBlock:^(NSError *error) {
//            NSLog(@"Could not search... error: %@", error.description);
//        }];
//    });
    
    // fetch thumbnail
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CLDItem *photo = [CLDItem itemWithPath:@"/Photos/teste.jpg"];
//        [[CLDSession defaultSession] fetchThumbnailForItem:photo format:CLDItemThumbnailFormatJPEG size:CLDItemThumbnailSizeL cropToSize:NO resultBlock:^(UIImage *thumbnail) {
//            NSLog(@"Woohoo! Thumbnail!");
//        } failureBlock:^(NSError *error) {
//            NSLog(@"Could not fetch thumbnail for item at path \"%@\". Error: %@", photo.path, error.description);
//        }];
//    });
    
    // direct download URL
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CLDItem *photo = [CLDItem itemWithPath:@"/Photos/teste.jpg"];
//        [[CLDSession defaultSession] fetchURLForItem:photo resultBlock:^(NSURL *url, NSDate *expireDate) {
//            NSLog(@"Fetch URL: %@", url);
//        } failureBlock:^(NSError *error) {
//            NSLog(@"Could not fetch download URL for item at path \"%@\". Error: %@", photo.path, error.description);
//        }];
//    });

    // download file using blocks
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CLDItem *photo = [CLDItem itemWithPath:@"/Photos/teste.jpg"];
//        [[CLDSession defaultSession] downloadItem:photo resultBlock:^(NSURL *fileURL) {
//            NSLog(@"Downloaded file! URL: %@", fileURL);
//        } failureBlock:^(NSError *error) {
//            NSLog(@"Could not download item at path \"%@\". Error: %@", photo.path, error.description);
//        }];
//    });
    
    // download file in the background
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CLDItem *photo = [CLDItem itemWithPath:@"/Applications/Plex.app.zip"];
//        [[CLDSession defaultSession] scheduleDownloadForItem:photo error:nil];
//    });

    // upload file using blocks
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSURL *fileURL = [NSURL fileURLWithPath:@"/Users/hsousa/Library/Developer/CoreSimulator/Devices/53DB9174-6405-432E-AFF5-4C8BAA77C357/data/Containers/Data/Application/13DCDC8A-1C44-44E3-9A77-6C934F6B5C59/tmp/pt.meo.cloud.sdk.dl.samplex.B01FD282-C085-47A4-97AF-3C3BA4010E0E.tmp"];
//        CLDItem *item = [CLDItem itemForUploadingWithURL:fileURL path:@"/_/uploaded bitch.jpg" revision:nil];
//        [[CLDSession defaultSession] uploadItem:item shouldOverwrite:NO resultBlock:^(CLDItem *newItem) {
//            NSLog(@"Downloaded file! Uploaded item: %@", newItem.path);
//        } failureBlock:^(NSError *error) {
//            NSLog(@"Could not upload item. Error: %@", error.userInfo[NSLocalizedDescriptionKey]);
//        }];
//    });


}

- (void)handleNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:kCLDTransferUpdatedProgressNotification]) {
        CLDTransfer *transfer = notification.userInfo[kCLDTransferKey];
        NSLog(@"[N][%@][%llu/%llu@%lu]", notification.name, transfer.bytesTransfered,
              transfer.bytesTotal, (unsigned long)transfer.lastRecordedSpeed);
    } else {
        NSLog(@"[N][%@][%@][%@]", notification.name, notification.object, notification.userInfo[kCLDTransferKey]);
    }
}

- (IBAction)touchedSomeButton:(UIButton *)sender {
    if ([CLDSession defaultSession].isLinked) {
        [[CLDSession defaultSession] unlinkSessionWithResultBlock:^{
            [self updateUI];
        } failureBlock:^(NSError *error) {
            NSLog(@"Could not unlink session! DAFUQ?!");
        }];
    } else {
        CLDSessionConfiguration *configuration = [CLDSessionConfiguration configurationWithConsumerKey:@"45fb9220-d2d9-47af-883e-eca94b340197"
                                                                                        consumerSecret:@"236719026544380755505209708384076084654"
                                                                                           callbackURL:[NSURL URLWithString:@"http://meocloudsdk/oauth"]
                                                                                               sandbox:NO];
        [[CLDSession defaultSession] linkSessionWithConfiguration:configuration resultBlock:^{
            NSLog(@"Session linked!");
        } failureBlock:^(NSError *error) {
            NSLog(@"Error linking session: %@", error);
        }];
        
        
    }
}

- (void)updateUI {
    if ([CLDSession defaultSession].isLinked) {
        self.someLabel.text = @"YOU ARE LINKED!";
        [self.someButton setTitle:@"Unlink" forState:UIControlStateNormal];
    } else {
        self.someLabel.text = @"YOU ARE NOT LINKED!";
        [self.someButton setTitle:@"Link session" forState:UIControlStateNormal];
    }
}
@end
