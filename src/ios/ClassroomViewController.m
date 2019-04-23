//
//  ClassroomViewController.m
//  TICDemo
//
//  Created by jameskhdeng(邓凯辉) on 2018/5/15.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
// #define kBoardH ceil([[UIScreen mainScreen] bounds].size.width*9/16.0) // 白板高度
#define kBoardW SCREEN_WIDTH * 0.7 - 40.0
#define kBoardH SCREEN_HEIGHT * 0.6 // 白板高度
#define kVideoH kBoardH * 0.5 // 主视频高度
#define kVideoW SCREEN_WIDTH * 0.3 - 40 // 主视频宽度

#define sVideoW SCREEN_WIDTH * 0.2 // 小屏幕视频宽度
#define sVideoH SCREEN_HEIGHT * 0.3 // 小屏幕视频宽度

#import "ClassroomViewController.h"
#import <objc/message.h>

@interface ClassroomViewController () <UITextFieldDelegate> {
    NSString *_classID;
    NSString *_teacherId;
    CDVPlugin *_plugin;
}
@property (nonatomic, strong) TXBoardView *boardView;     //!< 白板
@property (nonatomic, strong) UITextView *chatView;       //!< 聊天视图
@property (nonatomic, strong) ILiveRenderView *mainRenderView;       //!< 教师视频
@property (nonatomic, strong) NSMutableArray *allStudentsRenderViews; //所有学生视频

@end

@implementation ClassroomViewController


- (BOOL)shouldAutorotate
{
    return NO;
}

- (instancetype)initWithClasssID:(NSString *)classId teacherId: (NSString *) teacherId plugin: (CDVPlugin *)plugin
{
    self = [super init];
    if (self) {
        _classID = classId;
        _teacherId = teacherId;
        _allStudentsRenderViews = [[NSMutableArray alloc] init];
        _plugin = plugin;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 强制横屏
//    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIDeviceOrientationLandscapeLeft]
//                                forKey:@"orientation"];
    
//    [[UIDevice currentDevice] setValue:3 forKey:@"orientation"];
    [self changeToOrientation: UIDeviceOrientationLandscapeLeft];
    
    
    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    
    [self.view setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    
    // UI设置
    self.view.backgroundColor = [UIColor colorWithRed:79/255.0 green:191/255.0 blue:255/255.0 alpha:1.0];
    [self.view addSubview:self.boardView];
    [self.view addSubview:self.mainRenderView];
    
    [self.boardView.layer setCornerRadius:20.0f];
    //    [self.view addSubview:self.chatView];
    
    
    // 调用TIC接口，添加白板视图，建立TICManager和白板视图的联系
    [[TICManager sharedInstance] addBoardView:self.boardView andLoadHistoryData:^(int errCode, NSString *errMsg) {
        NSLog(@"加载课堂历史数据完成");
    }];
    
    // 打开摄像头
    [[TICManager sharedInstance] enableCamera:CameraPosFront enable:true succ:^{
        NSLog(@"启动摄像头成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"启动摄像头失败");
    }];
    
    // 添加按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(onQuitRoom) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"退出" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
    button.frame = CGRectMake(10.0, 10.0, 50.0, 30.0);
//    button.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:button];
    [self.view bringSubviewToFront:button];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // 强制竖屏
    [self changeToOrientation: UIDeviceOrientationPortrait];
    
    // 退出课堂
    [[TICManager sharedInstance] quitClassroomSucc:^{
         NSLog(@"退出房间成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"退出房间失败：%d-%@", errId, errMsg);
    }];
}

#pragma mark - Target Action

#pragma mark - UITextFieldDelegate

#pragma mark - Custom Action
// 退出教室
- (void)onQuitRoom {
    // 因为dealloc方法中已经写了退出课堂逻辑，所以这里只需要pop掉控制器，触发dealloc方法即可
//    [self.navigationController popViewControllerAnimated:YES];
    [self removeFromParentViewController];
    [self.view removeFromSuperview];
}

// 房间内上麦用户数量变化时调用，重新布局所有渲染视图，这里简单处理，从左到右等分布局，开发者可以根据自己业务自定义布局
- (void)onCameraNumChange {
    // 获取当前所有渲染视图
//    NSArray *allRenderViews = [[[ILiveRoomManager getInstance] getFrameDispatcher] getAllRenderViews];
    NSArray *allRenderViews = _allStudentsRenderViews;
    
    // 检测异常情况
    if (allRenderViews.count == 0) {
        return;
    }
    
    // 计算并设置每一个渲染视图的frame
    CGFloat renderViewHeight = sVideoH;
    CGFloat renderViewWidth = sVideoW;
    CGFloat renderViewY = kBoardH + 30;
    __block CGFloat renderViewX = 40;
    
    [_allStudentsRenderViews enumerateObjectsUsingBlock:^(ILiveRenderView *renderView, NSUInteger idx, BOOL * _Nonnull stop) {
        renderViewX = renderViewX + (renderViewWidth + 10) * idx;
        CGRect frame = CGRectMake(renderViewX, renderViewY, renderViewWidth, renderViewHeight);
        renderView.frame = frame;
        [renderView.layer setCornerRadius:10.0f];
    }];
}


#pragma mark - TICClassroomIMListener
// 收到文本消息
- (void)onRecvTextMsg:(NSString *)text from:(NSString *)fromId type:(TICMessageType)type {
    // 接收到房间内其他成员发出的文本消息，将消息按"[发送者] 消息内容"格式展示在界面上
    NSString *msgInfo = [NSString stringWithFormat:@"[%@] %@",fromId, text];
    self.chatView.text = [NSString stringWithFormat:@"%@\n%@",self.chatView.text, msgInfo];
    [self.chatView scrollRangeToVisible:NSMakeRange(self.chatView.text.length, 1)];
}

// 收到自定义消息
- (void)onRecvCustomMsg:(NSData *)data from:(NSString *)fromId type:(TICMessageType)type {
    // 接收到房间内其他成员发出的文本消息，将消息按"[发送者] 消息内容"格式展示在界面上
    NSString *msgInfo = [NSString stringWithFormat:@"[%@] %@",fromId, @"CUSTOM"];
    self.chatView.text = [NSString stringWithFormat:@"%@\n%@",self.chatView.text, msgInfo];
    [self.chatView scrollRangeToVisible:NSMakeRange(self.chatView.text.length, 1)];
}

// 收到消息
- (void)onRecvGroupCustomMsg:(NSString *)fromId context:(NSData *)data {
    NSLog(@"");
}


#pragma mark - TICClassroomAVEventListener
/**
 * 音视频事件回调
 */
- (void)onUserUpdateInfo:(QAVUpdateEvent)event users:(NSArray *)users {
    if (users.count <= 0) {
        return;
    }
    for (NSString *identifier in users) {
        if([identifier isEqualToString:_teacherId]) continue;
        
        switch (event) {
            case QAV_EVENT_ID_ENDPOINT_HAS_CAMERA_VIDEO:
            {
                /*
                 创建并添加渲染视图，传入userID和渲染画面类型，这里传入 QAVVIDEO_SRC_TYPE_CAMERA（摄像头画面）,
                 */
                ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
                ILiveRenderView *renderView = [frameDispatcher addRenderAt:CGRectZero forIdentifier:identifier srcType:QAVVIDEO_SRC_TYPE_CAMERA];
                renderView.autoRotate = NO;
//                renderView.userId = identifier;
                if ([identifier isEqualToString:[[ILiveLoginManager getInstance] getLoginId]]) {
                    renderView.rotateAngle = ILIVEROTATION_180;
                }
                
                [self addRenderView:renderView];
            }
            break;
            case QAV_EVENT_ID_ENDPOINT_NO_CAMERA_VIDEO:
            {
                // 移除渲染视图
                ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
                ILiveRenderView *renderView = [frameDispatcher removeRenderViewFor:identifier srcType:QAVVIDEO_SRC_TYPE_CAMERA];
                [self removeRenderView:renderView];
            }
            break;
            case QAV_EVENT_ID_ENDPOINT_HAS_SCREEN_VIDEO:
            {
                ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
                ILiveRenderView *renderView = [frameDispatcher addRenderAt:CGRectZero forIdentifier:identifier srcType:QAVVIDEO_SRC_TYPE_SCREEN];
                renderView.autoRotate = NO;
                [self addRenderView:renderView];
//                [self.view sendSubviewToBack:renderView];
            }
            break;
            case QAV_EVENT_ID_ENDPOINT_NO_SCREEN_VIDEO:
            {
                // 移除渲染视图
                ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
                ILiveRenderView *renderView = [frameDispatcher removeRenderViewFor:identifier srcType:QAVVIDEO_SRC_TYPE_SCREEN];
            }
            break;
            case QAV_EVENT_ID_ENDPOINT_HAS_MEDIA_FILE_VIDEO:
            {
                ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
                ILiveRenderView *renderView = [frameDispatcher addRenderAt:CGRectZero forIdentifier:identifier srcType:QAVVIDEO_SRC_TYPE_MEDIA];
                renderView.autoRotate = NO;
                [self addRenderView:renderView];
//                [self.view sendSubviewToBack:renderView];
            }
            break;
            case QAV_EVENT_ID_ENDPOINT_NO_MEDIA_FILE_VIDEO:
            {
                // 移除渲染视图
                ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
                ILiveRenderView *renderView = [frameDispatcher removeRenderViewFor:identifier srcType:QAVVIDEO_SRC_TYPE_MEDIA];
                [self removeRenderView:renderView];
            }
            break;
            default:
            break;
        }
    }
}

- (void) addRenderView: (ILiveRenderView *)renderView
{
    [_allStudentsRenderViews addObject:renderView];
    [self.view addSubview:renderView];
    [self onCameraNumChange];
}

- (void) removeRenderView: (ILiveRenderView *)renderView
{
    [_allStudentsRenderViews removeObject:renderView];
    [renderView removeFromSuperview];
    // 房间内上麦用户数量变化，重新布局渲染视图
    [self onCameraNumChange];
}

/**
 * 首帧到达回调
 */
- (void)onFirstFrameRecved:(int)width height:(int)height identifier:(NSString *)identifier srcType:(avVideoSrcType)srcType {
    
}

/**
 * SDK主动退出房间提示
 */
- (void)onRoomDisconnect:(int)reason {
    
}

/**
 *  有人加入课堂时的通知回调
 *
 *  @param members 加入成员的identifier（NSString*）列表
 */
-(void)onMemberJoin:(NSArray*)members {
    NSString *msgInfo = [NSString stringWithFormat:@"[%@] %@",members.firstObject, @"加入了房间"];
    self.chatView.text = [NSString stringWithFormat:@"%@\n%@",self.chatView.text, msgInfo];;
}

/**
 *  有人退出课堂时的通知回调
 *
 *  @param members 退出成员的identifier（NSString*）列表
 */
-(void)onMemberQuit:(NSArray*)members {
    NSString *msgInfo = [NSString stringWithFormat:@"[%@] %@",members.firstObject, @"退出了房间"];
    self.chatView.text = [NSString stringWithFormat:@"%@\n%@",self.chatView.text, msgInfo];;
}

/**
 *  课堂被解散通知
 */
-(void)onClassroomDestroy {
    [self onQuitRoom];
}

#pragma mark - Accessor

- (TXBoardView *)boardView {
    if (!_boardView) {
        _boardView = [[TXBoardView alloc] initWithRoomID:_classID];
        _boardView.frame = CGRectMake(40, 14, kBoardW, kBoardH);
        [_boardView setBrushModel:TXBoardBrushModelNone]; // 禁止学生端画画
    }
    return _boardView;
}

- (UITextView *)chatView {
    if (!_chatView) {
        _chatView = [[UITextView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.boardView.frame), SCREEN_WIDTH*0.4, SCREEN_HEIGHT-CGRectGetMaxY(self.boardView.frame)-50)];
        _chatView.backgroundColor = [UIColor lightGrayColor];
        _chatView.editable = NO;
    }
    return _chatView;
}

- (ILiveRenderView *) mainRenderView{
    if (!_mainRenderView) {
        
        ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
        ILiveRenderView *renderView = [frameDispatcher addRenderAt:CGRectZero forIdentifier:_teacherId srcType:QAVVIDEO_SRC_TYPE_CAMERA];
        renderView.autoRotate = NO;
//        [self.view addSubview:renderView];
        
        CGFloat renderViewHeight = kVideoH;
        CGFloat renderViewWidth = kVideoW;
        CGFloat renderViewY = 14;
        __block CGFloat renderViewX = 40 + kBoardW + 20;
        
        CGRect frame = CGRectMake(renderViewX, renderViewY, renderViewWidth, renderViewHeight);
        renderView.frame = frame;
        [renderView.layer setCornerRadius:10.0f];
        [renderView setClipsToBounds:YES];
        
        _mainRenderView = renderView;
    }
    return _mainRenderView;
}


- (void) changeToOrientation: (int) orientation
{
    NSMutableArray* result = [[NSMutableArray alloc] init];
    CDVViewController* vc = (CDVViewController*) _plugin.viewController;
    
    [result addObject:[NSNumber numberWithInt:orientation]];
    
    SEL selector = NSSelectorFromString(@"setSupportedOrientations:");
    ((void (*)(CDVViewController*, SEL, NSMutableArray*))objc_msgSend)(vc,selector,result);
    
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: orientation]
                                     forKey:@"orientation"];
}


@end
