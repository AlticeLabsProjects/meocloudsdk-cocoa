//
//  NSDateFormatter+Additions.m
//  MEOCloudSDK
//
//  Created by Hugo Sousa on 03/07/14.
//
//

#import "NSDateFormatter+CLDAdditions.h"

@implementation NSDateFormatter (Additions)

+ (NSDateFormatter *)serviceDateFormatter {
    static NSDateFormatter *_formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _formatter  = [[NSDateFormatter alloc] init];
        _formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        _formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss ZZZ";
    });
    return _formatter;
}

@end
