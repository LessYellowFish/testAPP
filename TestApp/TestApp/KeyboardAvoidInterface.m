//
//  KeyboardAvoidInterface.m
//  旺旺好房
//
//  Created by 刘浩宇 on 17/5/22.
//  Copyright © 2017年 房王网. All rights reserved.
//

#import "KeyboardAvoidInterface.h"
#import <UIKit/UIKit.h>

@interface KeyboardAvoidInterface ()

@property(nonatomic, strong, nonnull, readwrite) NSMutableSet<Class> *disabledKeyBoardClasses;

/** 是否是禁用的VC */
@property (nonatomic,assign) BOOL disabledVc;

@property (nonatomic, weak)UIView *subView;
@property (nonatomic, weak)UIView *superView;


@end

@implementation KeyboardAvoidInterface


+ (instancetype)shareKeyBoard{
    static KeyboardAvoidInterface * model = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model = [[KeyboardAvoidInterface alloc]init];
    });
    return model;
}
- (instancetype)init{
    
    self = [super init];
    if (self) {
        __weak typeof(self) weakSelf = self;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __strong typeof(self) strongSelf = weakSelf;
        [strongSelf registerTextFieldViewClass:[UITextField class]
         didBeginEditingNotificationName:UITextFieldTextDidBeginEditingNotification
           didEndEditingNotificationName:UITextFieldTextDidEndEditingNotification];
        
        //  Registering for UITextView notification.
        [strongSelf registerTextFieldViewClass:[UITextView class]
         didBeginEditingNotificationName:UITextViewTextDidBeginEditingNotification
           didEndEditingNotificationName:UITextViewTextDidEndEditingNotification];
            
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        strongSelf.disabledKeyBoardClasses = [[NSMutableSet alloc] init];
            
        });
    }
    return self;
}

/** 注册监听 */
-(void)registerTextFieldViewClass:(nonnull Class)aClass
  didBeginEditingNotificationName:(nonnull NSString *)didBeginEditingNotificationName
    didEndEditingNotificationName:(nonnull NSString *)didEndEditingNotificationName{
    //    [_registeredClasses addObject:aClass];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldViewDidBeginEditing:) name:didBeginEditingNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldViewDidEndEditing:) name:didEndEditingNotificationName object:nil];
}

-(void)keyboardWillShow:(NSNotification *)showNot{
//    self.subView = [self textFieldBecoming];
//    self.superView = [self viewController].view;
     UIViewController *controller = [self getCurrentVC];
    if ([controller isKindOfClass:[UITabBarController class]]) {
        UITabBarController * tabarVC = (UITabBarController *)controller;
        if ([tabarVC.viewControllers count]>tabarVC.selectedIndex) {
            UINavigationController *navController = tabarVC.viewControllers[tabarVC.selectedIndex];
            controller = [navController topViewController];
        }
    }else if ([controller isKindOfClass:[UINavigationController class]]&&[(UINavigationController *)controller topViewController]){
        controller =[(UINavigationController *)controller topViewController];
    }else if([controller isKindOfClass:[UIViewController class]]){
        controller = controller;
    }else{
        controller = nil;
    }
    
    self.disabledVc = [self controllerDisabled:controller];
    if (controller&&!self.disabledVc) {
        self.superView = controller.view;
        //    1.取出键盘frame
        CGRect subRectFrame = [self.subView convertRect:self.subView.bounds toView:self.superView];
        CGFloat subViewH = subRectFrame.size.height;
        CGFloat subViewY = subRectFrame.origin.y;
        CGFloat subMaxH = subViewH + subViewY;
        
        CGRect keyboardFrame = [showNot.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat keyBoardY = keyboardFrame.origin.y;
        
        CGFloat transformY = keyBoardY - subMaxH;
        if (transformY < 0){
            CGRect frame = self.superView.frame;
            frame.origin.y = transformY ;
            //    2.键盘弹出的时间
            CGFloat duration=[showNot.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
            //    3.执行动画
            [UIView animateWithDuration:duration animations:^{
                self.superView.transform=CGAffineTransformMakeTranslation(0,transformY);
            }]; 
        }
    }
}
//是不是禁止了该类
- (BOOL)controllerDisabled:(UIViewController *)controller{
    
    for (Class disabledClass in self.disabledKeyBoardClasses) {
        if ([controller isKindOfClass:disabledClass]) {
            return YES;
            break;
        }
    }
    return NO;
}

-(void)textFieldViewDidBeginEditing:(NSNotification*)notification{
     self.subView = notification.object;
    
}
- (void)textFieldViewDidEndEditing:(NSNotification *)notification{
    self.subView = nil;
}
-(void)keyboardWillHide:(NSNotification *)hideNot{
    
    if (!self.disabledVc) {
        //    2.键盘弹出的时间
        CGFloat duration=[hideNot.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        //    3.执行动画
        [UIView animateWithDuration:duration animations:^{
            self.superView.transform=CGAffineTransformIdentity;
        }];
    }
}

//获取当前显示的viewcontroller
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}
/** 添加废弃类 */
- (void)addobjectDisableClass:(NSString *)classes{
    Class disableClass = NSClassFromString(classes);
    for (Class disClass in self.disabledKeyBoardClasses) {
        if ([disClass isSubclassOfClass:disableClass]) {
            return;
        }
    }
    [self.disabledKeyBoardClasses addObject:disableClass];
}
//释放通知
- (void)deleteNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
