//
//  CLDLoginViewController.h
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 10/04/14.
//
//

@import UIKit;

@interface CLDLoginViewController : UIViewController

- (instancetype)initWithSession:(CLDSession *)session
                  configuration:(CLDSessionConfiguration *)configuration
                    resultBlock:(void(^)())resultBlock
                   failureBlock:(void(^)(NSError *error))failureBlock;

@end
