//
//  KRRegisterViewController.m
//  酷跑
//
//  Created by mis on 15/12/4.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRRegisterViewController.h"
#import "KRUserInfo.h"
#import "KRXMPPTool.h"
#import "AFNetworking.h"
#import "NSString+md5.h"

@interface KRRegisterViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userRegisterNameField;
@property (weak, nonatomic) IBOutlet UITextField *userRegisterPasswordField;

@end

@implementation KRRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)backToLogin:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)registerButtonClick:(id)sender {
    [KRUserInfo sharedKRUserInfo].userRegisterName = self.userRegisterNameField.text;
    [KRUserInfo sharedKRUserInfo].userRegisterPasswd = self.userRegisterPasswordField.text;
    [KRUserInfo sharedKRUserInfo].registerType = YES;
    __weak typeof(self) weakVc = self;
    /* 调用KRXMPPTool完成注册 */
    [[KRXMPPTool sharedKRXMPPTool] userRegister:^(KRXMPPResultType type) {
        [weakVc handleRegisterResult:type];
    }];
    
}

/** 处理注册的结果 */
-(void)handleRegisterResult:(KRXMPPResultType)type
{
    switch (type) {
        case KRXMPPResultTypeRegisterSucess:
            MYLog(@"注册成功");
            [MBProgressHUD showSuccess:@"注册成功"];
            //发起web注册
            [self webRegisterForServer];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        case KRXMPPResultTypeRegisterFailed:
            MYLog(@"注册失败");
            [MBProgressHUD showError:@"注册失败"];
            break;
        case KRXMPPResultTypeNetError:
            MYLog(@"网络错误");
            [MBProgressHUD showError:@"网络错误"];
            break;
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
    MYLog(@"%@",parameters[@"md5password"]);
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
