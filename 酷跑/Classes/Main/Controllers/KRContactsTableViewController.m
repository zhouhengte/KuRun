//
//  KRContactsTableViewController.m
//  酷跑
//
//  Created by mis on 15/12/8.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRContactsTableViewController.h"
#import "KRXMPPTool.h"
#import "KRFriendCell.h"
#import "UIImageView+KRRoundImageView.h"
#import "KRUserInfo.h"
#import "KRCharViewController.h"

@interface KRContactsTableViewController ()<NSFetchedResultsControllerDelegate>

//@property(nonatomic,strong)NSArray *friends;
@property(nonatomic,strong)NSFetchedResultsController *fetchController;

@end

@implementation KRContactsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    /* 加载好友 */
    //[self loadFriend1];
    [self loadFriend2];
    
}

//-(void)loadFriend1
//{
//    //coredata获取数据步骤:
//    //获取上下文
//    NSManagedObjectContext *context = [[KRXMPPTool sharedKRXMPPTool].xmppRosterStroe mainThreadManagedObjectContext];
//    //关联实体NSFetchRequest 关联实体
//    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"XMPPUserCoreDataStorageObject"];
//    //设置过滤条件
//    NSPredicate *pre = [NSPredicate predicateWithFormat:@"streamBareJidStr = %@",[KRUserInfo sharedKRUserInfo].jidStr];
//    request.predicate = pre;
//    //排序
//    NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
//    request.sortDescriptors = @[nameSort];
//    //获取数据
//    NSError *error = nil;
//    self.friends = [context executeFetchRequest:request error:&error];
//    if (error) {
//        MYLog(@"%@",error.userInfo);
//    }
//}

-(void)loadFriend2
{
    //coredata获取数据步骤:
    //获取上下文
    NSManagedObjectContext *context = [[KRXMPPTool sharedKRXMPPTool].xmppRosterStroe mainThreadManagedObjectContext];
    //关联实体NSFetchRequest 关联实体XMPPUserCoreDataStorageObject即为好友列表实体
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:@"XMPPUserCoreDataStorageObject"];
    //设置过滤条件,获取当前登录账号的好友列表
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"streamBareJidStr = %@",[KRUserInfo sharedKRUserInfo].jidStr];
    request.predicate = pre;
    //排序
    NSSortDescriptor *nameSort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES];
    request.sortDescriptors = @[nameSort];
    //获取数据
    self.fetchController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    self.fetchController.delegate = self;
    NSError *error = nil;
    [self.fetchController performFetch:&error];
    if (error) {
        MYLog(@"%@",error.userInfo);
    }
    
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
    //return self.friends.count;
    return  self.fetchController.fetchedObjects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"friendCell";
    KRFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    //XMPPUserCoreDataStorageObject *friend = self.friends[indexPath.row];
    XMPPUserCoreDataStorageObject *friend = self.fetchController.fetchedObjects[indexPath.row];
    NSData *data = [[KRXMPPTool sharedKRXMPPTool].xmppvCardAvar photoDataForJID:friend.jid];
    [cell.headImageView setRoundLayer];
    if (!data) {
        cell.headImageView.image = [UIImage imageNamed:@"微信"];
    }else{
        cell.headImageView.image = [UIImage imageWithData:data];
    }
    cell.friendNameLabel.text = friend.jidStr;
    //状态
    switch (friend.sectionNum.intValue) {
        case 0:
            cell.friendStatusLabel.text = @"在线";
            break;
        case 1:
            cell.friendStatusLabel.text = @"离开";
            break;
        case 2:
            cell.friendStatusLabel.text = @"离线";
        default:
            break;
    }
    
    return cell;
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    //一旦数据发生变化，就更新tableView
    [self.tableView reloadData];
}

/** 编辑模式 */
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPUserCoreDataStorageObject *friend = self.fetchController.fetchedObjects[indexPath.row];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //删除好友
        [[KRXMPPTool sharedKRXMPPTool].xmppRoster removeUser:friend.jid];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPUserCoreDataStorageObject *f = self.fetchController.fetchedObjects[indexPath.row];
    [self performSegueWithIdentifier:@"chatSegue" sender:f.jid];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    id desVC = segue.destinationViewController;
    if ([desVC isKindOfClass:[KRCharViewController class]]) {
        KRCharViewController *des = (KRCharViewController *)desVC;
        des.friendJid = sender;
    }
}


- (IBAction)backClick:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
