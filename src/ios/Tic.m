#import "Tic.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <TICSDK/TICSDK.h>
#import <YYImage/YYImage.h>
#import "ClassroomViewController.h"
#import "ClassroomViewController.h"
#import "TicChatItemView.h"

@implementation Tic

- (void) init:(CDVInvokedUrlCommand*)command
{
    NSString *sdkappid = [command.arguments objectAtIndex:0];
    int result = [[TICManager sharedInstance] initSDK: sdkappid];
    NSLog(@"初始化插件%d", result);
}

- (void) join:(CDVInvokedUrlCommand*)command
{
    callbackId = command.callbackId;
    
    NSDictionary *args = [command.arguments objectAtIndex:0];
    
    NSString *roomId = [args valueForKey:@"roomId"];
    NSString *userName = [args valueForKey:@"userName"];
    NSString *userSig = [args valueForKey:@"userSig"];
    
    [[TICManager sharedInstance] loginWithUid:userName userSig:userSig succ:^{
        NSLog(@"登录成功！");
        [self joinRoom: roomId args: args];
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        [self showErrorMessage: errId errMsg: errMsg];
    }];
    
}


- (void) joinRoom: (NSString *)inputRoomID args:(NSDictionary*)args
{
    if (inputRoomID.length <= 0) {
        return;
    }
    
    NSString *teacherId = [args valueForKey:@"teacherId"];
    NSString *role = [args valueForKey:@"role"];
    NSString *userName = [args valueForKey:@"userName"];
    NSString *truename = [args valueForKey:@"truename"];
    NSString *roomName = [args valueForKey:@"roomName"];
    NSArray *userScores = [args valueForKey:@"userScores"];
    
    ClassroomViewController *classroomVC = [[ClassroomViewController alloc] initWithClasssID:inputRoomID userId:userName truename:truename teacherId: teacherId userScores: userScores roomName:roomName plugin: self];
  
    
    [[TICManager sharedInstance] joinClassroomWithOption:^TICClassroomOption *(TICClassroomOption *option) {
        option.roomID = [inputRoomID intValue];
        option.role = kClassroomRoleStudent;
        option.eventListener = classroomVC;
        option.imListener = classroomVC;
        option.controlRole = role;
        return option;
    } succ:^{

        UIViewController *rootViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
        
        UIView *rootView = rootViewController.view ;
        
        
        
        
        
        [rootViewController addChildViewController:classroomVC];
        [rootView addSubview:classroomVC.view];
        
//        [rootViewController presentViewController:classroomVC animated:YES completion:nil];
        
        
        [self showSuccessMessage];
        NSLog(@"进入房间成功");
        
    } failed:^(NSString *module, int errId, NSString *errMsg) {
//         NSLog(@"进入房间失败：%d %@", errId, errMsg);
        [self showErrorMessage: errId errMsg: errMsg];
    }];
}


- (void) quit:(CDVInvokedUrlCommand*)command
{
    // 退出课堂
    [[TICManager sharedInstance] quitClassroomSucc:^{
        NSLog(@"退房成功");
    } failed:^(NSString *module, int errId, NSString *errMsg) {
//        NSLog(@"退出房间失败：%d-%@", errId, errMsg);
        [self showErrorMessage: errId errMsg: errMsg];
    }];
}


- (void) showSuccessMessage
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
}

- (void) showErrorMessage: (int)errId errMsg: (NSString *)errMsg
{
    NSDictionary *message = @{@"errId" : @(errId), @"errMsg" : errMsg};
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary: message];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
}


- (void) pluginInitialize{
    NSLog(@"初始化插件");
//    [[TICManager sharedInstance] initSDK: @"1400204887"];
}

- (void) onReset{
    NSLog(@"onReset");
}

- (void) dealloc {
    
}




@end
