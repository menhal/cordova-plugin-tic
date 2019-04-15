#import <Cordova/CDV.h>
#import "Tic.h"

@interface Tic : CDVPlugin {
//   EduPlayerViewController *player;
//   NSString *movie;
  NSString *callbackId;
}

- (void) join:(CDVInvokedUrlCommand*)command;

@end
