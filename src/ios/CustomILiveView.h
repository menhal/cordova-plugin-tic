//
//  CustomILiveView.h
//  MyApp
//
//  Created by Kenny on 2019/7/10.
//

#import <UIKit/UIKit.h>
#import <TICSDK/TICSDK.h>

@interface CustomILiveView : UIView

- (instancetype) initWithFrame:(CGRect)frame and: (NSString *)userId ;
- (void) start;
- (void) stop;
- (void) setScoreWith: (int) score;

@property (nonatomic, strong) ILiveRenderView *renderView;
@property (nonatomic, strong) UILabel *scoreView;
@property (nonatomic) int score;
@property (nonatomic) BOOL visible;
@property (nonatomic, strong) NSString *userId;
@end
