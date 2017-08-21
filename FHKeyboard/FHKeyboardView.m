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

#define FH_EMOJI_SCREEN_WIDTH ([UIScreen mainScreen].nativeBounds.size.width/[UIScreen mainScreen].nativeScale)
#define FH_EMOJI_SCREEN_HEIGHT ([UIScreen mainScreen].nativeBounds.size.height/[UIScreen mainScreen].nativeScale)
#define FH_EMOJI_COUNT_OF_EACHPAGE (self.numOfCols * self.numOfLines - 1)

#pragma mark - FHEmojiKeyboard

@interface FHEmojiKeyboard:UICollectionView

@end

@implementation FHEmojiKeyboard

- (instancetype)initWithFrame:(CGRect)frame
         collectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
        self.remembersLastFocusedIndexPath = YES;
        self.backgroundColor = [UIColor clearColor];
        self.showsHorizontalScrollIndicator = NO;
        self.pagingEnabled = YES;
    
    }
    return self;
}

@end

#pragma mark - FHEmojiKeyboardLayout

@interface FHEmojiKeyboardLayout:UICollectionViewFlowLayout

@property (strong)NSIndexPath* pathForFocusItem;

@end

@implementation FHEmojiKeyboardLayout

- (instancetype)init {
    if (self = [super init]) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.minimumLineSpacing = 0.f;
        self.minimumInteritemSpacing = 0.f;
        self.itemSize = CGSizeMake(FH_EMOJI_SCREEN_WIDTH, 200);
        self.estimatedItemSize = CGSizeMake(FH_EMOJI_SCREEN_WIDTH, 200);
    }
    return self;
}
//
//-(CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
//{
//    if (self.pathForFocusItem) {
//        UICollectionViewLayoutAttributes* layoutAttrs = [self layoutAttributesForItemAtIndexPath:self.pathForFocusItem];
//        return CGPointMake(layoutAttrs.frame.origin.x - self.collectionView.contentInset.left, layoutAttrs.frame.origin.y-self.collectionView.contentInset.top);
//    }else{
//        return [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
//    }
//}

@end


#pragma mark - FHKeyboardView

@interface FHKeyboardView()<UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray *emojiArray;

@property (nonatomic, assign) NSInteger selectedIndex;

@property (nonatomic, strong) FHEmojiKeyboard *keyboard;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, copy) void(^handleEmojiClicked)(NSString *emoji);

@property (nonatomic, copy) void(^handleDeleteClicked)();

@property (nonatomic, strong) NSLayoutConstraint *bottomLayoutConstraint;

@property (nonatomic, assign, getter=isShow) BOOL show;

@property (nonatomic, assign) UIInterfaceOrientation orientation;

@end

static CGFloat const kPageControlHeight = 30.f;

@implementation FHKeyboardView

- (instancetype)initWithEmojiClicked:(void(^)(NSString *emoji))emojiHandler
                       deleteClicked:(void(^)())deleteHandler {
    if (self = [super initWithFrame:CGRectZero]) {
        self.frame = CGRectMake(0, FH_EMOJI_SCREEN_HEIGHT, FH_EMOJI_SCREEN_WIDTH, 200);
        [self resetConfiguration];
        [self setupKeyboard];
        [self setupPageControl];
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.handleDeleteClicked = deleteHandler;
        self.handleEmojiClicked = emojiHandler;
        self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - PrivateMethod

- (void)resetConfiguration {
    self.keyboardHeight = 216.f;
    self.numOfLines = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.numOfCols = 10;
    } else {
        self.numOfCols = 8;
    }
    
    self.backgroundColor = [UIColor whiteColor];
    self.emojiArray = [self defaultEmoticons];
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
                                                                        constant:self.keyboardHeight];
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1
                                                                         constant:self.keyboardHeight];
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
    FHEmojiKeyboardLayout *horizontalLayout = [[FHEmojiKeyboardLayout alloc] init];
    self.keyboard = [[FHEmojiKeyboard alloc] initWithFrame:self.bounds collectionViewLayout:horizontalLayout];
    self.keyboard.dataSource = self;
    self.keyboard.delegate = self;
    [self.keyboard registerClass:[FHKeyboardEmojiCell class] forCellWithReuseIdentifier:@"11"];
    [self addSubview:self.keyboard];
    [self makeConstraints];
}

- (void)setupPageControl {
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.keyboardHeight - kPageControlHeight , FH_EMOJI_SCREEN_WIDTH, kPageControlHeight)];
    CGFloat  overCount = self.emojiArray.count % FH_EMOJI_COUNT_OF_EACHPAGE;
    self.pageControl.numberOfPages = overCount == 0 ? self.emojiArray.count / FH_EMOJI_COUNT_OF_EACHPAGE : self.emojiArray.count / FH_EMOJI_COUNT_OF_EACHPAGE + 1;
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
    CGFloat  overCount = self.emojiArray.count % FH_EMOJI_COUNT_OF_EACHPAGE;
    return overCount == 0 ?  self.emojiArray.count / FH_EMOJI_COUNT_OF_EACHPAGE : self.emojiArray.count / FH_EMOJI_COUNT_OF_EACHPAGE + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FHKeyboardEmojiCell *cell = [self.keyboard dequeueReusableCellWithReuseIdentifier:@"11" forIndexPath:indexPath];
    NSArray *emojiArray;
    if ((indexPath.row + 1) * FH_EMOJI_COUNT_OF_EACHPAGE > self.emojiArray.count)
    {
        emojiArray = [self.emojiArray subarrayWithRange:NSMakeRange(indexPath.row * FH_EMOJI_COUNT_OF_EACHPAGE, self.emojiArray.count - indexPath.row * FH_EMOJI_COUNT_OF_EACHPAGE)];
    } else {
        emojiArray = [self.emojiArray subarrayWithRange:NSMakeRange(indexPath.row * FH_EMOJI_COUNT_OF_EACHPAGE, FH_EMOJI_COUNT_OF_EACHPAGE)];
    }
    cell.emojiArray = emojiArray;
    cell.deleteButtonImage = self.deleteButtonImage;
    cell.handleEmojiClicked = self.handleEmojiClicked;
    cell.handleDeleteClicked = self.handleDeleteClicked;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (UIInterfaceOrientationIsLandscape([self orientation])) {
        return CGSizeMake(FH_EMOJI_SCREEN_HEIGHT, self.keyboardHeight);
    } else {
        return CGSizeMake(FH_EMOJI_SCREEN_WIDTH,  self.keyboardHeight);
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.pageControl.currentPage = scrollView.contentOffset.x/self.keyboard.frame.size.width;
}

#pragma mark - PublicMethod

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    if (self.show) {
        return;
    }
    [view endEditing:YES];
    [view addSubview:self];
    [self resetKeyBoardLayout];
    [self makeConstraints];
    if (animated)
    {
        [UIView animateWithDuration:0.25f delay:0.f options:7 animations:^{
            [self updateConstraints];
        } completion:^(BOOL finished) {
        
        }];
    } else {
        [self updateConstraints];
    }
    self.show = YES;
}

- (void)hideWithAnimated:(BOOL)animated {
    if (animated)
    {
        self.bottomLayoutConstraint.constant = self.keyboardHeight;
        [UIView animateWithDuration:0.25f delay:0.f options:7 animations:^{
            [self.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        self.bottomLayoutConstraint.constant = self.keyboardHeight;
        [self removeFromSuperview];
    }
    self.show = NO;
}

#pragma mark - HandleNotificaiton

- (void)handleOrientationDidChange:(NSNotification *)notification {
    if (self.show) {
        [self updateConstraints];
        self.selectedIndex = self.pageControl.currentPage;
        [self resetKeyBoardLayout];
    }
    [self.keyboard scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
}

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    if (self.show)
    {
        [self hideWithAnimated:YES];
    }
}

#pragma mark - Helper

- (UIInterfaceOrientation)orientation {
    return [UIApplication sharedApplication].statusBarOrientation;
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

- (void)resetKeyBoardLayout {
    if (UIInterfaceOrientationIsLandscape([self orientation])) {
        self.keyboard.frame = CGRectMake(0, 0, FH_EMOJI_SCREEN_HEIGHT, self.keyboardHeight);
    } else {
        self.keyboard.frame = CGRectMake(0, 0, FH_EMOJI_SCREEN_WIDTH, self.keyboardHeight);
    }
    [self.keyboard.collectionViewLayout invalidateLayout];
    [self.keyboard reloadData];
}

@end
