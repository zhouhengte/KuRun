//
//  KRSportViewController.m
//  酷跑
//
//  Created by mis on 15/12/10.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "KRSportViewController.h"
#import <BaiduMapAPI_Map/BMKMapView.h>
#import <BaiduMapAPI_Map/BMKPointAnnotation.h>
#import <BaiduMapAPI_Search/BMKPoiSearch.h>
#import <BaiduMapAPI_Location/BMKLocationService.h>
#import <BaiduMapAPI_Utils/BMKGeometry.h>
#import <BaiduMapAPI_Map/BMKPinAnnotationView.h>
#import <BaiduMapAPI_Map/BMKPolyline.h>
#import <BaiduMapAPI_Map/BMKPolylineView.h>
#import "AFNetworking.h"
#import "KRXMPPTool.h"
#import "KRUserInfo.h"

/** 是TrailStart就在地图上画跟踪轨迹线 否则不画 */
typedef enum {
    TrailStart = 1,
    TrailEnd
}Trail;
#define BMKSPAN 0.002

@interface KRSportViewController ()<BMKMapViewDelegate, BMKPoiSearchDelegate,BMKLocationServiceDelegate>
//百度地图的view
@property (nonatomic, strong) BMKMapView *mapView;
@property (nonatomic, strong) BMKPoiSearch *poiSearch;
//百度地图位置服务
@property (nonatomic,strong) BMKLocationService *bmkLocationService;
//用来标记是否画轨迹线
@property (nonatomic,assign) Trail trail;
//起点大头针 和 终点大头针
@property (nonatomic,strong) BMKPointAnnotation *startPoint;
@property (nonatomic,strong) BMKPointAnnotation *endPoint;
//位置数组
@property (nonatomic,strong) NSMutableArray *locationArrayM;
@property (weak, nonatomic) IBOutlet UIButton *startRunningButton;
//记录上一次位置
@property (nonatomic,strong) CLLocation *preLocation;

@property (nonatomic,assign) CGFloat sumDistance;
@property (nonatomic,assign) CGFloat sportTime;
@property (nonatomic,assign) CGFloat sumHeat;
/* 地图上的遮盖线 */
@property (nonatomic,strong) BMKPolyline *polyLine;
@property (weak, nonatomic) IBOutlet UIButton *pauseRunningButton;
@property (weak, nonatomic) IBOutlet UIView *pauseRunningView;
- (IBAction)continueRunningButtonClick:(UIButton *)sender;
- (IBAction)completeRunningButtonClick:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UIView *completeViewUp;
@property (weak, nonatomic) IBOutlet UIView *completeViewDown;


@end

@implementation KRSportViewController

-(NSMutableArray *)locationArrayM
{
    if (_locationArrayM == nil) {
        _locationArrayM = [NSMutableArray array];
    }
    return _locationArrayM;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化mapView/poiSearch
    self.poiSearch = [[BMKPoiSearch alloc] init];
    self.mapView = [[BMKMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view insertSubview:self.mapView atIndex:0];
    
    
    //设置poi的delegate
    self.poiSearch.delegate = self;
    
    
    [self initBMLocationService];
    [self setMapViewProperty];
    self.trail = TrailEnd;
    self.bmkLocationService.delegate = self;
    self.mapView.delegate = self;
    [self.bmkLocationService startUserLocationService];
    
    //对暂停按钮增加手势识别
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(pauseBtnSwip)];
    gesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.pauseRunningButton addGestureRecognizer:gesture];
    
    
}

-(void)pauseBtnSwip
{
    self.pauseRunningButton.hidden = YES;
    self.pauseRunningView.hidden = NO;
    /* 停止位置服务 */
    [self.bmkLocationService stopUserLocationService];
}

/** 初始化百度位置服务 */
-(void) initBMLocationService
{
    self.bmkLocationService = [[BMKLocationService alloc]init];
    //设置距离过滤器，当距离大于xx时再重新定位
    self.bmkLocationService.distanceFilter = 5;
    self.bmkLocationService.desiredAccuracy = kCLLocationAccuracyBest;
//    [BMKLocationService setLocationDistanceFilter:5];
//    [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyBest];
}

/** 设置百度mapView的一些属性 */
-(void)setMapViewProperty
{
    //显示定位图层
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = BMKUserTrackingModeNone;
    self.mapView.rotateEnabled = NO;
    //比例尺
    self.mapView.showMapScaleBar = YES;
    //比例尺的位置
    self.mapView.mapScaleBarPosition = CGPointMake(self.view.frame.size.width-50, self.view.frame.size.height-50);
    //定位图层 自定义样式参数
    BMKLocationViewDisplayParam *displayParam = [[BMKLocationViewDisplayParam alloc]init];
    //经度圈
    displayParam.isAccuracyCircleShow = NO;
    //跟随态旋转角度
    displayParam.isRotateAngleValid = NO;
    //纠偏
    displayParam.locationViewOffsetX = 0;
    displayParam.locationViewOffsetY = 0;
    //提交自定义参数
    [self.mapView updateLocationViewWithParam:displayParam];
    
}

/** 用户位置更新 */
-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    MYLog(@"用户位置变化 %lf:%lf",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    [self.mapView updateLocationData:userLocation];
    /* 以用户目前位置为中心点 并设置扇区范围 */
    if (self.trail == TrailEnd) {
        BMKCoordinateRegion adjustRegion = [self.mapView regionThatFits:BMKCoordinateRegionMake(userLocation.location.coordinate,BMKCoordinateSpanMake(BMKSPAN,BMKSPAN))];
        [self.mapView setRegion:adjustRegion animated:YES];
    }
    //通过定位的精度，判断是通过GPS还是基站定位，从而判断有没有在室外活动
    if (userLocation.location.horizontalAccuracy > kCLLocationAccuracyNearestTenMeters) {
        //判断没有在室外活动
        return;
    }
    if (self.trail == TrailStart) {
        //开始跟踪用户
        [self startTrailRouterWithUserLocation:userLocation];
        //用户当前位置作为地图中心点
        [self.mapView setRegion:BMKCoordinateRegionMake(userLocation.location.coordinate, BMKCoordinateSpanMake(BMKSPAN, BMKSPAN)) animated:YES];
    }
}

-(void)startTrailRouterWithUserLocation:(BMKUserLocation *)userLocation
{
    if (self.preLocation) {
        //计算本次定位和上一个位置的距离
        CGFloat distance = [userLocation.location distanceFromLocation:self.preLocation];
        self.sumDistance += distance;
    }
    self.preLocation = userLocation.location;
    //把用户位置存入数组
    [self.locationArrayM addObject:userLocation.location];
    //绘图
    [self drawWalkPolyline];
}

/* 绘制覆盖线 */
-(void) drawWalkPolyline
{
    NSInteger count = self.locationArrayM.count;
    //百度地图的覆盖线初始化需要传入BMKMapPoint类型的参数，但是该参数又要是一个数组，使用C语言的malloc进行改造
    BMKMapPoint *tempPoints = (BMKMapPoint *)malloc(sizeof(BMKMapPoint)*count);
    //使用C++动态内存，文件名后缀改为.mm
    //BMKMapPoint *tempPoints = new BMKMapPoint[count];
    [self.locationArrayM enumerateObjectsUsingBlock:^(CLLocation* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        /* 把CLLocation 转换成BMKMapPoint */
        BMKMapPoint point = BMKMapPointForCoordinate(obj.coordinate);
        tempPoints[idx] = point;
        
    }];
        self.polyLine = [BMKPolyline polylineWithPoints:tempPoints count:count];
    /* 加载遮盖 */
    if (self.polyLine) {
        [self.mapView addOverlay:self.polyLine];
    }
    //释放内存,C语言
    free(tempPoints);
    //释放内存，C++
    //delete [] tempPoints;
}

-(BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView *polyLineView = [[BMKPolylineView alloc]initWithOverlay:overlay];
        polyLineView.fillColor = [[UIColor clearColor]colorWithAlphaComponent:0.7];
        polyLineView.strokeColor = [[UIColor greenColor] colorWithAlphaComponent:0.7];
        polyLineView.lineWidth = 5.0;
        return polyLineView;
    }
    return nil;
}


/** 显示大头针 */
-(BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        BMKPinAnnotationView *annotationView = [[BMKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        //如果有起点 设置终点图片 否则设置起点图片
        if (self.startPoint) {
            annotationView.image = [UIImage imageNamed:@"定位-终"];
        }else{
            annotationView.image = [UIImage imageNamed:@"定位-起"];
        }
        annotationView.animatesDrop = YES;
        annotationView.draggable = NO;
        return annotationView;
    }
    return nil;
}

/** 添加大头针的方法 */
-(BMKPointAnnotation *)creatPointWithLocation:(CLLocation *)location title:(NSString *)title
{
    BMKPointAnnotation *point = [[BMKPointAnnotation alloc]init];
    point.coordinate = location.coordinate;
    point.title = title;
    //添加大头针 到mapView
    [self.mapView addAnnotation:point];
    return point;
}
- (IBAction)startRunning:(id)sender {
    self.trail = TrailStart;
    self.startPoint = [self creatPointWithLocation:self.bmkLocationService.userLocation.location title:@"起点"];
    [self.locationArrayM addObject:self.bmkLocationService.userLocation.location];
    UIButton *button = (UIButton *)sender;
    button.hidden = YES;
    //self.startRunningButton.hidden = YES;
    
    self.pauseRunningButton.hidden = NO;

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

- (IBAction)continueRunningButtonClick:(UIButton *)sender {
    [self.bmkLocationService startUserLocationService];
    self.pauseRunningView.hidden = YES;
    self.pauseRunningButton.hidden = NO;
}

/** 运动完成 */
- (IBAction)completeRunningButtonClick:(UIButton *)sender {
    // 隐藏暂停视图 把起点和终点同时显示在地图上 重新产生新界面
    self.pauseRunningView.hidden = YES;
    if (self.startPoint) {
        self.endPoint = [self creatPointWithLocation:[self.locationArrayM lastObject] title:@"终点"];
    }
    [self mapviewFitPolyLine:self.polyLine];
    
    self.completeViewUp.hidden = NO;
    self.completeViewDown.hidden = NO;
    CLLocation *firstLoc = [self.locationArrayM firstObject];
    CLLocation *lastLoc = [self.locationArrayM lastObject];
    self.sportTime = [lastLoc.timestamp timeIntervalSince1970] - [firstLoc.timestamp timeIntervalSince1970];
    self.sumHeat = (self.sportTime/3600.0)*600.0;
}

/** 根据用户的位置点 把所有的位置都显示到地图范围 */
-(void)mapviewFitPolyLine:(BMKPolyline *)polyLine
{
    CGFloat ltX,ltY,maX,maY;
    if (polyLine.pointCount < 1) {
        return;
    }
    BMKMapPoint pt = polyLine.points[0];
    ltX = pt.x;
    ltY = pt.y;
    maX = pt.x;
    maY = pt.y;
    for (int i = 1; i < polyLine.pointCount; i++) {
        BMKMapPoint temp = polyLine.points[i];
        if (temp.x < ltX) {
            ltX = temp.x;
        }
        if (temp.y < ltY) {
            ltY = temp.y;
        }
        if (temp.x > maX) {
            maX = temp.x;
        }
        if (temp.y > maY) {
            maY = temp.y;
        }
    }
    BMKMapRect rect = BMKMapRectMake(ltX-40, ltY-60, maX - ltX + 80, maY - ltY + 120);
    self.mapView.visibleMapRect = rect;
}

- (IBAction)shareDataToSina:(id)sender {
//    /* 组装微博数据 运动距离 运动时长 运动消耗能量 */
//    NSString *statusStr = [NSString stringWithFormat:@"本次运动总距离:%.1lf米，运动总时间为:%.1lf秒，消耗热量:%.4lf卡",self.sumDistance,self.sportTime,self.sumHeat];
//    //百度地图截图
//    UIImage *image = [self.mapView takeSnapshot];
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    NSString *url = @"https://upload.api.weibo.com/2/statuses/upload.json";
//    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//    //图片不能放在字典里发送请求
//    parameters[@"access_token"] = [KRUserInfo sharedKRUserInfo].sinaToken;
//    MYLog(@"%@",parameters[@"access_token"]);
//    parameters[@"status"] = statusStr;
//    //parameters[@"visible"] = @1;
//    if ([KRUserInfo sharedKRUserInfo].sinaLoginAndRegister) {
//        [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
//            [formData appendPartWithFileData:UIImagePNGRepresentation(image) name:@"pic" fileName:@"运动记录.png" mimeType:@"image/jpeg"];
//        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
//            MYLog(@"发布微博成功");
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            
//            MYLog(@"发布微博失败:%@",error.userInfo);
//        }];
//    }else{
//        MYLog(@"请使用新浪第三方登陆");
//    }
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url = @"https://upload.api.weibo.com/2/statuses/upload.json";
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    

    parameters[@"access_token"] = [KRUserInfo sharedKRUserInfo].sinaToken;
    
    NSString *statusStr = [NSString stringWithFormat:@"本次运动总距离:%.1lf米,运动时间为:%.1lf秒,消耗热量%.4lf卡",self.sumDistance,
                           self.sportTime,self.sumHeat];
    parameters[@"status"] = statusStr;
    //parameters[@"visible"] = @1;
    MYLog(@"statusStr:%@",statusStr);
    
    if ([KRUserInfo sharedKRUserInfo].sinaLoginAndRegister) {
        [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            UIImage *image = [self.mapView takeSnapshot];
            [formData appendPartWithFileData:UIImagePNGRepresentation(image) name:@"pic" fileName:@"运动记录.png" mimeType:@"image/jpeg"];
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {
            MYLog(@"发布微博成功");
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            MYLog(@"发布微博失败:%@",error.userInfo);
        }];
    }else{
        MYLog(@"请使用新浪第三方方式登录");
    }
    
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

- (IBAction)shareDataToKR:(id)sender {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //    manager.responseSerializer.acceptableContentTypes = [NSSet
    //        setWithObject:@"text/html"];
    //    NSString *url =
    //    @"http://localhost:8080/allRunServer/addTopic.jsp";
    NSString *url = [NSString stringWithFormat:@"http://%@:8080/allRunServer/addTopic.jsp",KRXMPPHOSTNAME];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    KRUserInfo *userInfo = [KRUserInfo sharedKRUserInfo];
    /* content:  address: latitude: longitude:*/
    parameters[@"username"] = userInfo.userName;
    parameters[@"md5password"] = userInfo.userPasswd;
    if (self.sumDistance <= 0.0) {
        return;
    }
    NSString *statusStr = [NSString stringWithFormat:@"本次运动总距离:%.1lf米,运动时间为:%.1lf@秒,消耗热量%.4lf卡",self.sumDistance,self.sportTime,self.sumHeat];
    
    parameters[@"content"] = statusStr;
    parameters[@"address"] = @"北京潘家园";
    CLLocation  *lastLoc = self.locationArrayM.lastObject;
    parameters[@"latitude"] = @(lastLoc.coordinate.latitude);
    parameters[@"longitude"] = @(lastLoc.coordinate.longitude);

    
    [manager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        /* 按照日期生成文件名 */
        NSDate  *date = [NSDate date];
        NSDateFormatter *format = [[NSDateFormatter alloc]init];
        [format setDateFormat:@"yyyy-MM-ddHH:mm:ss"];
        NSString *dateName = [format stringFromDate:date];
        NSString *picName = [dateName stringByAppendingFormat:@"%@.png",[KRUserInfo sharedKRUserInfo].userName];
        /* 得到上传图片 */
        UIImage *image = [self.mapView takeSnapshot];
        //压缩为宽度200，高度等比例
        UIImage *newImage = [self thumbnaiWithImage:image Size:CGSizeMake(200, (200.0/image.size.width)*image.size.height)];
        [formData appendPartWithFileData:UIImagePNGRepresentation(newImage) name:@"pic" fileName:picName mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        MYLog(@"%@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        MYLog(@"%@",error);
    }];

    
}



@end
