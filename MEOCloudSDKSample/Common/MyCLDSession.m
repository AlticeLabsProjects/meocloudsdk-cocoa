//
//  MyCLDSession.m
//  MEOCloudSDKSample
//
//  Created by Hugo Sousa on 26/06/14.
//  Copyright (c) 2014 SAPO. All rights reserved.
//

#import "MyCLDSession.h"

@implementation MyCLDSession

- (NSString *)_authHost {
    return @"meocloud.pt";
}

- (NSString *)_apiHost {
    return @"api.meocloud.pt";
}

- (NSString *)_apiContentHost {
    return @"api-content.meocloud.pt";
}

- (NSString *)_accessModeSandbox {
    return @"sandbox";
}

- (NSString *)_accessModeFullAccess {
    return @"meocloud";
}

@end
