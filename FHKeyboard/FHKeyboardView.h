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

/**
 Get an emoji category
 
 @param icon Category icon
 @param emojis Emojis in this category
 */
+ (instancetype)categoryWithIcon:(UIImage *)icon emojis:(NSArray<NSString *> *)emojis;

@end

@interface FHKeyboardView : UIView

/**
 Data source of the emoji,
 @discussion Categories has value in default once FHKeyboardView get initliazed, you can also set it to load your own emojis
 */
@property (nonatomic, strong) NSArray <FHKeyboardEmojiCategory *> *categories;

/**
 Emoji keyboard's height, default is 216
 */
@property (nonatomic, assign) CGFloat keyboardHeight;
/**
 Num of emoji lines,default is 3
 */
@property (nonatomic, assign) NSUInteger numOfLines;
/**
 Num of emoji cols, default is 8 in iPhone, 10 in iPad
 */
@property (nonatomic, assign) NSUInteger numOfCols;
/**
 Hide page control,default is NO
 */
@property (nonatomic, assign) BOOL hidePageControl;
/**
 Pagecontrol's current page indicator color
 */
@property (nonatomic, strong) UIColor *currentPageIndicatorTintColor;
/**
 Pagecontrol's other page indicator color
 */
@property (nonatomic, strong) UIColor *pageIndicatorTintColor;

/**
 Delete button's indicator image
 */
@property (nonatomic, strong) UIImage *deleteButtonImage;

/**
 Initialize method
 
 @param emojiHandler A block be excuted when selected a emoji
 @param deleteHandler A block be excuted when delete button tapped
 @return FHKeyboardView
 */
- (instancetype)initWithEmojiClicked:(void(^)(NSString *emoji))emojiHandler
                       deleteClicked:(void(^)())deleteHandler;

/**
 Show the emoji keyboard
 
 @param view Where the keyboard will show
 @param animated Show with animated or not
 */
- (void)showInView:(UIView *)view animated:(BOOL)animated;

/**
 Hide the emoji keyboard
 
 @param animated Hide with animated or not
 */
- (void)hideWithAnimated:(BOOL)animated;

/**
 Reset keyboard's layout
 */
- (void)resetKeyBoardLayout;

/**
 Convert an unicode to string
 
 @param code The unicode
 @return Emoji result
 */
+ (NSString *)getEmojiStringFromUnicode:(UInt64)code;

+ (NSString *)getEmojiFromUnicodeString:(NSString *)code;
@end
