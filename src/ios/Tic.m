#import "Tic.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import "TICManager.h"
#import "ClassroomViewController.h"
#import "ClassroomViewController.h"

@implementation Tic

- (void) init:(CDVInvokedUrlCommand*)command
{
    NSLog(@"初始化插件");
    int sdkappid = [[command.arguments objectAtIndex:0] intValue];
    
    [[TICManager sharedInstance] init:sdkappid callback:^(TICModule module, int code, NSString *desc) {
        if(code == 0){
//            [[TICManager sharedInstance] addStatusListener:self];
        } else {
            [self showErrorMessage: 0 errMsg: @"初始化插件失败"];
        }
    }];
}

- (void) join:(CDVInvokedUrlCommand*)command
{
    callbackId = command.callbackId;
    
    NSDictionary *args = [command.arguments objectAtIndex:0];
    
    NSString *roomId = [args valueForKey:@"roomId"];
    NSString *userName = [args valueForKey:@"userName"];
    NSString *userSig = [args valueForKey:@"userSig"];
    
    [[TICManager sharedInstance] login:userName userSig:userSig callback:^(TICModule module, int code, NSString *desc) {
        if(code == 0){
            [self joinRoom: roomId args: args];
        } else {
            [self showErrorMessage: code errMsg: desc];
        }
    }];
    
}


- (void) joinRoom: (NSString *)inputRoomID args:(NSDictionary*)args
{
    NSString *teacherId = [args valueForKey:@"teacherId"];
    NSString *userId = [args valueForKey:@"userName"];

    ClassroomViewController *classroomVC = [[ClassroomViewController alloc] initWithClasssID:inputRoomID teacherId: teacherId userId: userId plugin: self];

    TICClassroomOption *option = [[TICClassroomOption alloc] init];
    option.classId = [inputRoomID intValue];

    [[TICManager sharedInstance] addMessageListener: classroomVC];
    [[TICManager sharedInstance] addEventListener: classroomVC];

    UIViewController *rootViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    UIView *rootView = rootViewController.view ;

    [[TICManager sharedInstance] joinClassroom:option callback:^(TICModule module, int code, NSString *desc) {
        if(code == 0){
            [[[TICManager sharedInstance] getBoardController] addDelegate:self];
            [rootViewController addChildViewController:classroomVC];
            [rootView addSubview:classroomVC.view];

            [self showSuccessMessage];
            NSLog(@"进入房间成功");
        }
        else{
            [self showErrorMessage: code errMsg: desc];
        }
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
