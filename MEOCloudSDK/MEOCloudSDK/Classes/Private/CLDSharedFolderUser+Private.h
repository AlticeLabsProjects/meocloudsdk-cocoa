//
//  CLDSharedFolderUser+Private.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 07/07/14.
//
//

#import <MEOCloudSDK/CLDSharedFolderUser.h>

@interface CLDSharedFolderUser (Private)
@property (readwrite, nonatomic) BOOL accepted;
@property (readwrite, weak, nonatomic) CLDSharedFolder *folder;
@end