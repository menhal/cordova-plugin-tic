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
#import "TICRenderView.h"
#import <objc/message.h>

@interface ClassroomViewController () <UITextFieldDelegate> {
    NSString *_classID;
    NSString *_userId;
    NSString *_teacherId;
    CDVPlugin *_plugin;
}
@property (weak, nonatomic) IBOutlet UIView *boardViewContainer;

@property (weak, nonatomic) IBOutlet UIView *mainRenderContainer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *borderViewContainerHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mainRenderViewContainerWidth;


@property (weak, nonatomic) IBOutlet UIView *boardView;

@property (weak, nonatomic) IBOutlet TICRenderView *mainRenderView;//!< 教师视频

@property (weak, nonatomic) IBOutlet UIButton *handButton;  // 举手按钮

@property (weak, nonatomic) IBOutlet UIScrollView *liveListContainer;

@property (nonatomic, strong) NSMutableArray *allStudentsRenderViews; //所有学生视频

@end

@implementation ClassroomViewController

//
//- (BOOL)shouldAutorotate
//{
//    return NO;
//}

- (instancetype)initWithClasssID:(NSString *)classId teacherId: (NSString *) teacherId userId:(NSString *) userId plugin: (CDVPlugin *)plugin
{
    self = [super init];
    if (self) {
        _classID = classId;
        _teacherId = teacherId;
        _allStudentsRenderViews = [[NSMutableArray alloc] init];
        _plugin = plugin;
        _userId = userId;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 强制横屏
    [self changeToOrientation: UIDeviceOrientationLandscapeLeft];
    [self.view setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];

    // ipad和手机区别对待
    if(SCREEN_HEIGHT > 400){
        _borderViewContainerHeight.constant = SCREEN_HEIGHT * 2 / 3;
        _mainRenderViewContainerWidth.constant = SCREEN_WIDTH * 1 / 3;
    } else {
        _borderViewContainerHeight.constant = SCREEN_HEIGHT * 6 / 10;
        _mainRenderViewContainerWidth.constant = SCREEN_WIDTH * 1 / 3;
    }
    

    [self.view layoutIfNeeded];

    // UI设置
    [self initMainRenderView];
    [self initBoardView];
    
    // 关闭mic
    [self setMic: NO];
    [self initLocalRenderView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self onCameraNumChange];
    });
}

-(void)dealloc {
    // 强制竖屏
    
}

#pragma mark - Target Action

#pragma mark - UITextFieldDelegate

#pragma mark - Custom Action
// 退出教室
- (void)quitRoom {
    // 因为dealloc方法中已经写了退出课堂逻辑，所以这里只需要pop掉控制器，触发dealloc方法即可
//    [self.navigationController popViewControllerAnimated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[TICManager sharedInstance] removeEventListener:self];
    [[TICManager sharedInstance] removeMessageListener:self];
    
    [[TICManager sharedInstance] quitClassroom:^(TICModule module, int code, NSString *desc) {
        if(code == 0){
            //退出课堂成功
        }
        else{
            //退出课堂失败
        }
    }];
    
    [self changeToOrientation: UIDeviceOrientationPortrait];
    [self removeFromParentViewController];
    [self.view removeFromSuperview];
}

- (IBAction)onQuitRoom:(id)sender {
    [self quitRoom];
}

// 左滑按钮
- (IBAction)onLeftButtonClick:(id)sender {
    [self scrollTo: 1];
}

// 右滑按钮
- (IBAction)onRightButtonClick:(id)sender {
    [self scrollTo: -1];
}

// 滑动到
- (void) scrollTo: (int) direction{
    CGFloat scrollWidth = [self getLiveViewWidth] + 10;
    
    float scrollViewWidth = _liveListContainer.frame.size.width;
    float scrollContentWidth = _liveListContainer.contentSize.width;
    float scrollOffset = _liveListContainer.contentOffset.x;
    
    if(_liveListContainer.contentOffset.x == 0 && direction == -1) return;
    if(scrollOffset + scrollViewWidth >= scrollContentWidth && direction == 1) return;
    
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint offset = _liveListContainer.contentOffset;
        offset.x += direction * scrollWidth;
        _liveListContainer.contentOffset = offset;
    }];
}

// 设置mic
- (void) setMic: (BOOL) isEnable{

    // 关闭mic
    if(isEnable){
        [[TRTCCloud sharedInstance] startLocalAudio];
    } else {
        [[TRTCCloud sharedInstance] stopLocalAudio];
    }
}

// 房间内上麦用户数量变化时调用，重新布局所有渲染视图，这里简单处理，从左到右等分布局，开发者可以根据自己业务自定义布局
- (void)onCameraNumChange {
    // 获取当前所有渲染视图
    NSArray *allRenderViews = _allStudentsRenderViews;
    
    // 检测异常情况
    if (allRenderViews.count == 0) {
        return;
    }
    
    // 计算并设置每一个渲染视图的frame
    CGFloat renderViewHeight = _liveListContainer.bounds.size.height;
    CGFloat renderViewWidth = renderViewHeight;
    __block CGFloat renderViewX = 0;
    
    [_allStudentsRenderViews enumerateObjectsUsingBlock:^(TICRenderView *renderView, NSUInteger idx, BOOL * _Nonnull stop) {
        renderViewX = renderViewX + (renderViewWidth + 10) * idx;
        renderView.frame = CGRectMake(0, 0, renderViewHeight, renderViewWidth);
//        renderView.superview.backgroundColor = UIColor.blackColor;
        renderView.superview.frame = CGRectMake(renderViewX, 0, renderViewHeight , renderViewWidth);
        
        NSLog(@"renderViewHeight: %f, renderViewWidth:%f", renderViewHeight, renderViewWidth);
    }];
    
    CGFloat contentWidth = allRenderViews.count * (renderViewWidth + 10);
    _liveListContainer.contentSize = CGSizeMake(contentWidth, 0);
}


- (CGFloat) getLiveViewWidth {
    CGFloat renderViewHeight = _liveListContainer.bounds.size.height;
    return renderViewHeight ;
}


#pragma mark - TICClassroomIMListener

// 收到文本消息
- (void)onTICRecvTextMessage:(NSString *)text fromUserId:(NSString *)fromUserId
{
    if([fromUserId isEqualToString:_teacherId]){
        [self onTeacherC2CMessage:text];
    }
}

// 收到自定义消息
- (void)onTICRecvCustomMessage:(NSData *)data fromUserId:(NSString *)fromUserId
{
}

- (void)onTICRecvMessage:(TIMMessage *)message
{
}


// 接收到老师的消息
-(void) onTeacherC2CMessage: (NSString *) message{
    if([message isEqualToString:@"TIMCustomHandReplyYes"]){
        [self setMic:true];
        [self sendC2CMessageToTeacher:@"TIMCustomHandRecOpenOk"];
        [_handButton setTitle:@"正在发言" forState:UIControlStateNormal];
    } else if([message isEqualToString:@"TIMCustomHandReplyNo"]){
        [self setMic:false];
        [self sendC2CMessageToTeacher:@"TIMCustomHandRecCloseOk"];
        [_handButton setTitle:@"我要发言" forState:UIControlStateNormal];
    }
}

// 发送消息给老师
-(void) sendC2CMessageToTeacher: (NSString *) message{
    
    [[TICManager sharedInstance] sendTextMessage:message toUserId:_teacherId callback:^(TICModule module, int code, NSString *desc){
        
        if(code == 0){
            NSLog(@"消息发送成功");
        } else {
            NSLog(@"消息发送失败: %@", desc);
        }
        
    }];
}


#pragma mark - event listener
- (void)onTICUserVideoAvailable:(NSString *)userId available:(BOOL)available
{
    if([userId isEqualToString:_teacherId]) return;
    if([userId isEqualToString:_userId]) return;
    
    if(available){
        TICRenderView *render = [[TICRenderView alloc] init];
        render.userId = userId;
        render.streamType = TICStreamType_Main;
        [self.view addSubview:render];
       
        [[TRTCCloud sharedInstance] startRemoteView:userId view:render];
        [self addRenderView:render];
    }
    else{
        TICRenderView *render = [self getRenderView:userId streamType:TICStreamType_Main];
        [[TRTCCloud sharedInstance] stopRemoteView:userId];
        [self removeRenderView:render];
    }
}

    
- (void)onTICUserSubStreamAvailable:(NSString *)userId available:(BOOL)available
{
    
}

- (TICRenderView *)getRenderView:(NSString *)userId streamType:(TICStreamType)streamType
{
    for (TICRenderView *render in self.allStudentsRenderViews) {
        if([render.userId isEqualToString:userId] && render.streamType == streamType){
            return render;
        }
    }
    return nil;
}

-(void)onTICMemberJoin:(NSArray*)members {
    
    for(NSString *userId in members){
        if([userId isEqualToString:_teacherId]) continue;
        if([userId isEqualToString:_userId]) continue;
        
        TICRenderView *render = [[TICRenderView alloc] init];
        render.userId = userId;
        render.streamType = TICStreamType_Main;
        [[TRTCCloud sharedInstance] startRemoteView:userId view:render];
        
        [self addRenderView:render];
    }
}

-(void)onTICMemberQuit:(NSArray*)members {
    for(NSString *userId in members){
        if([userId isEqualToString:_teacherId]) continue;
        if([userId isEqualToString:_userId]) continue;
        
        TICRenderView *render = [self getRenderView:userId streamType:TICStreamType_Main];
        
        if(render != nil){
            [self removeRenderView:render];
        }
    }
}

/**
 * 音视频事件回调
 */

- (void) addRenderView: (TICRenderView *)renderView
{
    UIView *wrapper = [[UIView alloc] init];
    wrapper.layer.cornerRadius = 10;
    wrapper.clipsToBounds = YES;
    
    [wrapper addSubview:renderView];
    
    [_allStudentsRenderViews addObject:renderView];
    [_liveListContainer addSubview:wrapper];
    [self onCameraNumChange];
}

- (void) removeRenderView: (TICRenderView *)renderView
{
    [_allStudentsRenderViews removeObject:renderView];
    [renderView removeFromSuperview];
    // 房间内上麦用户数量变化，重新布局渲染视图
    [self onCameraNumChange];
}

/**
 * 首帧到达回调
 */
//- (void)onFirstFrameRecved:(int)width height:(int)height identifier:(NSString *)identifier srcType:(avVideoSrcType)srcType {
//
//}

// 点击举手按钮
- (IBAction)onHandButtonClick:(id)sender {
    NSLog(@"_mainRenderView width: %f", _mainRenderView.frame.size.width);
    NSLog(@"_mainRenderView height: %f", _mainRenderView.frame.size.height);
    NSLog(@"Screen Width: %f", SCREEN_WIDTH);

    
    if(![_handButton.titleLabel.text isEqualToString: @"我要发言"]) return;
    
    [_handButton setTitle:@"等待老师同意..." forState:UIControlStateNormal];
    
    [self sendC2CMessageToTeacher:@"TIMCustomHand"];
}

/**
 *  课堂被解散通知
 */
-(void) onTICClassroomDestroy {
    [self quitRoom];
}

#pragma mark - Accessor

- (void)initBoardView {
    
    [[[TICManager sharedInstance] getBoardController] addDelegate: self];
    UIView *boardView = [[[TICManager sharedInstance] getBoardController] getBoardRenderView];
    boardView.frame = _boardViewContainer.bounds;
    
    [_boardViewContainer addSubview:boardView];
    [[[TICManager sharedInstance] getBoardController] setDrawEnable:NO];
}

- (void) initMainRenderView{
    _mainRenderView.userId = _teacherId;
    _mainRenderView.streamType = TICStreamType_Main;
    [[TRTCCloud sharedInstance] startRemoteView:_teacherId view:_mainRenderView];
}
    
- (void) initLocalRenderView{
    TICRenderView *render = [[TICRenderView alloc] init];
    render.userId = _userId;
    render.streamType = TICStreamType_Main;
    [self.view addSubview:render];
    
    [[TRTCCloud sharedInstance] startLocalPreview:YES view:render];
    
    [self addRenderView:render];
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
