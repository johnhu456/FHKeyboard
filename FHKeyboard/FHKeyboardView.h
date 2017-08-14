//
//  FHKeyboardView.h
//  FHKeyBoardDemo
//
//  Created by Moxtra on 2017/8/11.
//  Copyright © 2017年 MADAO. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FH_IS_IPAD [UIDevice deviceIsIPad]

@interface FHKeyboardView : UIView

- (instancetype)initWithEmojiClicked:(void(^)(NSString *emoji))emojiHandler
                       deleteClicked:(void(^)())deleteHandler;

- (void)showInView:(UIView *)view animated:(BOOL)animated;

- (void)hideWithAnimated:(BOOL)animated;

@end
