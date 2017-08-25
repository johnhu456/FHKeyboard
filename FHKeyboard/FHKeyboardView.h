//
//  FHKeyboardView.h
//  FHKeyBoardDemo
//
//  Created by Moxtra on 2017/8/11.
//  Copyright © 2017年 MADAO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FHKeyboardEmojiCategory: NSObject

/**
 The icon used to indicate this emoji category
 */
@property (nonatomic, strong) UIImage *icon;

/**
 The emojis in this category
 */
@property (nonatomic, strong) NSArray<NSString *> *emojis;

@end

@interface FHKeyboardView : UIView

@property (nonatomic, assign) CGFloat keyboardHeight;

@property (nonatomic, assign) NSUInteger numOfLines;

@property (nonatomic, assign) NSUInteger numOfCols;

@property (nonatomic, assign) BOOL hidePageControl;

@property (nonatomic, strong) UIColor *currentPageIndicatorTintColor;

@property (nonatomic, strong) UIColor *pageIndicatorTintColor;

@property (nonatomic, strong) UIImage *deleteButtonImage;

- (instancetype)initWithEmojiClicked:(void(^)(NSString *emoji))emojiHandler
                       deleteClicked:(void(^)())deleteHandler;

- (void)showInView:(UIView *)view animated:(BOOL)animated;

- (void)hideWithAnimated:(BOOL)animated;

@end
