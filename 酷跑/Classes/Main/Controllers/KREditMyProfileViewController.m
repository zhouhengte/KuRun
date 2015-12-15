//
//  KREditMyProfileViewController.m
//  酷跑
//
//  Created by mis on 15/12/8.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KREditMyProfileViewController.h"
#import "KRXMPPTool.h"
#import "UIImageView+KRRoundImageView.h"

@interface KREditMyProfileViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *headImageView;
@property (weak, nonatomic) IBOutlet UITextField *nickNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@end

@implementation KREditMyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.vCardTemp.photo) {
        self.headImageView.image = [UIImage imageWithData:self.vCardTemp.photo];
    }else{
        self.headImageView.image = [UIImage imageNamed:@"微信"];
    }
    //设置圆形头像
    [self.headImageView setRoundLayer];
    
    /* 增加手势识别 */
    self.headImageView.userInteractionEnabled = YES;
    [self.headImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headImageTap)]];
    
    self.nickNameTextField.text = self.vCardTemp.nickname;
    self.emailTextField.text = self.vCardTemp.mailer;
}

/* 图片tap方法的处理 */
-(void)headImageTap
{
    UIActionSheet *sht = [[UIActionSheet alloc]initWithTitle:@"请选择" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"照相机" otherButtonTitles:@"相册", nil];
    [sht showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 2) {
        MYLog(@"取消");
    }else if(buttonIndex == 1){
        MYLog(@"相册");
        //推出相册
        UIImagePickerController *pc = [[UIImagePickerController alloc] init];
        pc.allowsEditing = YES;
        pc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        pc.delegate = self;
        [self presentViewController:pc animated:YES completion:nil];
    }else{
        MYLog(@"照相机");
        //判断设备是否支持相机
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController *pc = [[UIImagePickerController alloc]init];
            pc.allowsEditing = YES;
            pc.sourceType = UIImagePickerControllerCameraCaptureModeVideo;
            pc.delegate = self;
            [self presentViewController:pc animated:YES completion:nil];
        }
    }
}

/** 选择图片的处理 */
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    //获取选中的图片
    UIImage *image = info[UIImagePickerControllerEditedImage];
    self.headImageView.image = image;
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (IBAction)saveMyProfile:(id)sender {
    /* 得到用户输入的数据 头像 昵称 邮件 更新 */
    self.vCardTemp.photo = UIImagePNGRepresentation(self.headImageView.image);
    self.vCardTemp.nickname = self.nickNameTextField.text;
    self.vCardTemp.mailer = self.emailTextField.text;
    [[KRXMPPTool sharedKRXMPPTool].xmppvCard updateMyvCardTemp:self.vCardTemp];
    [self dismissViewControllerAnimated:YES completion:nil];
    
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
