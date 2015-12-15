//
//  KRUserInfo.m
//  酷跑
//
//  Created by mis on 15/12/3.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRUserInfo.h"

@implementation KRUserInfo
singleton_implementation(KRUserInfo);
-(NSString *)jidStr
{
    NSString *jidS = [NSString stringWithFormat:@"%@@%@",self.userName,KRXMPPDOMAIN];
    return jidS;
}
@end
