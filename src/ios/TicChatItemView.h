//
//  TicChatItemView.h
//  MyApp
//
//  Created by Kenny on 2019/7/12.
//

#import <UIKit/UIKit.h>
#import <TICSDK/TICSDK.h>

@interface TicChatItemView : UIView

- (instancetype) initWithFrame:(CGRect)frame ;
//- (CGFloat) getHeight;


@property (nonatomic, strong) UILabel *userLabel;
@property (nonatomic, strong) UILabel *msgLabel;

- (void) setMessage: (NSString *) message from: (NSString *) from;
+ (CGSize) getRect: (CGFloat) containerWidth userId:(NSString *) userId msg: (NSString *) msg;

@end
