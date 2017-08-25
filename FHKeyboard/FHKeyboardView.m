//
//  FHKeyboardView.m
//  FHKeyBoardDemo
//
//  Created by Moxtra on 2017/8/11.
//  Copyright © 2017年 MADAO. All rights reserved.
//

#import "FHKeyboardView.h"
#import "FHKeyboardEmojiCell.h"

#define FH_IS_IPAD [UIDevice deviceIsIPad]

#define EMOJI_CODE_TO_SYMBOL(x) ((((0x808080F0 | (x & 0x3F000) >> 4) | (x & 0xFC0) << 10) | (x & 0x1C0000) << 18) | (x & 0x3F) << 24);

#define FH_EMOJI_SCREEN_WIDTH ([UIScreen mainScreen].nativeBounds.size.width/[UIScreen mainScreen].nativeScale)
#define FH_EMOJI_SCREEN_HEIGHT ([UIScreen mainScreen].nativeBounds.size.height/[UIScreen mainScreen].nativeScale)
#define FH_EMOJI_COUNT_OF_EACHPAGE (self.numOfCols * self.numOfLines)
#define FH_EMOJI_CATEGORY_SIZE 60.f
#define FH_EMOJI_CATEGORY_HEIGHT 40.f

#pragma mark - FHKeyboardEmojiCategory

@implementation FHKeyboardEmojiCategory

@end

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

@end

@implementation FHEmojiKeyboardLayout

- (instancetype)init {
    if (self = [super init]) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.minimumLineSpacing = 0.f;
        self.minimumInteritemSpacing = 0.f;
    }
    return self;
}

@end

#pragma mark - FHKeyboardView

@interface FHKeyboardView()<UICollectionViewDelegate, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

//For categories
@property (nonatomic, strong) UICollectionView *categoriesCollectionView;

//For state mark
@property (nonatomic, assign) NSInteger selectedSection;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign, getter=isShow) BOOL show;
@property (nonatomic, assign) UIInterfaceOrientation orientation;

//UI Component
@property (nonatomic, strong) FHEmojiKeyboard *keyboard;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSLayoutConstraint *bottomLayoutConstraint;

//Action block
@property (nonatomic, copy) void(^handleEmojiClicked)(NSString *emoji);
@property (nonatomic, copy) void(^handleDeleteClicked)();

@end

static CGFloat const kPageControlHeight = 30.f;
static NSString *const kEmojiCellReuseIdentifier = @"kEmojiCellReuseIdentifier";
static NSString *const kCategoryCellReuseIdentifier = @"kCategoryCellReuseIdentifier";

@implementation FHKeyboardView

- (instancetype)initWithEmojiClicked:(void(^)(NSString *emoji))emojiHandler
                       deleteClicked:(void(^)())deleteHandler {
    if (self = [super initWithFrame:CGRectZero]) {
        self.frame = CGRectMake(0, FH_EMOJI_SCREEN_HEIGHT, FH_EMOJI_SCREEN_WIDTH, 200);
        [self resetConfiguration];
        [self setupKeyboard];
        [self setupPageControl];
        [self setupCategoriesView];
        [self setupDeleteButton];
        
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
    self.selectedIndex = 0;
    self.selectedSection = 0;
    self.numOfLines = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.numOfCols = 10;
    } else {
        self.numOfCols = 8;
    }
    
    self.backgroundColor = [UIColor whiteColor];
    _categories = [self defaultEmoticons];
    
    self.currentPageIndicatorTintColor = [UIColor blackColor];
    self.pageIndicatorTintColor = [UIColor redColor];
    
}

- (void)setupCategoriesView {
    UICollectionViewFlowLayout *verticalLayout = [[UICollectionViewFlowLayout alloc] init];
    verticalLayout.itemSize = CGSizeMake(FH_EMOJI_CATEGORY_SIZE, FH_EMOJI_CATEGORY_SIZE);
    verticalLayout.minimumLineSpacing = 0.f;
    verticalLayout.minimumInteritemSpacing = 0.f;
    verticalLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.categoriesCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, FH_EMOJI_SCREEN_WIDTH, FH_EMOJI_CATEGORY_HEIGHT) collectionViewLayout:verticalLayout];
    self.categoriesCollectionView.backgroundColor = [UIColor clearColor];
    self.categoriesCollectionView.delegate = self;
    self.categoriesCollectionView.dataSource = self;
    self.categoriesCollectionView.layer.borderWidth = 1.f;
    self.categoriesCollectionView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    [self.categoriesCollectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.categoriesCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedSection inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self.categoriesCollectionView registerClass:[FHKeyboardCategoryCell class] forCellWithReuseIdentifier:kCategoryCellReuseIdentifier];
    [self addSubview:self.categoriesCollectionView];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.categoriesCollectionView
                                                                      attribute:NSLayoutAttributeLeft
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1
                                                                       constant:-1];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.categoriesCollectionView
                                                                       attribute:NSLayoutAttributeRight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1
                                                                        constant:1];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.categoriesCollectionView
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:1];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.categoriesCollectionView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1
                                                                         constant:FH_EMOJI_CATEGORY_HEIGHT];
    [self addConstraints:@[leftConstraint,rightConstraint,bottomConstraint,heightConstraint]];
}

- (void)setupDeleteButton {
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.frame = CGRectMake(0, 0, FH_EMOJI_CATEGORY_SIZE, FH_EMOJI_CATEGORY_HEIGHT);
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.deleteButton setImage:self.deleteButtonImage forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(handleDeleteOnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.deleteButton];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.deleteButton
                                                                      attribute:NSLayoutAttributeRight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self
                                                                      attribute:NSLayoutAttributeRight
                                                                     multiplier:1
                                                                       constant:0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self.deleteButton
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:0
                                                                        constant:FH_EMOJI_CATEGORY_SIZE];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.deleteButton
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:0];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.deleteButton
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.categoriesCollectionView
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1
                                                                         constant:0];
    [self addConstraints:@[rightConstraint,widthConstraint,bottomConstraint,heightConstraint]];
}

- (void)makeConstraints {
    if (self.superview) {
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
    horizontalLayout.itemSize = self.keyboard.bounds.size;
    self.keyboard.dataSource = self;
    self.keyboard.delegate = self;
    [self.keyboard registerClass:[FHKeyboardEmojiCell class] forCellWithReuseIdentifier:kEmojiCellReuseIdentifier];
    [self addSubview:self.keyboard];
    [self makeConstraints];
}

- (void)setupPageControl {
    FHKeyboardEmojiCategory *currentCategory = self.categories[self.selectedSection];
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.keyboardHeight - kPageControlHeight - FH_EMOJI_CATEGORY_HEIGHT + 5.f, FH_EMOJI_SCREEN_WIDTH, kPageControlHeight)];
    CGFloat  overCount = currentCategory.emojis.count % FH_EMOJI_COUNT_OF_EACHPAGE;
    self.pageControl.numberOfPages = overCount == 0 ? currentCategory.emojis.count / FH_EMOJI_COUNT_OF_EACHPAGE : currentCategory.emojis.count / FH_EMOJI_COUNT_OF_EACHPAGE + 1;
    self.pageControl.currentPageIndicatorTintColor = self.currentPageIndicatorTintColor;
    self.pageControl.pageIndicatorTintColor = self.pageIndicatorTintColor;
    self.pageControl.hidden = self.hidePageControl;
    self.pageControl.userInteractionEnabled = NO;
    [self addSubview:self.pageControl];
    [self.pageControl setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.pageControl
                                                                       attribute:NSLayoutAttributeRight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1
                                                                        constant:0];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.pageControl
                                                                       attribute:NSLayoutAttributeLeft
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self
                                                                       attribute:NSLayoutAttributeLeft
                                                                      multiplier:1
                                                                        constant:0];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.pageControl
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1
                                                                         constant:5.f - FH_EMOJI_CATEGORY_HEIGHT];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self.pageControl
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1
                                                                         constant:kPageControlHeight];
    [self addConstraints:@[rightConstraint,leftConstraint,bottomConstraint,heightConstraint]];
    
}

#pragma mark - UICollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self isCategoriesCollectionView:collectionView] ? 1 : self.categories.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self isCategoriesCollectionView: collectionView]) {
        return self.categories.count;
    }
    else {
        FHKeyboardEmojiCategory *currentCategory = self.categories[section];
        CGFloat  overCount = currentCategory.emojis.count % FH_EMOJI_COUNT_OF_EACHPAGE;
        return overCount == 0 ? currentCategory.emojis.count / FH_EMOJI_COUNT_OF_EACHPAGE : currentCategory.emojis.count / FH_EMOJI_COUNT_OF_EACHPAGE + 1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isCategoriesCollectionView:collectionView]) {
        FHKeyboardCategoryCell *categoryCell = [collectionView dequeueReusableCellWithReuseIdentifier:kCategoryCellReuseIdentifier forIndexPath:indexPath];
        categoryCell.categoryIcon = [UIImage imageNamed:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
        return categoryCell;
    } else {
        FHKeyboardEmojiCategory *currentCategory = self.categories[indexPath.section];
        FHKeyboardEmojiCell *emojiCell = [self.keyboard dequeueReusableCellWithReuseIdentifier:kEmojiCellReuseIdentifier forIndexPath:indexPath];
        emojiCell.numOfCols = self.numOfCols;
        emojiCell.numOfLines = self.numOfLines;
        
        NSArray *emojiArray;
        if ((indexPath.row + 1) * FH_EMOJI_COUNT_OF_EACHPAGE > currentCategory.emojis.count)
        {
            emojiArray = [currentCategory.emojis subarrayWithRange:NSMakeRange(indexPath.row * FH_EMOJI_COUNT_OF_EACHPAGE, currentCategory.emojis.count - indexPath.row * FH_EMOJI_COUNT_OF_EACHPAGE)];
        } else {
            emojiArray = [currentCategory.emojis subarrayWithRange:NSMakeRange(indexPath.row * FH_EMOJI_COUNT_OF_EACHPAGE, FH_EMOJI_COUNT_OF_EACHPAGE)];
        }
        emojiCell.emojiArray = emojiArray;
        emojiCell.deleteButtonImage = self.deleteButtonImage;
        emojiCell.handleEmojiClicked = self.handleEmojiClicked;
        emojiCell.handleDeleteClicked = self.handleDeleteClicked;
        return emojiCell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isCategoriesCollectionView:collectionView]) {
        [self.keyboard scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.row] atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
        self.selectedIndex = 0;
        self.selectedSection = indexPath.row;
        [self updatePageControl];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isCategoriesCollectionView:collectionView]) {
        return CGSizeMake(FH_EMOJI_CATEGORY_SIZE, FH_EMOJI_CATEGORY_HEIGHT);
    } else {
        if (UIInterfaceOrientationIsLandscape([self orientation])) {
            return CGSizeMake(FH_EMOJI_SCREEN_HEIGHT, self.keyboardHeight);
        } else {
            return CGSizeMake(FH_EMOJI_SCREEN_WIDTH,  self.keyboardHeight);
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = CGPointMake(scrollView.contentOffset.x + 1, scrollView.contentOffset.y + 1);
    self.selectedIndex = [self.keyboard indexPathForItemAtPoint:offset].row;
    self.selectedSection = [self.keyboard indexPathForItemAtPoint:offset].section;
    [self.categoriesCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedSection inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self updatePageControl];
}

#pragma mark - PublicSetter

- (void)setCategories:(NSArray<FHKeyboardEmojiCategory *> *)categories {
    _categories = categories;
    [self.categoriesCollectionView.collectionViewLayout invalidateLayout];
    [self.categoriesCollectionView reloadData];
    [self.keyboard.collectionViewLayout invalidateLayout];
    [self.keyboard reloadData];
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight {
    _keyboardHeight = keyboardHeight;
    [self layoutIfNeeded];
}

- (void)setNumOfLines:(NSUInteger)numOfLines {
    _numOfLines = numOfLines;
    [self.categoriesCollectionView.collectionViewLayout invalidateLayout];
    [self.categoriesCollectionView reloadData];
    [self.keyboard.collectionViewLayout invalidateLayout];
    [self.keyboard reloadData];
}

- (void)setNumOfCols:(NSUInteger)numOfCols {
    _numOfCols = numOfCols;
    [self.categoriesCollectionView.collectionViewLayout invalidateLayout];
    [self.categoriesCollectionView reloadData];
    [self.keyboard.collectionViewLayout invalidateLayout];
    [self.keyboard reloadData];
}

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

- (void)setDeleteButtonImage:(UIImage *)deleteButtonImage {
    _deleteButtonImage = deleteButtonImage;
    [self.deleteButton setImage:deleteButtonImage forState:UIControlStateNormal];
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

#pragma mark - WidgetsAction

- (void)handleDeleteOnClicked:(UIButton *)sender
{
    if (self.handleDeleteClicked) {
        self.handleDeleteClicked();
    }
}

#pragma mark - HandleNotificaiton

- (void)handleOrientationDidChange:(NSNotification *)notification {
    if (self.show) {
        [self updateConstraints];
        [self resetKeyBoardLayout];
    }
    [self.keyboard scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:self.selectedSection] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
}

- (void)handleKeyboardWillShow:(NSNotification *)notification {
    if (self.show)
    {
        [self hideWithAnimated:YES];
    }
}

#pragma mark - Helper

- (BOOL)isCategoriesCollectionView:(UICollectionView *)collectionView {
    return collectionView == self.categoriesCollectionView;
}

- (UIInterfaceOrientation)orientation {
    return [UIApplication sharedApplication].statusBarOrientation;
}

- (void)updatePageControl {
    FHKeyboardEmojiCategory *currentCategory = self.categories[self.selectedSection];
    CGFloat  overCount = currentCategory.emojis.count % FH_EMOJI_COUNT_OF_EACHPAGE;
    self.pageControl.numberOfPages = overCount == 0 ? currentCategory.emojis.count / FH_EMOJI_COUNT_OF_EACHPAGE : currentCategory.emojis.count / FH_EMOJI_COUNT_OF_EACHPAGE + 1;
    self.pageControl.currentPage = self.selectedIndex;
}

#warning need config emojis more accurate
- (NSArray *)defaultEmoticons {
    NSMutableArray *aArray = [NSMutableArray new];
    for (int i=0x1F600; i<=0x1F64F; i++) {
        if (i < 0x1F641 || i > 0x1F644) {
            int sym = EMOJI_CODE_TO_SYMBOL(i);
            NSString *emoT = [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
            if (emoT)
            {
                [aArray addObject:emoT];
            }
        }
    }
    FHKeyboardEmojiCategory *aCategory = [[FHKeyboardEmojiCategory alloc] init];
    aCategory.emojis = aArray;
    
    NSMutableArray *bArray = [NSMutableArray new];
    for (int i=0x1F600; i<=0x1F64F; i++) {
        int sym = EMOJI_CODE_TO_SYMBOL(i);
        NSString *emoT = [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
        if (emoT)
        {
            [bArray addObject:emoT];
        }
    }
    FHKeyboardEmojiCategory *bCategory = [[FHKeyboardEmojiCategory alloc] init];
    bCategory.emojis = bArray;
    
    NSMutableArray *cArray = [NSMutableArray new];
    for (int i=0x1F680; i<=0x1F6C0; i++) {
        int sym = EMOJI_CODE_TO_SYMBOL(i);
        NSString *emoT = [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
        if (emoT)
        {
            [cArray addObject:emoT];
        }
    }
    FHKeyboardEmojiCategory *cCategory = [[FHKeyboardEmojiCategory alloc] init];
    cCategory.emojis = cArray;
    
    NSMutableArray *dArray = [NSMutableArray new];
    for (int i=0x1F170; i<=0x1F251; i++) {
        int sym = EMOJI_CODE_TO_SYMBOL(i);
        NSString *emoT = [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
        if (emoT)
        {
            [dArray addObject:emoT];
        }
    }
    FHKeyboardEmojiCategory *dCategory = [[FHKeyboardEmojiCategory alloc] init];
    dCategory.emojis = dArray;
    
    NSMutableArray *eArray = [NSMutableArray new];
    for (int i=0x1F600; i<=0x1F64F; i++) {
        int sym = EMOJI_CODE_TO_SYMBOL(i);
        NSString *emoT = [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
        if (emoT)
        {
            [eArray addObject:emoT];
        }
    }
    FHKeyboardEmojiCategory *eCategory = [[FHKeyboardEmojiCategory alloc] init];
    eCategory.emojis = eArray;
    return @[aCategory,bCategory,cCategory,dCategory,eCategory];
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
