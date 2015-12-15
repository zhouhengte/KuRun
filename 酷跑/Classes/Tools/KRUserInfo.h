//
//  KRUserInfo.h
//  酷跑
//
//  Created by mis on 15/12/3.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"

@interface KRUserInfo : NSObject
singleton_interface(KRUserInfo)
@property(nonatomic,copy)NSString *userName;
@property(nonatomic,copy)NSString *userPasswd;
/* 注册的用户名 密码 */
@property(nonatomic,copy)NSString *userRegisterName;
@property(nonatomic,copy)NSString *userRegisterPasswd;
/* 区分到底是登陆 还是注册 */
@property(nonatomic,assign,getter=isRegisterType)BOOL registerType;
/* 区分是不是新浪注册和登陆 */
@property(nonatomic,assign)BOOL sinaLoginAndRegister;
@property(nonatomic,copy)NSString *sinaToken;

/* 获取当前用户jidStr的属性 */
@property(nonatomic,copy) NSString *jidStr;

@end
