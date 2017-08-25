//
//  FHKeyboardEmojiCell.m
//  FHKeyBoardDemo
//
//  Created by Moxtra on 2017/8/14.
//  Copyright © 2017年 MADAO. All rights reserved.
//

#import "FHKeyboardEmojiCell.h"

@interface FHKeyboardEmojiCell()

@property (nonatomic, strong) NSArray<UIButton *> *emojiButtons;

@end

#define FH_EMOJI_SIZE 30.f
#define FH_EMOJI_COL_SPACING ((self.bounds.size.width - FH_EMOJI_SIZE * _numOfCols)/(_numOfCols + 1))
#define FH_EMOJI_Line_SPACING (((self.bounds.size.height - FH_EMOJI_SIZE * _numOfLines - kTopInsets)/(_numOfLines + 1)) - 5.f)

static CGFloat const kTopInsets = 20.f;

@implementation FHKeyboardEmojiCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.numOfCols = 8;
        self.numOfLines = 3;
    }
    return self;
}

- (void)setEmojiArray:(NSArray<NSString *> *)emojiArray {
    _emojiArray = emojiArray;
    _numOfCols = self.numOfCols;
    _numOfLines = self.numOfLines;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateContent];
    });
}

- (void)updateContent {
    //Remove old emoji panel first.
    for (UIButton *emoji in self.emojiButtons) {
        [emoji removeFromSuperview];
    }
    self.emojiButtons = nil;
    
    //Add new panel
    NSMutableArray *addedButtons = [[NSMutableArray alloc] init];
    for (int line = 0; line < _numOfLines ; line++) {
        for (int col = 0; col < _numOfCols ; col++) {
            NSInteger index = line * _numOfCols + col;
            if (index <= self.emojiArray.count - 1) {
                UIButton *newEmojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [newEmojiButton setTitle:self.emojiArray[index] forState:UIControlStateNormal];
                newEmojiButton.titleLabel.font = [UIFont systemFontOfSize:FH_EMOJI_SIZE - 5.f];
                newEmojiButton.frame = CGRectMake(FH_EMOJI_COL_SPACING + col * (FH_EMOJI_COL_SPACING + FH_EMOJI_SIZE), kTopInsets + line * (FH_EMOJI_Line_SPACING + FH_EMOJI_SIZE), FH_EMOJI_SIZE, FH_EMOJI_SIZE);
                newEmojiButton.tag = index;
                [newEmojiButton addTarget:self action:@selector(handleEmojiButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                [addedButtons addObject:newEmojiButton];
                [self.contentView addSubview:newEmojiButton];
            }
//        else {
//                break;
//            }
        }
//        if (addedButtons.count == self.emojiArray.count) {
//            UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
//            [deleteButton setImage:self.deleteButtonImage forState:UIControlStateNormal];
//            deleteButton.frame = CGRectMake(FH_EMOJI_COL_SPACING + (_numOfCols - 1) * (FH_EMOJI_COL_SPACING + FH_EMOJI_SIZE), kTopInsets + (kNumberOfLine - 1)* (FH_EMOJI_Line_SPACING + FH_EMOJI_SIZE), FH_EMOJI_SIZE, FH_EMOJI_SIZE);
//            [deleteButton addTarget:self action:@selector(handleDeleteButtonOnClicked:) forControlEvents:UIControlEventTouchUpInside];
//            [addedButtons addObject:deleteButton];
//            [self.contentView addSubview:deleteButton];
//            break;
//        }
    }
    self.emojiButtons = [addedButtons copy];
}
- (void)handleEmojiButtonClicked:(UIButton *)sender {
    if (self.handleEmojiClicked) {
        self.handleEmojiClicked(sender.titleLabel.text);
    }
}

- (void)handleDeleteButtonOnClicked:(UIButton *)sender {
    if (self.handleDeleteClicked) {
        self.handleDeleteClicked();
    }
}

@end

@interface FHKeyboardCategoryCell()

@property (nonatomic, strong) UIImageView *imageView;

@end
@implementation FHKeyboardCategoryCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupImageView];
    }
    return self;
}

- (void)setupImageView
{
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.imageView];
    [self.imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.contentView
                                                                      attribute:NSLayoutAttributeWidth
                                                                     multiplier:0
                                                                        constant:30.f];
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                                       attribute:NSLayoutAttributeCenterX
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.contentView
                                                                       attribute:NSLayoutAttributeCenterX
                                                                      multiplier:1
                                                                        constant:0];
    NSLayoutConstraint *bottomLayoutConstraint = [NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.contentView
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1
                                                                constant:0];
    NSLayoutConstraint *centerYLayoutConstraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                                        attribute:NSLayoutAttributeCenterY
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeCenterY
                                                                       multiplier:1
                                                                         constant:0];
    [self addConstraints:@[widthConstraint,centerXConstraint,bottomLayoutConstraint,centerYLayoutConstraint]];
}

- (void)setCategoryIcon:(UIImage *)categoryIcon {
    _categoryIcon = categoryIcon;
    self.imageView.image = _categoryIcon;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.backgroundColor = self.selected ? [UIColor lightGrayColor] : [UIColor whiteColor];
}
@end
