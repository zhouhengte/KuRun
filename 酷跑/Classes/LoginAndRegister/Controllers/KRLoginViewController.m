//
//  KRLoginViewController.m
//  酷跑
//
//  Created by mis on 15/12/3.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRLoginViewController.h"
#import "KRUserInfo.h"
#import "KRXMPPTool.h"
#import "MBProgressHUD+KR.h"

@interface KRLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end

@implementation KRLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *leftVN = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon"]];
    leftVN.contentMode = UIViewContentModeCenter;
    leftVN.frame = CGRectMake(0, 0, 30, 20);
    self.userNameField.leftViewMode = UITextFieldViewModeAlways;
    self.userNameField.leftView = leftVN;
    
    UIImageView *leftVP = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"lock"]];
    leftVP.contentMode = UIViewContentModeCenter;
    leftVP.frame = CGRectMake(0, 0, 30, 20);
    self.passwordField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordField.leftView= leftVP;
}

- (IBAction)loginBtnClick:(id)sender {
    if (self.userNameField.text.length == 0) {
        [MBProgressHUD showError:@"请输入用户名"];
        return;
    }
    [MBProgressHUD showMessage:@"正在登陆"];
    /* 点击按钮把输入框中的值赋值给单例对象 */
    KRUserInfo *userinfo = [KRUserInfo sharedKRUserInfo];
    userinfo.userName = self.userNameField.text;
    userinfo.userPasswd = self.passwordField.text;
    userinfo.registerType = NO;
    KRXMPPTool *xmpptool = [KRXMPPTool sharedKRXMPPTool];
    __weak typeof(self) weakSelf = self;
    [xmpptool userLogin:^(KRXMPPResultType type) {//将block代码块传给xmppTool，获取xmppTool中的数据并执行，xmppTool有可能多次调用该方法，但每次调用时其实都是LoginViewController在执行
        //隐藏消息框
        [MBProgressHUD hideHUD];
        //处理返回状态
        //[self handleXmppResult:type];//block中使用self会导致循环引用,使登陆控制器无法销毁,使用self的弱引用
        [weakSelf handleXmppResult:type];
    }];
}

/** 处理登陆返回状态的方法 */
-(void)handleXmppResult:(KRXMPPResultType) type
{
    
    switch (type) {
        case KRXMPPResultTypeLoginSuccess:
        {//switch语句不能写太长。。。加{}
            MYLog(@"登陆成功");
            [MBProgressHUD showSuccess:@"登陆成功"];
            /* 切换到主界面 */
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            [UIApplication sharedApplication].keyWindow.rootViewController = storyBoard.instantiateInitialViewController;
            break;
        }
        case KRXMPPResultTypeLoginFailed:
            MYLog(@"登陆失败");
            [MBProgressHUD showError:@"登陆失败"];
            break;
        case KRXMPPResultTypeNetError:
            MYLog(@"网络错误");
            [MBProgressHUD showError:@"网络错误"];
            break;
        default:
            break;
    }
}

/* 点击新浪按钮 */
- (IBAction)sinaLoginBtnClick:(id)sender {
    [KRUserInfo sharedKRUserInfo].sinaLoginAndRegister = YES;
    [self performSegueWithIdentifier:@"sinaSegue" sender:nil];
}

//-(void)dealloc
//{
//    //验证是否销毁
//    MYLog(@"%@",self);
//}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
