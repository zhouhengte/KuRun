//
//  KRXMPPTool.h
//  酷跑
//
//  Created by mis on 15/12/3.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"
#import "XMPPFramework.h"
#import "XMPPMessageArchiving.h"
#import "XMPPMessageArchivingCoreDataStorage.h"


typedef enum
{
    KRXMPPResultTypeLoginSuccess,
    KRXMPPResultTypeLoginFailed,
    KRXMPPResultTypeNetError,
    KRXMPPResultTypeRegisterSucess,
    KRXMPPResultTypeRegisterFailed
}KRXMPPResultType;
/* 定义BLOCK */
typedef void(^KRXMPPResultBlock)(KRXMPPResultType type);

@interface KRXMPPTool : NSObject
singleton_interface(KRXMPPTool);

@property (strong, nonatomic) XMPPStream *xmppStream;

/** 管理电子名片 */
@property (nonatomic,strong)XMPPvCardCoreDataStorage *xmppvCardStore;

/** 增加电子名片模块 和 头像模块 */
@property (nonatomic,strong)XMPPvCardTempModule *xmppvCard;
@property (nonatomic,strong)XMPPvCardAvatarModule *xmppvCardAvar;

/** 增加花名册模块 和 对应的存储 */
@property(nonatomic,strong)XMPPRoster *xmppRoster;
@property(nonatomic,strong)XMPPRosterCoreDataStorage *xmppRosterStroe;

/** 增加消息模块 和 对应的存储 */
@property(nonatomic,strong)XMPPMessageArchiving *xmppMsgArch;
@property(nonatomic,strong)XMPPMessageArchivingCoreDataStorage *xmppMsgArchStore;

/* 用户登陆 哪里需要XMPP的登陆状态就传一个BLOCK进来即可 */
-(void) userLogin:(KRXMPPResultBlock) block;
/* 用户注册 哪里需要XMPP的登陆装改就传一个BLOCK进来即可 */
-(void) userRegister:(KRXMPPResultBlock) block;
@end
