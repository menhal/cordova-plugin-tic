#import "Tic.h"
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <TICSDK/TICSDK.h>
//#import "ClassroomViewController.h"

@implementation Tic
- (void) join:(CDVInvokedUrlCommand*)command
{
    NSString *roomId = [command.arguments objectAtIndex:0];
//    NSDictionary *args = [command.arguments objectAtIndex:1];
//    double start = [[args valueForKey:@"start"] doubleValue];
    
    NSLog(@"RoomId:%@", roomId);
    
    [self login:command];
}


- (void) login:(CDVInvokedUrlCommand*)command
{

//    NSString *userName = [command.arguments objectAtIndex:0];
//    NSString *userSig = [command.arguments objectAtIndex:1];
    
    NSString *roomId = [command.arguments objectAtIndex:0];
    
    NSString *userName =  @"iOS_trtc_01";
    NSString *userSig = @"eJxlj11PgzAUhu-5FU2vjSsf5cM7XLbYqFtYZzavGoQCDQy6cjAjxv*uoslIPLfPk-d9z4eFEML7J36bZlk3tCBg1BKjO4QJvrlCrVUuUhCuyf9BedHKSJEWIM0EbUqpQ8jcUblsQRXqz1BbLsBAJog9k-q8FlPTb4pHyHeKG3pzRZUTfF69LlmyPAKrnbB6GTT4MoQ4WO1IcjpSLwrq3cEf1*kmI6ypDpuEVTHjiz5utmPpVWuanM-5vlN8fJPaXxRcPpSsfLSby5AN9f2sEtRJXt*KaBDNB71L06uunQSH2NR2XPJz2Pq0vgCGhl9d";
    
    [[TICManager sharedInstance] loginWithUid:userName userSig:userSig succ:^{
        NSLog(@"登录成功！");
        [self joinRoom: roomId];
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"登录失败：%@", errMsg);
    }];
    
}



- (void) joinRoom: (NSString *)inputRoomID
{
    if (inputRoomID.length <= 0) {
        return;
    }
    
//    ClassroomViewController *classroomVC = [[ClassroomViewController alloc] initWithClasssID:inputRoomID];
    
    [[TICManager sharedInstance] joinClassroomWithOption:^TICClassroomOption *(TICClassroomOption *option) {
        option.roomID = [inputRoomID intValue];
        option.role = kClassroomRoleStudent;
        option.eventListener = self;
        option.imListener = self;
        option.controlRole = @"ed640";
        return option;
    } succ:^{
        NSLog(@"进入房间成功");
//        [self.navigationController pushViewController:classroomVC animated:YES];
    } failed:^(NSString *module, int errId, NSString *errMsg) {;
         NSLog(@"进入房间失败：%d %@", errId, errMsg);
    }];
}

- (void) pluginInitialize{
      NSLog(@"初始化插件");
    
    [[TICManager sharedInstance] initSDK: @"1400200384"];
}

- (void) onReset{
    NSLog(@"onReset");
}

- (void) dealloc {
  //[player release];
  //[movie release];
  //[super dealloc];
}

@end
