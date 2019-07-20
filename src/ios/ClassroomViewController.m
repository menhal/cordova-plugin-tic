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
#define isIpad SCREEN_WIDTH > 1000 // 屏幕大于1000的是ipad
#define MainBottomSpace isIpad ? 125 : 65
#define LiveBottomHeight isIpad ? 120 : 60

#import "ClassroomViewController.h"
#import <objc/message.h>
#import <YYImage/YYImage.h>
#import "CustomILiveView.h"
#import "TicChatItemView.h"


@interface ClassroomViewController () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, TIMUserStatusListener> {
    NSString *_classID;
    NSString *_teacherId;
    NSString *_userId;
    NSString *_truename;
    NSString *_roomName;
    CDVPlugin *_plugin;
}

@property Boolean isShowStudents;
@property Boolean isExchange;

@property (weak, nonatomic) IBOutlet UIView *LeftContainer;

@property (weak, nonatomic) IBOutlet UIView *LayoutLeftBottom;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LayoutLeftTopBottomSpace;

@property (weak, nonatomic) IBOutlet UIView *AvSelfContainer;

@property (weak, nonatomic) IBOutlet UIView *ChatContainer;

@property (weak, nonatomic) IBOutlet UIView *LeftTopViewContainer;

@property (weak, nonatomic) IBOutlet UIView *RightTopViewContainer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *KeyboardContainerHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *MainContainerTop;

@property (weak, nonatomic) IBOutlet TXBoardView *boardView;

@property (weak, nonatomic) IBOutlet UIView *MainRenderViewContaienr;

@property (weak, nonatomic) IBOutlet UIButton *handButton;  // 举手按钮

@property (weak, nonatomic) IBOutlet UIButton *toggleButton;

@property (weak, nonatomic) IBOutlet UIButton *collapseButton;

@property (weak, nonatomic) IBOutlet UITableView *ChatList;

@property (weak, nonatomic) IBOutlet UITextField *ChatInput;

@property (weak, nonatomic) IBOutlet UIScrollView *liveListContainer;

@property (nonatomic, strong) NSMutableArray *allStudentsRenderViews; //所有学生视频

@property (nonatomic, strong) NSMutableDictionary *studentScore; //所有学生星星

@property (nonatomic, strong) NSMutableArray *chatContentList; //所有学生视频

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LiveListHeight;

@property (weak, nonatomic) IBOutlet YYAnimatedImageView *GifPlayer;

@property (weak, nonatomic) IBOutlet UILabel *RoomTitle;

@end

@implementation ClassroomViewController

- (instancetype)initWithClasssID:(NSString *)classId userId: (NSString *) userId truename: (NSString *)truename teacherId: (NSString *) teacherId userScores: (NSArray *) userScore roomName:(NSString *)roomName plugin: (CDVPlugin *)plugin
{
    self = [super init];
//    self.isShowStudents = isIpad ? YES : NO;
    self.isShowStudents = YES;
    self.isExchange = NO;
    
    if (self) {
        
        //        [[ILiveLoginManager getInstance] getLoginId];  // 获取当前用户id
        
        _classID = classId;
        _teacherId = teacherId;
        _userId = userId;
        _truename = truename;
        _roomName = roomName;
        _allStudentsRenderViews = [[NSMutableArray alloc] init];
        _chatContentList = [[NSMutableArray alloc] init];
        _studentScore = [[NSMutableDictionary alloc] init];
        _plugin = plugin;
        
        // 初始化学生分数
        for(int i=0; i<[userScore count]; i++){
            NSDictionary *data = userScore[i];
            NSString *userId = [data objectForKey:@"userId"];
            NSNumber *integral = [data objectForKey:@"integral"];
            
            [_studentScore setValue:integral forKey:userId];
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 强制横屏
    [self changeToOrientation: UIDeviceOrientationLandscapeLeft];
    [self.view setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    [_RoomTitle setText:_roomName];
//
    [[TICManager sharedInstance] setUserStatusListener:self];
    // ipad 下方学生视频要大些
    _LiveListHeight.constant = LiveBottomHeight;
    _LayoutLeftTopBottomSpace.constant = MainBottomSpace;
    [self.view layoutIfNeeded];

    // UI设置
    
    [self initCollapseState];
    [self initChatView];
    
    [self printSize];
    
    [self.view layoutIfNeeded];
    [self initBoardAndMainRenderViews];
    // 打开摄像头
    [[TICManager sharedInstance] enableCamera:CameraPosFront enable:true succ:^{
        NSLog(@"启动摄像头成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"启动摄像头失败");
    }];

    // 关闭mic
    [self setMic:false];
    [self printSize];
}

- (void) printSize{
    
    NSLog(@"printSize:%f", _MainRenderViewContaienr.frame.size.height);
}

-(void)dealloc {
    
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
- (void)quitRoom {
    // 因为dealloc方法中已经写了退出课堂逻辑，所以这里只需要pop掉控制器，触发dealloc方法即可
//    [self.navigationController popViewControllerAnimated:YES];
    [self removeFromParentViewController];
    [self.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[TICManager sharedInstance] setUserStatusListener:nil];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//
//    // 强制竖屏
//    [self changeToOrientation: UIDeviceOrientationPortrait];
//
//    // 退出课堂
//    [[TICManager sharedInstance] quitClassroomSucc:^{
//        NSLog(@"退出房间成功");
//    } failed:^(NSString *module, int errId, NSString *errMsg) {
//        NSLog(@"退出房间失败：%d-%@", errId, errMsg);
//    }];
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
    [[TICManager sharedInstance] enableMic:isEnable succ:^{
        NSLog(@"设置mic成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"设置mic失败");
    }];
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
    CGFloat renderViewHeight = LiveBottomHeight;
    CGFloat renderViewWidth = [self getLiveViewWidth];
    __block CGFloat renderViewX = 0;
    
    [_allStudentsRenderViews enumerateObjectsUsingBlock:^(CustomILiveView *renderView, NSUInteger idx, BOOL * _Nonnull stop) {
        if(idx != 0) renderViewX = renderViewX + (renderViewWidth + 10);
        CGRect frame = CGRectMake(renderViewX, 0, renderViewWidth, renderViewHeight);
        renderView.frame = frame;
        [renderView clipsToBounds];
    }];
    
    CGFloat contentWidth = allRenderViews.count * (renderViewWidth + 10);
    _liveListContainer.contentSize = CGSizeMake(contentWidth, 0);
}


- (CGFloat) getLiveViewWidth {
    CGFloat renderViewHeight = LiveBottomHeight;
    return renderViewHeight ;
}


#pragma mark - TICClassroomIMListener

// 收到文本消息
- (void)onRecvTextMsg:(NSString *)text from:(NSString *)fromId type:(TICMessageType)type {
    // 接收到房间内其他成员发出的文本消息，将消息按"[发送者] 消息内容"格式展示在界面上
    
    if([fromId isEqualToString:_teacherId]){
        [self onTeacherC2CMessage:text];
    } else {
        NSDictionary *data = [self getMessageFromJson:text];
        if(data != nil) [self showChatMessage:data from: fromId];
    }
}


// 收到自定义消息
- (void)onRecvCustomMsg:(NSData *)data from:(NSString *)fromId type:(TICMessageType)type {
    // 接收到房间内其他成员发出的文本消息，将消息按"[发送者] 消息内容"格式展示在界面上
    NSLog(@"%@", data);
}

// 收到消息
- (void)onRecvGroupCustomMsg:(NSString *)fromId context:(NSData *)data {
    NSLog(@"");
}


// 接收到老师的消息
-(void) onTeacherC2CMessage: (NSString *) message{
    if([message isEqualToString:@"TIMCustomHandReplyYes"]){
        [self setMic:true];
        [self sendC2CMessageToTeacher:@"TIMCustomHandRecOpenOk"];
        [_handButton setTitle:@"正在发言" forState:UIControlStateNormal];
        [self addChatMessage:@"已经同意您的发言请求" from:@"系统"];
    } else if([message isEqualToString:@"TIMCustomHandReplyNo"]){
        [self setMic:false];
        [self sendC2CMessageToTeacher:@"TIMCustomHandRecCloseOk"];
        [_handButton setTitle:@"我要发言" forState:UIControlStateNormal];
        [self addChatMessage:@"发言已结束" from:@"系统"];
    } else {
        
        NSDictionary *data = [self getMessageFromJson:message];
        if(data != nil) [self showChatMessage:data from: _teacherId];
    }
}

- (void) showChatMessage: (NSDictionary *) data from: (NSString *) from
{
    NSString *type = [data objectForKey:@"type"];
    NSString *uid = [data objectForKey:@"uid"];
    NSString *truename = [data objectForKey:@"truename"];
    NSString *text = [data objectForKey:@"msg"];
    NSString *integral = [data objectForKey:@"integral"];
    NSString *addIntegral = [data objectForKey:@"addIntegral"];
    
    if([type isEqualToString:@"chat"]){
        [self addChatMessage:text from:truename];
    } else {
        [self addChatMessage:text from: @"系统"];
        [self addScoreForUser:uid integral: integral];
    }
}

- (void) addScoreForUser: (NSString *) userId integral: (NSString *) integral
{
    [_allStudentsRenderViews enumerateObjectsUsingBlock:^(CustomILiveView *renderView, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if([renderView.userId isEqualToString:userId])
        {
            [_studentScore setValue:integral forKey:userId];
            [renderView setScoreWith: [integral intValue]];
        }
    }];
    
    if([userId isEqualToString:_userId]) [self showAnimate];
}

- (void) showAnimate
{
    UIImage *image = [YYImage imageNamed:@"Fireworks.gif"];
    [_GifPlayer setImage:image];
    [_GifPlayer setHidden:NO];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideAnimate];
    });
}

- (void) hideAnimate
{
    [_GifPlayer setHidden:YES];
}

// 发送消息给老师
-(void) sendC2CMessageToTeacher: (NSString *) message{
   
    [[TICManager sharedInstance] sendTextMessage:message toUser:_teacherId succ:^{
        NSLog(@"消息发送成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"消息发送失败: %@", errMsg);
    }];
}

// 广播消息
- (void) sendMessageToAll: (NSString *) message{
    
    NSDictionary *data = @{@"type": @"chat" ,@"msg":message,@"uid":_userId , @"truename": _truename,@"integral":@"",@"addIntegral":@""};
    
    NSString *json = [self getJsonFromMessage:data];
    
    [[TICManager sharedInstance] sendTextMessage: json toUser:nil succ:^{
        [self addChatMessage:message from: _truename];
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"消息发送失败: %@", errMsg);
    }];
}

- (NSDictionary *) getMessageFromJson: (NSString *) jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSString *replacedStr = [jsonString stringByReplacingOccurrencesOfString:@"&quot;"withString:@"\""];
    
    NSData *jsonData = [replacedStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    
    return dic;
}

- (NSString *) getJsonFromMessage: (NSDictionary *)dic
{
    NSData *data =    [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *json = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
    return json;
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
                [self addRenderView: identifier];
            }
            break;
                
            case QAV_EVENT_ID_ENDPOINT_NO_CAMERA_VIDEO:
            {
                [self removeRenderView: identifier];
            }
            break;
                
            case QAV_EVENT_ID_ENDPOINT_HAS_SCREEN_VIDEO:
            {
                [self addRenderView: identifier];
            }
            break;
                
            case QAV_EVENT_ID_ENDPOINT_NO_SCREEN_VIDEO:
            {
                
            }
            break;
                
            case QAV_EVENT_ID_ENDPOINT_HAS_MEDIA_FILE_VIDEO:
            {
                [self addRenderView: identifier];
            }
            break;
                
            case QAV_EVENT_ID_ENDPOINT_NO_MEDIA_FILE_VIDEO:
            {
                [self removeRenderView: identifier];
            }
            break;
                
            default:
            break;
        }
    }
}

- (void) addRenderView: (NSString *)userId
{
    CustomILiveView *renderView = [[CustomILiveView alloc] initWithFrame: CGRectMake(0, 0, 100, 100) and: userId];
    
    if([userId isEqualToString:_userId]){
        [_allStudentsRenderViews insertObject:renderView atIndex:0];
    } else {
        [_allStudentsRenderViews addObject:renderView];
    }
    
    [_liveListContainer addSubview:renderView];
    [renderView start];
    
    NSNumber *score = [_studentScore objectForKey:userId];
    [renderView setScoreWith:[score integerValue]];
    
    [self onCameraNumChange];
}

- (void) removeRenderView: (NSString *) userId
{
    for(int i=0; i<_allStudentsRenderViews.count; i++){
        CustomILiveView *renderView = (CustomILiveView *) _allStudentsRenderViews[i];
        if([userId isEqualToString:renderView.userId]){
            [renderView removeFromSuperview];
            [_allStudentsRenderViews removeObject: renderView];
        }
    }
    // 房间内上麦用户数量变化，重新布局渲染视图
    [self onCameraNumChange];
}

- (void) addAllStudentsRenderViews{
    for(int i = 0; i< _allStudentsRenderViews.count; i++){
        CustomILiveView *renderView = (CustomILiveView *) _allStudentsRenderViews[i];
        [renderView start];
    }
    [self onCameraNumChange];
}

- (void) removeAllStudentsRenderViews{
    for(int i = 0; i< _allStudentsRenderViews.count; i++){
        CustomILiveView *renderView = (CustomILiveView *) _allStudentsRenderViews[i];
        [renderView stop];
    }
}

- (void) addSelfRenderView
{
    CustomILiveView *renderView = [[CustomILiveView alloc] initWithFrame:CGRectMake(0, 0, _AvSelfContainer.frame.size.width, _AvSelfContainer.frame.size.height) and:_userId];
    
    [_AvSelfContainer addSubview:renderView];
    [renderView start];
    
    NSNumber *score = [_studentScore objectForKey:_userId];
    [renderView setScoreWith:score == nil ? 0 : [score integerValue]];
}

- (void) removeSelfRenderView
{
    [[_AvSelfContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void) addChatMessage: (NSString *) message from: (NSString *) userId
{
    NSDictionary *data = @{@"userId": userId, @"content": message};
    [_chatContentList addObject:data];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: _chatContentList.count-1 inSection:0];
    [_ChatList insertRowsAtIndexPaths:@[indexPath]  withRowAnimation:UITableViewRowAnimationTop];
    // 滚动到最后一行
    [_ChatList scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
    // NSString *msgInfo = [NSString stringWithFormat:@"[%@] %@",members.firstObject, @"加入了房间"];
    // [self addChatMessage:msgInfo from:@"系统"];
}

/**
 *  有人退出课堂时的通知回调
 *
 *  @param members 退出成员的identifier（NSString*）列表
 */
-(void)onMemberQuit:(NSArray*)members {
    // NSString *msgInfo = [NSString stringWithFormat:@"[%@] %@",members.firstObject, @"退出了房间"];
    // [self addChatMessage:msgInfo from:@"系统"];
}

// 点击举手按钮
- (IBAction)onHandButtonClick:(id)sender {
    
//    TXBoardView *boardView = (TXBoardView *)_LeftTopViewContainer.subviews[0];
//
//    [[TICManager sharedInstance] addBoardView: boardView andLoadHistoryData:^(int errCode, NSString *errMsg) {
//        if(errCode == 0)
//        NSLog(@"加载课堂历史数据完成");
//        else {
//            [self addChatMessage:@"加载课堂历史数据失败" from:@"系统"];
//            NSLog(@"加载课堂历史数据失败！！！！");
//        }
//    }];
  
    if(![_handButton.titleLabel.text isEqualToString: @"我要发言"]) return;
    
    [_handButton setTitle:@"等待同意" forState:UIControlStateNormal];
    
    [self sendC2CMessageToTeacher:@"TIMCustomHand"];
}

// 点击折叠按钮
- (IBAction)onCollapseButtonClick:(id)sender {
    self.isShowStudents = !self.isShowStudents;
    [self initCollapseState];
}


- (void) initCollapseState{
    
    if(self.isShowStudents){
        self.LayoutLeftBottom.hidden = NO;
        self.LayoutLeftTopBottomSpace.constant = MainBottomSpace;
        self.AvSelfContainer.hidden = YES;
        self.ChatContainer.hidden = NO;
        [self addAllStudentsRenderViews];
        [self removeSelfRenderView];
        
    } else {
        self.LayoutLeftBottom.hidden = YES;
        self.LayoutLeftTopBottomSpace.constant = 0;
        self.AvSelfContainer.hidden = NO;
        self.ChatContainer.hidden = YES;
        [self removeAllStudentsRenderViews];
        [self addSelfRenderView];
    }
    
    NSString *text = self.isShowStudents ? @"收起" : @"展开";
    [_collapseButton setTitle: text forState: UIControlStateNormal];
    [self.view layoutIfNeeded];
    
    [self addEqualSizeConstraint: _MainRenderViewContaienr ratio: self.isExchange ? 0.65 : 0.75];
    [self addEqualSizeConstraint: _LeftTopViewContainer ratio: self.isExchange ? 0.75 : 0.65];
}

- (void) initBoardAndMainRenderViews{
    
    [[_LeftTopViewContainer subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [[_MainRenderViewContaienr subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        
        TXBoardView *boardView = [[TXBoardView alloc] initWithRoomID:_classID];
        
        
        [boardView getBoardData:^{
            NSLog(@"");
        } failed:^(int errCode, NSString *errMsg) {
            NSLog(@"111%@", errMsg);
        }];
        
        [self initBoardView: boardView];
        
        ILiveRenderView *renderView = [[ILiveRenderView alloc] init];
        [self initMainRenderView: renderView];
        
        boardView.translatesAutoresizingMaskIntoConstraints = false;
        renderView.translatesAutoresizingMaskIntoConstraints = false;
        
        if(self.isExchange){
            
            [_LeftTopViewContainer insertSubview:renderView atIndex:0];
            [_MainRenderViewContaienr insertSubview:boardView atIndex:0];
            
            [self addEqualSizeConstraint: _MainRenderViewContaienr ratio:0.65];
            [self addEqualSizeConstraint: _LeftTopViewContainer ratio:0.75];
            
        } else {
            
            [_LeftTopViewContainer insertSubview:boardView atIndex:0];
            [_MainRenderViewContaienr insertSubview:renderView atIndex:0];
            
            [self addEqualSizeConstraint: _MainRenderViewContaienr ratio:0.75];
            [self addEqualSizeConstraint: _LeftTopViewContainer ratio:0.56];
        }
        
    });
    
    
    
    
    
//    _toggleButton.layer.zPosition = 999;
}

- (IBAction)onToggleButtonClick:(id)sender {
    
    self.isExchange = !self.isExchange;
    [self initBoardAndMainRenderViews];
    [self printSize];
}

- (void) addCenterConstraint: (UIView *) from to: (UIView *)to{
    
//    [to addConstraint: [NSLayoutConstraint constraintWithItem:to attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:from attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
//
//    [to addConstraint: [NSLayoutConstraint constraintWithItem:to attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:from attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
}

- (void) addEqualSizeConstraint: (UIView *)to ratio: (CGFloat) ratio{
    
//    [to addConstraint: [NSLayoutConstraint constraintWithItem:to attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:from attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
//
//    [to addConstraint: [NSLayoutConstraint constraintWithItem:to attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:from attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        
        if([to.subviews count] == 0) return;
        UIView *from = to.subviews[0];
        
        CGSize containerSize = to.frame.size;
        
        //过扁
        if((containerSize.height / containerSize.width) > ratio) {
            CGFloat height = containerSize.width * ratio;
            CGFloat top = (containerSize.height - height) / 2;
            from.frame = CGRectMake(0, top, containerSize.width, height);
        } else {
            CGFloat width = containerSize.height / ratio;
            CGFloat left = (containerSize.width - width) / 2;
            from.frame = CGRectMake(left, 0, width, containerSize.height);
        }
        
        
        [from clipsToBounds];
        
    });
    
    
}

- (void) addAspectConstraint: (UIView *) from to: (UIView *)to{
    
}

/**
 *  课堂被解散通知
 */
-(void)onClassroomDestroy {
    [self quitRoom];
}


#pragma mark - TIMUserStatusListener
- (void)onForceOffline {
    [self quitRoom];
}


#pragma mark - Accessor

- (void)initBoardView: (TXBoardView *) boardView {
    
    [boardView setBrushModel:TXBoardBrushModelNone]; // 禁止学生端画画
    
    [TXBoardSDK enableConsoleLog:YES];

    // 调用TIC接口，添加白板视图，建立TICManager和白板视图的联系
    [[TICManager sharedInstance] addBoardView: boardView andLoadHistoryData:^(int errCode, NSString *errMsg) {
        if(errCode == 0)
        NSLog(@"加载课堂历史数据完成");
        else {
            [self addChatMessage:@"加载课堂历史数据失败" from:@"系统"];
            NSLog(@"加载课堂历史数据失败！！！！");
        }
    }];
    
    [NSThread sleepForTimeInterval:0.1];
    
}

- (void) initMainRenderView: (ILiveRenderView *) renderView{
//    [renderView init];
    [renderView setIdentifier:_teacherId];
    [renderView setSrcType:QAVVIDEO_SRC_TYPE_CAMERA];
    renderView.autoRotate = NO;
    
    ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
    [frameDispatcher addRenderView:renderView];
}

- (void) initChatView {
    _ChatList.dataSource = self;
    _ChatList.delegate = self;
}

- (NSInteger) tableView: (UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int count = [_chatContentList count];
    return count;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    
    NSString * cellID = [NSString stringWithFormat:@"cellID%ld", indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    NSInteger row = indexPath.row;
    
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        
        CGSize listItemSize = tableView.frame.size;
        
        TicChatItemView *chatItem = [[TicChatItemView alloc] initWithFrame: CGRectMake(0, 0, listItemSize.width, 50)];
        [cell.contentView addSubview:chatItem];
        chatItem.tag = 998;
        
        NSDictionary *data = [_chatContentList objectAtIndex:indexPath.row];
        NSString *userId = [data objectForKey:@"userId"];
        NSString *content = [data objectForKey:@"content"];
        
        [chatItem setMessage:content from:userId];
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *data = [_chatContentList objectAtIndex:indexPath.row];
    NSString *userId = [data objectForKey:@"userId"];
    NSString *content = [data objectForKey:@"content"];
    
    CGSize listItemSize = tableView.frame.size;
    CGSize contentSize = [TicChatItemView getRect:listItemSize.width userId:userId msg:content];
    
    return contentSize.height + 10;
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


//键盘将要弹出
- (void)keyboardWillShow:(NSNotification *)notification
{
    //获取键盘高度 keyboardHeight
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    CGFloat keyboardHeight = keyboardRect.size.height;
    
    _KeyboardContainerHeight.constant = keyboardHeight;
    _MainContainerTop.constant = 54 - keyboardHeight;
    
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //结束编辑
    [self.view endEditing:YES];
}

- (IBAction)onPrimaryAction:(id)sender {
    NSLog(@"onPrimaryAction");
    NSString *text = [_ChatInput text];
    _ChatInput.text = @"";
    [self sendMessageToAll:text];
}

- (IBAction)onDidEnd:(id)sender {
    NSLog(@"onDidEnd");
}


//键盘将要隐藏
- (void)keyboardWillHide:(NSNotification *)notification{
    
//    self.baseView.center = self.view.center;
    
    NSDictionary *userInfo = [notification userInfo];
    
    _KeyboardContainerHeight.constant = 0;
    _MainContainerTop.constant = 54;
    
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

@end
