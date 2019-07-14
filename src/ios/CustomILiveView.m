//
//  CustomILiveView.m
//  MyApp
//
//  Created by Kenny on 2019/7/10.
//

#import "CustomILiveView.h"

@implementation CustomILiveView

- (instancetype) initWithFrame:(CGRect)frame and: (NSString *)userId{
    self = [super initWithFrame:frame];
    
    if(self){
        _userId = userId;
        _visible = NO;
//        [self setBackgroundColor:UIColor.redColor];
    }
    
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if(_visible){
        CGSize size = self.frame.size;
        _scoreView.frame = CGRectMake(0, 0, size.width - 5, 30);
        _renderView.frame = CGRectMake(0, 0, size.width, size.height);
    }
}

- (void) start
{
    _visible = YES;
    
    ILiveFrameDispatcher *frameDispatcher = [[ILiveRoomManager getInstance] getFrameDispatcher];
    _renderView = [frameDispatcher addRenderAt:CGRectZero forIdentifier: _userId srcType:QAVVIDEO_SRC_TYPE_CAMERA];
    
    if ([_userId isEqualToString:[[ILiveLoginManager getInstance] getLoginId]]) {
        _renderView.rotateAngle = ILIVEROTATION_180;
    }
    
    _renderView.autoRotate = YES;
    
    _renderView.frame = self.frame;
    
    [self addSubview:_renderView];
    
    
    _scoreView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 30)];
    [_scoreView setTextColor: [UIColor colorWithRed:(255)/255.0 green:(214)/255.0 blue:(48)/255.0 alpha:1.0]];
    [_scoreView setTextAlignment:NSTextAlignmentRight];
    
    [self addSubview: _scoreView];
    [self setScoreWith: self.score];
    
    [self addPostionConstraint];
    [self addCenterConstraint: _scoreView to: self];
}

- (void) stop
{
    _visible = NO;
    [_renderView removeFromSuperview];
    [_scoreView removeFromSuperview];
}

- (void) setScoreWith:(int)score
{
    self.score = score;
    NSString *text = [NSString stringWithFormat:@"★%d", score];
    [_scoreView setText: text];
}

- (void) addPostionConstraint{
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_scoreView attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_scoreView attribute:NSLayoutAttributeTop multiplier:1 constant:10]];
    
//    [_scoreView addConstraint: [NSLayoutConstraint constraintWithItem:_scoreView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:70]];
    
    [_scoreView addConstraint: [NSLayoutConstraint constraintWithItem:_scoreView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1 constant: 50]];
    
    [_scoreView addConstraint: [NSLayoutConstraint constraintWithItem:_scoreView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1 constant: 30]];
}


- (void) addCenterConstraint: (UIView *) from to: (UIView *)to{
    
    [to addConstraint: [NSLayoutConstraint constraintWithItem:to attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:from attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [to addConstraint: [NSLayoutConstraint constraintWithItem:to attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:from attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
}

@end
