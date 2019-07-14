//
//  TicChatItem.m
//  MyApp
//
//  Created by Kenny on 2019/7/12.
//

//
//  CustomILiveView.m
//  MyApp
//
//  Created by Kenny on 2019/7/10.
//

#import "TicChatItemView.h"

@implementation TicChatItemView

- (instancetype) initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    if(self){
        _userLabel = [[UILabel alloc] init];
        _msgLabel = [[UILabel alloc] init];
        
        [_userLabel setTextColor:UIColor.blackColor];
        [_msgLabel setTextColor:UIColor.grayColor];
       
        _msgLabel.numberOfLines = 0;
        
        [self addSubview:_userLabel];
        [self addSubview:_msgLabel];
    }
    
    return self;
}

+ (NSDictionary *) getFont
{
    UILabel *label = [[UILabel alloc] init];
    return @{NSFontAttributeName:label.font};
}

+ (CGSize) singleLineTextRect: (NSString *) text
{
    NSDictionary *font = [TicChatItemView getFont];
    CGSize textSize = [text sizeWithAttributes: font];
    return textSize;
}

+ (CGSize) multiLineTextRect: (NSString *) text width: (CGFloat) width
{
    NSDictionary *font = [TicChatItemView getFont];
    CGSize size = CGSizeMake(width, MAXFLOAT);//设置高度宽度的最大限度
    
    CGRect rect = [text boundingRectWithSize:size options:NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes: font context:nil];
    
    return rect.size;
}

+ (CGSize) getRect: (CGFloat) containerWidth userId:(NSString *) userId msg: (NSString *) msg
{
    CGSize userLabelSize = [TicChatItemView singleLineTextRect:userId];
    CGFloat msgLabelWidth = containerWidth - userLabelSize.width - 10;
    return [TicChatItemView multiLineTextRect:msg width:msgLabelWidth];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    CGSize userSize = [TicChatItemView singleLineTextRect:_userLabel.text];
    CGFloat userWidth = userSize.width;
    CGFloat userHeight = userSize.height;
    _userLabel.frame = CGRectMake(0, 0, userWidth, userHeight);
    
    CGSize containerSize = self.frame.size;
    CGSize msgSize = [TicChatItemView multiLineTextRect:_msgLabel.text width:containerSize.width - userWidth - 10];
    
    _msgLabel.frame = CGRectMake(userWidth + 10, 0, msgSize.width, msgSize.height);
}


- (void) setMessage: (NSString *) message from: (NSString *) from
{
    _userLabel.text = from;
    _msgLabel.text = message;
    [_msgLabel sizeToFit];
}

//- (CGFloat) getHeight
//{
//    int msgWidth = [self getMsgWidth];
//    CGSize size = CGSizeMake(msgWidth, MAXFLOAT);//设置高度宽度的最大限度
//
//    CGRect rect = [_msgLabel.text boundingRectWithSize:size options:NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_msgLabel.font} context:nil];
//
//    return ceilf(rect.size.height);
//}
//
//- (int) getMsgWidth
//{
//    CGSize containerSize = self.frame.size;
//    CGFloat userWidth = [self getUserWidth: _userLabel];
//
//    int msgWidth = containerSize.width - userWidth - 10;
//    return msgWidth;
//}
//
//+ (CGFloat) getUserWidth:(UILabel *)label
//{
//    CGSize textSize = [label.text sizeWithAttributes:@{NSFontAttributeName:label.font}];
//    return textSize.width;
//}
//
//- (CGFloat) getTextHeight: (UILabel *) label
//{
//    CGSize textSize = [label.text sizeWithAttributes:@{NSFontAttributeName:label.font}];
//    return textSize.height;
//}
//
//+ (CGFloat) getRect: (NSString *) userId msg: (NSString *) msg
//{
//    UILabel *label = [[UILabel alloc] init];
//    label.text = userId;
//
//    UILabel *label2 = [[UILabel alloc] init];
//    label.text = msg;
//
//    CGFloat msgWidth = [self getUserWidth: label];
//
//}

@end
