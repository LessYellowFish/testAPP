//
//  KeyboardAvoidInterface.h
//  旺旺好房
//
//  Created by 刘浩宇 on 17/5/22.
//  Copyright © 2017年 房王网. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 监听键盘
 */
@interface KeyboardAvoidInterface : NSObject

/** 移除监听 */
- (void)deleteNotification;

+ (nonnull instancetype)shareKeyBoard;




/** 禁用的类 */
@property(nonatomic, strong, nonnull, readonly) NSMutableSet<Class> *disabledKeyBoardClasses;

- (void)addobjectDisableClass:(nonnull NSString *)classes;

@end
