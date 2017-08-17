//
//  FHKeyboardView.m
//  FHKeyBoardDemo
//
//  Created by Moxtra on 2017/8/11.
//  Copyright © 2017年 MADAO. All rights reserved.
//

#import "FHKeyboardView.h"
#import "FHKeyboardEmojiCell.h"

#define EMOJI_CODE_TO_SYMBOL(x) ((((0x808080F0 | (x & 0x3F000) >> 4) | (x & 0xFC0) << 10) | (x & 0x1C0000) << 18) | (x & 0x3F) << 24);

#define FH_EMOJI_SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define FH_EMOJI_SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

#pragma mark - FHEmojiKeyboard

@interface FHEmojiKeyboard:UICollectionView

@end

@implementation FHEmojiKeyboard
- (instancetype)initWithFrame:(CGRect)frame
         collectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithFrame:frame collectionViewLayout:layout])
    {
        self.backgroundColor = [UIColor clearColor];
        self.showsHorizontalScrollIndicator = NO;
        self.pagingEnabled = YES;
    }
    return self;
}

@end

#pragma mark - FHKeyboardView

@interface FHKeyboardView()<UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray *array;

@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, strong) FHEmojiKeyboard *keyboard;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, copy) void(^handleEmojiClicked)(NSString *emoji);

@property (nonatomic, copy) void(^handleDeleteClicked)();

@property (nonatomic, strong) NSLayoutConstraint *bottomLayoutConstraint;

@end

static CGFloat const kKeyboardHeight = 200.f;
static CGFloat const kPageControlHeight = 30.f;

@implementation FHKeyboardView

- (instancetype)initWithEmojiClicked:(void(^)(NSString *emoji))emojiHandler
                       deleteClicked:(void(^)())deleteHandler {
    if (self = [super initWithFrame:CGRectZero]) {
        self.frame = CGRectMake(0, FH_EMOJI_SCREEN_HEIGHT, FH_EMOJI_SCREEN_WIDTH, 200);
        self.backgroundColor = [UIColor whiteColor];
        [self setupKeyboard];
        [self setupPageControl];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.array = [self defaultEmoticons];
        self.handleDeleteClicked = deleteHandler;
        self.handleEmojiClicked = emojiHandler;
        self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (NSArray *)defaultEmoticons {
    NSMutableArray *array = [NSMutableArray new];
    for (int i=0x1F600; i<=0x1F64F; i++) {
        if (i < 0x1F641 || i > 0x1F644) {
            int sym = EMOJI_CODE_TO_SYMBOL(i);
            NSString *emoT = [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
            [array addObject:emoT];
        }
    }
    return array;
}

- (void)makeConstraints {
    if (self.superview) {
        [self removeConstraints:self.constraints];
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.superview
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1
                                                                       constant:0];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                      attribute:NSLayoutAttributeRight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.superview
                                                                      attribute:NSLayoutAttributeRight
                                                                     multiplier:1
                                                                       constant:0];
        self.bottomLayoutConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                       attribute:NSLayoutAttributeBottom
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.superview
                                                                       attribute:NSLayoutAttributeBottom
                                                                      multiplier:1
                                                                        constant:200.f];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1
                                                                         constant:200.f];
        [self.superview addConstraints:@[leftConstraint,rightConstraint,self.bottomLayoutConstraint,heightConstraint]];
        [self.superview layoutIfNeeded];
    }
}

- (void)updateConstraints {
    [super updateConstraints];
    if (self.superview) {
        self.bottomLayoutConstraint.constant = 0.f;
        [self.superview layoutIfNeeded];
    }
}

- (void)setupKeyboard {
    UICollectionViewFlowLayout *horizontalLayout = [[UICollectionViewFlowLayout alloc] init];
    horizontalLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    horizontalLayout.minimumLineSpacing = 0.f;
    horizontalLayout.minimumInteritemSpacing = 0.f;
    horizontalLayout.itemSize = CGSizeMake(FH_EMOJI_SCREEN_WIDTH, 200);
    horizontalLayout.estimatedItemSize = CGSizeMake(FH_EMOJI_SCREEN_WIDTH, 200);
    self.keyboard = [[FHEmojiKeyboard alloc] initWithFrame:self.bounds collectionViewLayout:horizontalLayout];
    self.keyboard.dataSource = self;
    self.keyboard.delegate = self;
    [self.keyboard registerClass:[FHKeyboardEmojiCell class] forCellWithReuseIdentifier:@"11"];
    [self addSubview:self.keyboard];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.keyboard
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1
                                                                       constant:0];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.keyboard
                                                                       attribute:NSLayoutAttributeRight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1
                                                                        constant:0];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.keyboard
                                                               attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1
                                                                constant:0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.keyboard
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:0];
    [self addConstraints:@[leftConstraint,rightConstraint,topConstraint,bottomConstraint]];
}

- (void)setupPageControl {
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, kKeyboardHeight - kPageControlHeight , FH_EMOJI_SCREEN_WIDTH, kPageControlHeight)];
    self.pageControl.numberOfPages = 2;
    self.pageControl.currentPageIndicatorTintColor = self.currentPageIndicatorTintColor;
    self.pageControl.pageIndicatorTintColor = self.pageIndicatorTintColor;
    self.pageControl.hidden = self.hidePageControl;
    [self addSubview:self.pageControl];
}

#pragma mark - PublicSetter

- (void)setHidePageControl:(BOOL)hidePageControl {
    _hidePageControl = hidePageControl;
    self.pageControl.hidden = _hidePageControl;
}

- (void)setCurrentPageIndicatorTintColor:(UIColor *)currentPageIndicatorTintColor {
    _currentPageIndicatorTintColor = currentPageIndicatorTintColor;
    self.pageControl.currentPageIndicatorTintColor = _currentPageIndicatorTintColor;
}

- (void)setPageIndicatorTintColor:(UIColor *)pageIndicatorTintColor {
    _pageIndicatorTintColor = pageIndicatorTintColor;
    self.pageControl.pageIndicatorTintColor = _pageIndicatorTintColor;
}

#pragma mark - UICollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FHKeyboardEmojiCell *cell = [self.keyboard dequeueReusableCellWithReuseIdentifier:@"11" forIndexPath:indexPath];
    NSArray *emojiArray;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        emojiArray= [self.array subarrayWithRange:NSMakeRange(0, 29)];
    } else {
        emojiArray = [self.array subarrayWithRange:NSMakeRange(0, 23)];
    }
    cell.emojiArray = emojiArray;
    cell.handleEmojiClicked = self.handleEmojiClicked;
    cell.handleDeleteClicked = self.handleDeleteClicked;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(FH_EMOJI_SCREEN_HEIGHT, 200);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.selectedIndex = self.keyboard.contentOffset.x/FH_EMOJI_SCREEN_WIDTH;
    self.pageControl.currentPage = self.selectedIndex;
}

#pragma mark - PublicMethod

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    [view endEditing:YES];
    [view addSubview:self];
    [self makeConstraints];
    if (animated)
    {
        [UIView animateWithDuration:0.25f delay:0.f options:7 animations:^{
            self.bottomLayoutConstraint.constant = 0.f;
            [self.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
        
        }];
    } else {
        self.bottomLayoutConstraint.constant = 0.f;
        [self.superview layoutIfNeeded];
    }
}

- (void)hideWithAnimated:(BOOL)animated {

    if (animated)
    {
        self.bottomLayoutConstraint.constant = 200.f;
        [UIView animateWithDuration:0.25f delay:0.f options:7 animations:^{
            [self.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        self.bottomLayoutConstraint.constant = 200.f;
        [self removeFromSuperview];
    }
}

#pragma mark - HandleNotificaiton

- (void)handleOrientationDidChange:(NSNotification *)notification {
    [self updateConstraints];
    self.keyboard.frame = CGRectMake(0, 0, FH_EMOJI_SCREEN_HEIGHT, 200);
    [self.keyboard reloadData];
    [self.keyboard selectItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionTop];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
