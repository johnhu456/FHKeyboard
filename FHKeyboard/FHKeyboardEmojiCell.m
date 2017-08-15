//
//  FHKeyboardEmojiCell.m
//  FHKeyBoardDemo
//
//  Created by Moxtra on 2017/8/14.
//  Copyright © 2017年 MADAO. All rights reserved.
//

#import "FHKeyboardEmojiCell.h"

@interface FHKeyboardEmojiCell()
{
    NSInteger _numOfCols;
}

@property (nonatomic, strong) NSArray<UIButton *> *emojiButtons;

@end

static CGFloat const kEmojiSize = 35.f;

//#define FH_EMOJI_SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define FH_EMOJI_COL_SPACING ((self.bounds.size.width - kEmojiSize * _numOfCols)/(_numOfCols + 1))
#define FH_EMOJI_Line_SPACING ((self.bounds.size.height - kEmojiSize * 3)/4)
//static CGFloat const kEmojiColSpacing = 10.f;
//static CGFloat const kEmojiLinSpacing = 10.f;
//static CGFloat const kLeftInset = 15.f;
static CGFloat const kTopInsets = 20.f;

@implementation FHKeyboardEmojiCell

- (void)setEmojiArray:(NSArray<NSString *> *)emojiArray {
    NSAssert(((emojiArray.count + 1) %3 == 0), @"Emoji array count error, make sure that (emojiArray.count -1) %%3 == 0");
    _emojiArray = emojiArray;
    _numOfCols = (_emojiArray.count + 1)/3;
    [self updateContent];
}

- (void)updateContent {
    //Remove old emoji panel first.
    for (UIButton *emoji in self.emojiButtons) {
        [emoji removeFromSuperview];
    }
    self.emojiButtons = nil;
    UIDeviceOrientation  orient = [UIDevice currentDevice].orientation;
    if (orient == UIDeviceOrientationLandscapeLeft || orient == UIDeviceOrientationLandscapeRight) {
        self.bounds = CGRectMake(0, 0, 1024, 200);
    } else {
        self.bounds = CGRectMake(0, 0, 768, 200);
    }
    
    //Add new panel
    NSMutableArray *addedButtons = [[NSMutableArray alloc] init];
    for (int line = 0; line < 3 ; line++) {
        for (int col = 0; col < _numOfCols ; col++) {
            NSInteger index = line * _numOfCols + col;
            if (index <= self.emojiArray.count - 1) {
                UIButton *newEmojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [newEmojiButton setTitle:self.emojiArray[index] forState:UIControlStateNormal];
                newEmojiButton.frame = CGRectMake(FH_EMOJI_COL_SPACING + col * (FH_EMOJI_COL_SPACING + kEmojiSize), kTopInsets + line * (FH_EMOJI_Line_SPACING + kEmojiSize), kEmojiSize, kEmojiSize);
                newEmojiButton.tag = index;
                [newEmojiButton addTarget:self action:@selector(handleEmojiButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                [addedButtons addObject:newEmojiButton];
                [self.contentView addSubview:newEmojiButton];
            } else {
                UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
                deleteButton.frame = CGRectMake(FH_EMOJI_COL_SPACING + (_numOfCols - 1) * (FH_EMOJI_COL_SPACING + kEmojiSize), kTopInsets + line * (FH_EMOJI_Line_SPACING + kEmojiSize), kEmojiSize, kEmojiSize);
                [deleteButton addTarget:self action:@selector(handleDeleteButtonOnClicked:) forControlEvents:UIControlEventTouchUpInside];
                [addedButtons addObject:deleteButton];
                [self.contentView addSubview:deleteButton];
            }
        }
    }
    self.emojiButtons = [addedButtons copy];
}

- (void)handleEmojiButtonClicked:(UIButton *)sender {
    if (self.handleEmojiClicked)
    {
        self.handleEmojiClicked(sender.titleLabel.text);
    }
}

- (void)handleDeleteButtonOnClicked:(UIButton *)sender {
    if (self.handleDeleteClicked)
    {
        self.handleDeleteClicked();
    }
}

@end
