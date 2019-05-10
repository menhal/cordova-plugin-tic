#import <Cordova/CDV.h>

@interface Tic : CDVPlugin {
//   EduPlayerViewController *player;
//   NSString *movie;
  NSString *callbackId;
}

- (void) join:(CDVInvokedUrlCommand*)command;

@end
