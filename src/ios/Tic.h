#import <Cordova/CDV.h>
#import <TICSDK/TICSDK.h>

@interface Tic : CDVPlugin {
//   EduPlayerViewController *player;
//   NSString *movie;
  NSString *callbackId;
}

@property (nonatomic, strong) TXBoardView *boardView;     //!< 白板

- (void) join:(CDVInvokedUrlCommand*)command;

@end
