//
//  NSString+md5.m
//  酷跑
//
//  Created by mis on 15/12/4.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "NSString+md5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (md5)

-(NSString *)md5Str
{
    const char *myPasswd = [self UTF8String];
    unsigned char md5c[16];
    CC_MD5(myPasswd, (CC_LONG)strlen(myPasswd), md5c);
    NSMutableString *md5Str = [NSMutableString string];
    for (int i = 0; i < 16; i ++) {
        [md5Str appendFormat:@"%02x",md5c[i]];
    }
    return md5Str;
}

-(NSString *)md5StrXor
{
    const char *myPasswd = [self UTF8String];
    unsigned char md5c[16];
    CC_MD5(myPasswd, (CC_LONG)strlen(myPasswd), md5c);
    NSMutableString *md5Str = [NSMutableString string];
    [md5Str appendFormat:@"%02x",md5c[0]];
    for (int i = 0; i < 16; i ++) {
        [md5Str appendFormat:@"%02x",md5c[i]^md5c[0]];
    }
    return md5Str;
}

@end
