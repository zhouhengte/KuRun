//
//  KRCharViewController.m
//  酷跑
//
//  Created by mis on 15/12/9.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRCharViewController.h"
#import "XMPPMessage.h"
#import "KRXMPPTool.h"
#import "KRUserInfo.h"
#import "KRMeTableViewCell.h"

@interface KRCharViewController ()<UITableViewDataSource,UITableViewDelegate,NSFetchedResultsControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightForBottom;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
/** 消息结果控制器 */
@property(nonatomic,strong)NSFetchedResultsController *fetchControl;

@end

@implementation KRCharViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //tableview自适应高度
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 80;
    //上方自动留白设置为NO
    self.automaticallyAdjustsScrollViewInsets = NO;
    /* 加载消息 */
    [self loadMsg];
}

-(void)loadMsg
{
    /* 获取context */
    NSManagedObjectContext *context = [[KRXMPPTool sharedKRXMPPTool].xmppMsgArchStore mainThreadManagedObjectContext];
    /* 关联实体 */
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"XMPPMessageArchiving_Message_CoreDataObject"];
    /* 设置条件 设置当前用户的JID和好友的JID */
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"streamBareJidStr = %@ and bareJidStr = %@",[KRUserInfo sharedKRUserInfo].jidStr,[self.friendJid bare]];
    request.predicate = pre;
    /* 排序 */
    NSSortDescriptor *sortd = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
    request.sortDescriptors = @[sortd];
    /* 执行得到结果 */
    self.fetchControl = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    NSError *error = nil;
    self.fetchControl.delegate = self;
    [self.fetchControl performFetch:&error];
    if (error) {
        MYLog(@"%@",error.userInfo);
    }
    
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fetchControl.fetchedObjects.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KRMeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"meCell"];
    XMPPMessageArchiving_Message_CoreDataObject *msgObject = self.fetchControl.fetchedObjects[indexPath.row];
    NSData *photo =[[KRXMPPTool sharedKRXMPPTool].xmppvCardAvar photoDataForJID:[XMPPJID jidWithString:[KRUserInfo sharedKRUserInfo].jidStr]];
    if (photo) {
        cell.headImageView.image = [UIImage imageWithData:photo];
    }else{
        cell.headImageView.image = [UIImage imageNamed:@"微信"];
    }
    /* 判断是图片消息 */
    if ([msgObject.body hasPrefix:@"image:"]) {
        NSString *base64Str = [msgObject.body substringFromIndex:6];
        //进行解码
        NSData *data = [[NSData alloc]initWithBase64EncodedString:base64Str options:0];
        cell.MessageImageView.image = [UIImage imageWithData:data];
        cell.MessageImageView.hidden = NO;
        cell.messageContentLabel.text = @"";
    }else{
        cell.messageContentLabel.text = msgObject.body;
        cell.MessageImageView.hidden = YES;
    }
    cell.messageTimeLabel.text = @"2015-12-09";
    cell.userNameLabel.text = [KRUserInfo sharedKRUserInfo].userName;
    return cell;
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    //刷新tableView
    [self.tableView reloadData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

//-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
//{
//    if (![self.sendTextField isExclusiveTouch]) {
//        [self.sendTextField resignFirstResponder];
//    }
//    
//}

-(void)openKeyboard:(NSNotification *)notification
{
    //获取键盘frame
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    //键盘弹出的动画选项
    NSTimeInterval durations = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]doubleValue];
    UIViewAnimationOptions options = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey]intValue];
    
    self.heightForBottom.constant = keyboardFrame.size.height;
    //动画
    [UIView animateWithDuration:durations delay:0 options:options animations:^{
        //重新调整布局
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

-(void)closeKeyboard:(NSNotification *)notification
{
    //键盘收回的动画选项
    NSTimeInterval durations = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]doubleValue];
    UIViewAnimationOptions options = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey]intValue];
    
    self.heightForBottom.constant = 0;
    //动画
    [UIView animateWithDuration:durations delay:0 options:options animations:^{
        //重新调整布局
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

/** 发送文本消息 */
- (IBAction)sendTextMethod:(id)sender {
    NSString *msgText = self.sendTextField.text;
    //组装一个消息
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:self.friendJid];
    [msg addBody:msgText];
    /* 发送消息 */
    [[KRXMPPTool sharedKRXMPPTool].xmppStream sendElement:msg];
}

- (IBAction)sendClick:(id)sender {
    [self sendTextMethod:self.sendTextField];
}
//发送图片
- (IBAction)ImageClick:(id)sender {
    UIImagePickerController *pc = [[UIImagePickerController alloc]init];
    pc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pc.delegate = self;
    //是否可编辑，貌似没用
    pc.editing = YES;
    [self presentViewController:pc animated:YES completion:nil];
    
}

/** 选择图片 */
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    //获取选择的原图
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    MYLog(@"image length = %ld",UIImagePNGRepresentation(image).length);
    /* 生成缩略图 */
    UIImage *newImage = [self thumbnaiWithImage:image Size:CGSizeMake(100, 100)];
    MYLog(@"NewImage length = %ld",UIImagePNGRepresentation(newImage).length);
    //也可以继续压缩图片
    NSData *data2 = UIImageJPEGRepresentation(newImage, 0.05);
    MYLog(@"NewImage length = %ld",data2.length);
    // data2的图片数据 包装成消息发送出去
    [self sendImageMethod:data2];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

/** 发送图片消息的方法 */
-(void)sendImageMethod:(NSData *)data
{
    //组装一个消息
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:self.friendJid];
    //用base64将图片数据转成文本数据
    NSString *base64Str = [data base64EncodedStringWithOptions:0];
    [msg addBody:[@"image:"stringByAppendingString:base64Str]];
    /* 发送消息 */
    [[KRXMPPTool sharedKRXMPPTool].xmppStream sendElement:msg];
}


/** 生成缩略图 */
-(UIImage *) thumbnaiWithImage:(UIImage *)image Size:(CGSize)size
{
    UIImage *newImage = nil;
    if (nil == image) {
        newImage = nil;
    }else{
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    return newImage;
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
