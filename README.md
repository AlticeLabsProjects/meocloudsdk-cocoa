# MEO Cloud SDK (iOS & OS X)

An SDK for iOS 7+ & OS X 10.10+ to interface with the [MEO Cloud API](https://meocloud.pt/documentation).


## Getting started

We recommend building the framework and then including it in your project.

1. Clone this repo and open the ```MEOCloudSDK/MEOCloudSDK.xcodeproj```
2. Build the ```Framework-iOS7``` or the ```Framework-OSX``` scheme depending on the platform your targeting.
3. The previous step will place the framework in a folder inside ```MEOCloudSDK/``` with the scheme name. Copy it to your project.
4. [Register your app](https://meocloud.pt/my_apps) with the service to get your OAuth credentials

Have a look a the sample project in ```MEOCloudSDKSample/MEOCloudSDKSample.xcodeproj``` if you have any problems.

## CLDSession

The CLDSession object is your primary interface with MEO Cloud's API. You create a session by giving it an identifier that will be used to store OAuth tokens in the keychain. Normally you will be using only one session, so it is recomented that you set it has the default session.

``` Objective-C
CLDSession *session = [CLDSession sessionWithIdentifier:@"<#an identifier#>"];
[CLDSession setDefaultSession:session];
```

To start you'll need to link that object with an account. On iOS you can take advantage of the built in webview to perform the authentication like so:

``` Objective-C
CLDSessionConfiguration *configuration = [CLDSessionConfiguration configurationWithConsumerKey:@"<#your consumer key#>" 
												consumerSecret:@"<#your consumer secret#>"
												   callbackURL:[NSURL URLWithString:@"@"<#your callback url#>""]
												   sandbox:NO];

[[CLDSession defaultSession] linkSessionWithConfiguration:configuration resultBlock:^{
            NSLog(@"Session linked!");
} failureBlock:^(NSError *error) {
            NSLog(@"Error linking session: %@", error);
 }];
```

If you're targeting OS X or just want a finer control of how the authenticaton webview is presented, use the lower level API:

``` Objective-C
CLDSessionConfiguration *configuration = [CLDSessionConfiguration configurationWithConsumerKey:@"<#your consumer key#>" 
												consumerSecret:@"<#your consumer secret#>"
												   callbackURL:[NSURL URLWithString:@"@"<#your callback url#>""]
												   sandbox:NO];

[[CLDSession defaultSession] linkSessionWithConfiguration:configuration
                                                 URLBlock:^(NSURL *url, CLDSessionValidateCallbackURLBlock validateCallbackURL) {
                                                             self.validateBlock = validateCallbackURL;
                                                             // open the url as you see fit
                                                         }
                                              resultBlock:^{
                                                          NSLog(@"Session linked!");
                                                          self.validateBlock = nil;
                                                      } failureBlock:^(NSError *error) {
                                                          NSLog(@"Error linking session: %@", error);
                                                          self.validateBlock = nil;
                                                      }];
 }];
```

When using this method you'll need to store the CLDSessionValidateCallbackURLBlock and use it to check whether authentication is finished by passing it the callback URL.

### Examples

 * Listing items on the root:

 ``` Objective-C
CLDItem *item = [CLDItem rootFolderItem];
[[CLDSession defaultSession] fetchItem:item options:CLDSessionFetchItemOptionNone resultBlock:^(CLDItem *item) {
            NSLog(@"Fetched root folder! (%@)", item.folderHash);
        } failureBlock:^(NSError *error) {
            NSLog(@"Could not fetch root folder");
}];
```
 
 * Renaming a file:
 
 ``` Objective-C
CLDItem *item = [CLDItem itemWithPath:@"/initial name.pdf"];
NSString *newName = @"new name.pdf";
[[CLDSession defaultSession] renameItem:item name:newName resultBlock:^(CLDItem *renamedItem) {
            NSLog(@"Renamed! (%@)", renamedItem.name);
 } failureBlock:^(NSError *error) {
            NSLog(@"Could not rename file. Error: %@", error.description);
}];
```
 * Fetching a thumbnail (note ```CLDImage``` is just a ```#define``` for ```UIImage``` or ```NSImage```):
 
 ``` Objective-C
CLDItem *photo = [CLDItem itemWithPath:@"/Photos/teste.jpg"];
[[CLDSession defaultSession] fetchThumbnailForItem:photo format:CLDItemThumbnailFormatJPEG size:CLDItemThumbnailSizeL cropToSize:NO resultBlock:^(CLDImage *thumbnail) {
            NSLog(@"Woohoo! Thumbnail!");
} failureBlock:^(NSError *error) {
            NSLog(@"Could not fetch thumbnail for item at path \"%@\". Error: %@", photo.path, error.description);
}];
```

 * Downloading a file:
 
 ``` Objective-C
CLDItem *photo = [CLDItem itemWithPath:@"/Photos/teste.jpg"];
[[CLDSession defaultSession] downloadItem:photo resultBlock:^(NSURL *fileURL) {
    NSLog(@"Downloaded file! URL: %@", fileURL);
} failureBlock:^(NSError *error) {
    NSLog(@"Could not download item at path \"%@\". Error: %@", photo.path, error.description);
}];
```

* Uploading a file:

 ``` Objective-C
NSURL *fileURL = [NSURL fileURLWithPath:@"/Users/hsousa/Library/Developer/CoreSimulator/Devices/53DB9174-6405-432E-AFF5-4C8BAA77C357/data/Containers/Data/Application/13DCDC8A-1C44-44E3-9A77-6C934F6B5C59/tmp/pt.meo.cloud.sdk.dl.samplex.B01FD282-C085-47A4-97AF-3C3BA4010E0E.tmp"];
CLDItem *item = [CLDItem itemForUploadingWithURL:fileURL path:@"/_/uploaded bitch.jpg" revision:nil];
[[CLDSession defaultSession] uploadItem:item shouldOverwrite:NO resultBlock:^(CLDItem *newItem) {
    NSLog(@"Downloaded file! Uploaded item: %@", newItem.path);
} failureBlock:^(NSError *error) {
    NSLog(@"Could not upload item. Error: %@", error.userInfo[NSLocalizedDescriptionKey]);
}];
```

## Documentation

You can build the documentation using the ```Documentation``` scheme inside the ```MEOCloudSDK``` project. You'll need appledoc installed.
