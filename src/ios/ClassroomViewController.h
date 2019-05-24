//
//  ClassroomViewController.h
//  TICDemo
//
//  Created by jameskhdeng(邓凯辉) on 2018/5/15.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TICSDK/TICSDK.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDV.h>

/**
 课堂页面
 */
@interface ClassroomViewController : UIViewController <TICClassroomEventListener, TICClassroomIMListener>

// 初始化方法
- (instancetype)initWithClasssID:(NSString *)classId teacherId: (NSString *) teacherId plugin: (CDVPlugin *)plugin;

@end
