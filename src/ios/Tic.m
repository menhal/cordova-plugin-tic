#import "Tic.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <TICSDK/TICSDK.h>
#import "ClassroomViewController.h"

@implementation Tic

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
//        NSLog(@"登录失败：%@", errMsg);
        [self showErrorMessage: errId errMsg: errMsg];
    }];
    
}


- (void) joinRoom: (NSString *)inputRoomID args:(NSDictionary*)args
{
    if (inputRoomID.length <= 0) {
        return;
    }
    
    NSString *teacherId = [args valueForKey:@"teacherId"];
    
    ClassroomViewController *classroomVC = [[ClassroomViewController alloc] initWithClasssID:inputRoomID teacherId: teacherId];
  
    
    [[TICManager sharedInstance] joinClassroomWithOption:^TICClassroomOption *(TICClassroomOption *option) {
        option.roomID = [inputRoomID intValue];
        option.role = kClassroomRoleStudent;
        option.eventListener = classroomVC;
        option.imListener = classroomVC;
        option.controlRole = @"ed640";
        return option;
    } succ:^{
        NSLog(@"进入房间成功");
        UIViewController *rootViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
        
        UIView *rootView = rootViewController.view ;
        
        
        [rootViewController addChildViewController:classroomVC];
        [rootView addSubview:classroomVC.view];
        
    } failed:^(NSString *module, int errId, NSString *errMsg) {;
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

- (void) showErrorMessage: (int)errId errMsg: (NSString *)errMsg
{
    NSDictionary *message = @{@"errId" : @(errId), @"errMsg" : errMsg};
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary: message];
    [pluginResult setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
}


- (void) pluginInitialize{
    NSLog(@"初始化插件");
    [[TICManager sharedInstance] initSDK: @"1400203905"];
}

- (void) onReset{
    NSLog(@"onReset");
}

- (void) dealloc {

}

@end
