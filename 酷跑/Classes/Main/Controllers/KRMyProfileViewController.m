//
//  KRMyProfileViewController.m
//  酷跑
//
//  Created by mis on 15/12/7.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRMyProfileViewController.h"
#import "XMPPvCardTemp.h"
#import "KRXMPPTool.h"
#import "KRUserInfo.h"
#import "KREditMyProfileViewController.h"
#import "UIImageView+KRRoundImageView.h"

@interface KRMyProfileViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *headImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;

@end

@implementation KRMyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置圆形头像
    [self.headImageView setRoundLayer];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    XMPPvCardTemp *vCardTemp = [KRXMPPTool sharedKRXMPPTool].xmppvCard.myvCardTemp;
    if (!vCardTemp.photo) {
        self.headImageView.image = [UIImage imageNamed:@"微信"];
    }else{
        self.headImageView.image = [UIImage imageWithData:vCardTemp.photo];
    }
    self.userNameLabel.text = [KRUserInfo sharedKRUserInfo].userName;
    self.nickNameLabel.text = vCardTemp.nickname;
}


- (IBAction)backToMain:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    id desVc = segue.destinationViewController;
    if ([desVc isKindOfClass:[KREditMyProfileViewController class]]) {
        KREditMyProfileViewController *editVc = (KREditMyProfileViewController *)desVc;
        editVc.vCardTemp = [KRXMPPTool sharedKRXMPPTool].xmppvCard.myvCardTemp;
    }
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
