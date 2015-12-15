//
//  KRSinaLoginViewController.m
//  酷跑
//
//  Created by mis on 15/12/7.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRSinaLoginViewController.h"
#import "AFNetworking.h"
#import "KRUserInfo.h"
#import "KRXMPPTool.h"
#import "MBProgressHUD+KR.h"
#import "NSString+md5.h"
#define  APPKEY       @"2075708624"
//#define  APPKEY       @"2216974040"
#define  REDIRECT_URI @"http://www.tedu.cn"
#define  APPSECRET    @"36a3d3dec55af644cd94a316fdd8bfd8"
//#define  APPSECRET    @"67b689248e11e52b52e2c3c9c78b0cae"


@interface KRSinaLoginViewController ()<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation KRSinaLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /* 按照新浪官方文档发送web请求 */
    self.webView.delegate = self;
    NSString  *urlStr = [NSString stringWithFormat:@"https://api.weibo.com/oauth2/authorize?client_id=%@&redirect_uri=%@",APPKEY,REDIRECT_URI];
    NSURL  *url = [NSURL URLWithString:urlStr];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];

}

//在webview发送的请求前调用，返回yes则发送
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *urlPath = request.URL.absoluteString;
    //MYLog(@"urlPath=%@",urlPath);
    /* 包含 http://www/tedu/cn/?code= */
    NSRange range = [urlPath rangeOfString:[NSString stringWithFormat:@"%@%@",REDIRECT_URI,@"/?code="]];
    NSString *code = nil;
    //检索请求，如果包含http://www/tedu/cn/?code=，则截取之后的code
    if (range.length > 0) {
        code = [urlPath substringFromIndex:range.length];
        MYLog(@"code=%@",code);
        /* 使用code 换取access_token */
        [self accessTokenWithCode:code];
        return NO;
    }
    //不包含http://www/tedu/cn/?code=，继续检索下一个请求
    return YES;
}


-(void)accessTokenWithCode:(NSString *)code
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *urlStr = @"https://api.weibo.com/oauth2/access_token";
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    /* 按照官方文档填写参数 */
    parameters[@"client_id"] = APPKEY;
    parameters[@"client_secret"] = APPSECRET;
    parameters[@"grant_type"] = @"authorization_code";
    parameters[@"code"] = code;
    parameters[@"redirect_uri"] = REDIRECT_URI;
    //发送请求
    [manager POST:urlStr parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        MYLog(@"%@",responseObject);
        /* 从responseObject中获取uid和access_token,这里使用uid 作为用户名的一部分,access_token 加密之后作为密码 */
        [KRUserInfo sharedKRUserInfo].sinaToken = responseObject[@"access_token"];
        if ([KRUserInfo sharedKRUserInfo].sinaLoginAndRegister) {
            //不管用户是否注册过 都去注册
            [KRUserInfo sharedKRUserInfo].userRegisterName = responseObject[@"uid"];
            [KRUserInfo sharedKRUserInfo].userRegisterPasswd = responseObject[@"access_token"];
//            MYLog(@"%@,%@",[KRUserInfo sharedKRUserInfo].userRegisterName,[KRUserInfo sharedKRUserInfo].userRegisterPasswd);
            /* 就是把新浪注册 装换成普通注册 */
            [KRUserInfo sharedKRUserInfo].registerType = YES;
            __weak typeof (self) sinaVc = self;
            [[KRXMPPTool sharedKRXMPPTool] userRegister:^(KRXMPPResultType type) {
                //处理注册结果
                [sinaVc handleRegisterResultType:type];
            }];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MYLog(@"%@",error);
    }];
    
}

/** 处理注册结果的 处理方法 */
-(void) handleRegisterResultType:(KRXMPPResultType)type
{
    //成功 失败 网络错误
    switch (type) {
        case KRXMPPResultTypeRegisterSucess:
            //处理web注册
            [self webRegisterForServer];
        case KRXMPPResultTypeRegisterFailed:
        {
            [KRUserInfo sharedKRUserInfo].userName = [KRUserInfo sharedKRUserInfo].userRegisterName;
            [KRUserInfo sharedKRUserInfo].userPasswd = [KRUserInfo sharedKRUserInfo].userRegisterPasswd;
            [KRUserInfo sharedKRUserInfo].registerType = NO;
            /* 无论注册成功与否都要登陆 */
            [[KRXMPPTool sharedKRXMPPTool] userLogin:^(KRXMPPResultType type) {
                /* 处理登陆的返回结果 */
                [self handleLoginResult:type];
            }];
            break;
        }
            
        default:
            break;
    }
    
}


/** 完成web注册请求的方法 */
-(void)webRegisterForServer
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = [NSString stringWithFormat:@"http://%@:8080/allRunServer/register.jsp",KRXMPPHOSTNAME];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"username"] = [KRUserInfo sharedKRUserInfo].userRegisterName;
    parameters[@"md5password"] = [[KRUserInfo sharedKRUserInfo].userRegisterPasswd md5Str];

    parameters[@"nickname"] = [KRUserInfo sharedKRUserInfo].userRegisterName;
    [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        UIImage *image = [UIImage imageNamed:@"58"];
        NSData *data = UIImagePNGRepresentation(image);
        [formData appendPartWithFileData:data name:@"pic" fileName:@"headerImage.png" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        MYLog(@"%@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MYLog(@"%@",error);
    }];
    
}

/* 处理登陆地返回结果 */
-(void) handleLoginResult:(KRXMPPResultType)type
{
    switch (type) {
        case KRXMPPResultTypeLoginSuccess:
        {
            //跳转到主界面
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            [UIApplication sharedApplication].keyWindow.rootViewController = storyBoard.instantiateInitialViewController;
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case KRXMPPResultTypeLoginFailed:
            MYLog(@"sina login failed");
            break;
        case KRXMPPResultTypeNetError:
            MYLog(@"sina login netError");
            break;
            
        default:
            break;
    }
}



- (IBAction)BackToLogin:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
