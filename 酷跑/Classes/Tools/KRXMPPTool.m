//
//  KRXMPPTool.m
//  酷跑
//
//  Created by mis on 15/12/3.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRXMPPTool.h"
#import "KRUserInfo.h"

@interface KRXMPPTool ()<XMPPStreamDelegate>

{
    KRXMPPResultBlock _resultBlock;
}

/** 设置XMPPStream */
-(void) setupXMPPStream;
/** 连接到服务器 */
-(void) connectToServer;
/** 发送密码 请求授权 */
-(void) sendPassword;
/** 发送在线消息 */
-(void) sendOnLine;
@end

@implementation KRXMPPTool

singleton_implementation(KRXMPPTool);

/** 设置XMPPStream */
-(void) setupXMPPStream
{
    self.xmppStream = [[XMPPStream alloc]init];
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    /* 初始化电子名片模块和头像模块 */
    self.xmppvCardStore = [XMPPvCardCoreDataStorage sharedInstance];
    self.xmppvCard = [[XMPPvCardTempModule alloc]initWithvCardStorage:self.xmppvCardStore];
    self.xmppvCardAvar = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:self.xmppvCard];
    /* 初始化花名册模块 */
    self.xmppRosterStroe = [XMPPRosterCoreDataStorage sharedInstance];
    self.xmppRoster = [[XMPPRoster alloc]initWithRosterStorage:self.xmppRosterStroe];
    /* 初始化消息模块 */
    self.xmppMsgArchStore = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    self.xmppMsgArch = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:self.xmppMsgArchStore];
    
    //激活电子名片模块 和 头像模块
    [self.xmppvCard activate:self.xmppStream];
    [self.xmppvCardAvar activate:self.xmppStream];
    //激活花名册模块
    [self.xmppRoster activate:self.xmppStream];
    //激活消息模块
    [self.xmppMsgArch activate:self.xmppStream];
}

/** 连接到服务器 */
-(void) connectToServer
{
    /* 断开上一次连接 */
    [self.xmppStream disconnect];
    if (self.xmppStream == nil) {
        [self setupXMPPStream];
    }
    self.xmppStream.hostName = KRXMPPHOSTNAME;
    self.xmppStream.hostPort = KRXMPPPORT;
    /* 构建一个JID */
    NSString *userName = nil;
    /* 注册和登陆的区别是 登陆的时候拿登录名 注册的时候拿注册名 其他连接服务器的代码都相同 */
    if ([KRUserInfo sharedKRUserInfo].isRegisterType) {
        userName = [KRUserInfo sharedKRUserInfo].userRegisterName;
    }else{
        userName = [KRUserInfo sharedKRUserInfo].userName;
    }
    NSString *jidStr = [NSString stringWithFormat:@"%@@%@",userName,KRXMPPDOMAIN];
    XMPPJID *myJid = [XMPPJID jidWithString:jidStr];
    self.xmppStream.myJID = myJid;
    NSError *error = nil;
    [self.xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error];
    if (error) {
        MYLog(@"%@",error);
    }

}

/** 发送密码 请求授权/注册 */
-(void) sendPassword
{
    NSString *userpasswd = nil;
    NSError *error = nil;
    if ([KRUserInfo sharedKRUserInfo].isRegisterType) {
        userpasswd = [KRUserInfo sharedKRUserInfo].userRegisterPasswd;
        //请求注册
        [self.xmppStream registerWithPassword:userpasswd error:&error];
    }else{
        userpasswd = [KRUserInfo sharedKRUserInfo].userPasswd;
        //请求授权
        [self.xmppStream authenticateWithPassword:userpasswd error:&error];
    }
    if (error) {
        MYLog(@"%@",error);
    }
}

/** 发送在线消息 */
-(void) sendOnLine
{
    XMPPPresence *presence = [XMPPPresence presence];
    [self.xmppStream sendElement:presence];
}

#pragma mark --- XMPPStreamDelegate
/** 连接成功 */
-(void)xmppStreamDidConnect:(XMPPStream *)sender
{
    [self sendPassword];
}

-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    if (error) {
        _resultBlock(KRXMPPResultTypeNetError);//执行block代码块中的语句，运行环境仍为block代码块所在的环境，相当于将参数传给block代码块所在的环境下运行
        MYLog(@"%@",error);
    }
}

/** 用户注册成功 */
-(void)xmppStreamDidRegister:(XMPPStream *)sender{
    _resultBlock(KRXMPPResultTypeRegisterSucess);
}

/** 用户注册失败 */
-(void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{
    _resultBlock(KRXMPPResultTypeRegisterFailed);
    MYLog(@"注册失败%@",error);
}

/** 授权成功 */
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    _resultBlock(KRXMPPResultTypeLoginSuccess);
    [self sendOnLine];
}

-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    _resultBlock(KRXMPPResultTypeLoginFailed);
    MYLog(@"没有授权%@",error);
}



/* 用户登陆 */
-(void) userLogin:(KRXMPPResultBlock) block
{
    _resultBlock = block;//将block代码块引入，最终运行环境仍为block代码块所在的环境
    [self connectToServer];
    
}

/* 用户注册 */
- (void)userRegister:(KRXMPPResultBlock)block
{
    _resultBlock = block;
    [self connectToServer];
}


@end
