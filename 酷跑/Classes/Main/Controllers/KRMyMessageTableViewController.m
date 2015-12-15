//
//  KRMyMessageTableViewController.m
//  酷跑
//
//  Created by mis on 15/12/9.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRMyMessageTableViewController.h"
#import "KRXMPPTool.h"
#import "KRUserInfo.h"
#import "KRMeTableViewCell.h"
#import "KRCharViewController.h"


@interface KRMyMessageTableViewController ()<NSFetchedResultsControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic,strong)NSFetchedResultsController *fetchControl;
@property(nonatomic,strong)NSArray *mostMsgs;

@end

@implementation KRMyMessageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadMsg];
}

/** 加载聊天的最后一条消息 */
-(void)loadMsg
{
    /* 获取context */
    NSManagedObjectContext *context = [[KRXMPPTool sharedKRXMPPTool].xmppMsgArchStore mainThreadManagedObjectContext];
    /* 关联实体 */
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"XMPPMessageArchiving_Contact_CoreDataObject"];
    /* 设置条件 设置当前用户的JID和好友的JID */
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"streamBareJidStr = %@",[KRUserInfo sharedKRUserInfo].jidStr];
    request.predicate = pre;
    /* 排序 */
    NSSortDescriptor *sortd = [NSSortDescriptor sortDescriptorWithKey:@"mostRecentMessageTimestamp" ascending:NO];
    request.sortDescriptors = @[sortd];
    /* 执行得到结果 */
    NSError *error = nil;
    //self.mostMsgs = [context executeFetchRequest:request error:&error];//也可直接获取数据
    self.fetchControl = [[NSFetchedResultsController alloc]initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    self.fetchControl.delegate = self;
    [self.fetchControl performFetch:&error];
    if (error) {
        MYLog(@"%@",error.userInfo);
    }
    
}

- (IBAction)BackToMyProfile:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fetchControl.fetchedObjects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KRMeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"meCell"];
    XMPPMessageArchiving_Contact_CoreDataObject *msgObject = self.fetchControl.fetchedObjects[indexPath.row];
    NSData *photo =[[KRXMPPTool sharedKRXMPPTool].xmppvCardAvar photoDataForJID:[XMPPJID jidWithString:[KRUserInfo sharedKRUserInfo].jidStr]];
    if (photo) {
        cell.headImageView.image = [UIImage imageWithData:photo];
    }else{
        cell.headImageView.image = [UIImage imageNamed:@"微信"];
    }
    /* 判断是图片消息 */
    if ([msgObject.mostRecentMessageBody hasPrefix:@"image:"]) {
        NSString *base64Str = [msgObject.mostRecentMessageBody substringFromIndex:6];
        //进行解码
        NSData *data = [[NSData alloc]initWithBase64EncodedString:base64Str options:0];
        cell.MessageImageView.image = [UIImage imageWithData:data];
        cell.MessageImageView.hidden = NO;
        cell.messageContentLabel.text = @"";
    }else{
        cell.messageContentLabel.text = msgObject.mostRecentMessageBody;
        cell.MessageImageView.hidden = YES;
    }
    cell.messageTimeLabel.text = @"2015-12-09";
    cell.userNameLabel.text = [KRUserInfo sharedKRUserInfo].userName;
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPMessageArchiving_Contact_CoreDataObject *msgObject = self.fetchControl.fetchedObjects[indexPath.row];
    [self performSegueWithIdentifier:@"chatSegue2" sender:msgObject.bareJid];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    id desVC = segue.destinationViewController;
    if ([desVC isKindOfClass:[KRCharViewController class]]) {
        KRCharViewController *des = (KRCharViewController *)desVC;
        des.friendJid = sender;
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}


-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    //刷新tableView
    [self.tableView reloadData];
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
