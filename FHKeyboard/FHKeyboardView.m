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
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

@interface FHEmojiKeyboard:UICollectionView

@end

@implementation FHEmojiKeyboard
- (instancetype)initWithFrame:(CGRect)frame
         collectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithFrame:frame collectionViewLayout:layout])
    {
        self.showsHorizontalScrollIndicator = NO;
        self.pagingEnabled = YES;
    }
    return self;
}

@end

@interface FHKeyboardView()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) NSArray *array;

@property (nonatomic, strong) FHEmojiKeyboard *keyboard;

@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, copy) void(^handleEmojiClicked)(NSString *emoji);

@property (nonatomic, copy) void(^handleDeleteClicked)();

@end

static CGFloat const kKeyboardHeight = 200.f;
static CGFloat const kPageControlHeight = 30.f;

@implementation FHKeyboardView

- (instancetype)initWithEmojiClicked:(void(^)(NSString *emoji))emojiHandler
                       deleteClicked:(void(^)())deleteHandler {
    if (self = [super initWithFrame:CGRectZero]) {
        self.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 200);
        self.backgroundColor = [UIColor whiteColor];
        [self setupKeyboard];
        [self setupPageControl];
        
        self.array = [self defaultEmoticons];
        self.handleDeleteClicked = deleteHandler;
        self.handleEmojiClicked = emojiHandler;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardNotifications:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardNotifications:) name:UIKeyboardWillHideNotification object:nil];
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

- (void)setupKeyboard {
    UICollectionViewFlowLayout *horizontalLayout = [[UICollectionViewFlowLayout alloc] init];
    horizontalLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    horizontalLayout.minimumLineSpacing = 0.f;
    horizontalLayout.minimumInteritemSpacing = 0.f;
    horizontalLayout.itemSize = CGSizeMake(SCREEN_WIDTH, 200);
    horizontalLayout.estimatedItemSize = CGSizeMake(SCREEN_WIDTH, 200);
    self.keyboard = [[FHEmojiKeyboard alloc] initWithFrame:self.bounds collectionViewLayout:horizontalLayout];
    self.keyboard.dataSource = self;
    self.keyboard.delegate = self;
    [self.keyboard registerClass:[FHKeyboardEmojiCell class] forCellWithReuseIdentifier:@"11"];
    [self addSubview:self.keyboard];
}
- (void)setupPageControl {
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 100, SCREEN_WIDTH, kPageControlHeight)];
    self.pageControl.numberOfPages = 2;
    self.pageControl.pageIndicatorTintColor = [UIColor redColor];
    [self addSubview:self.pageControl];
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
    NSArray *shitArray = [self.array subarrayWithRange:NSMakeRange(0, 23)];
    cell.emojiArray = shitArray;
    cell.handleEmojiClicked = self.handleEmojiClicked;
    cell.handleDeleteClicked = self.handleDeleteClicked;
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger index = self.keyboard.contentOffset.x/SCREEN_WIDTH;
    self.pageControl.currentPage = index;
}

#pragma mark - PublicMethod

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    [view endEditing:YES];
    [view addSubview:self];
    if (animated)
    {
        [UIView animateWithDuration:0.25f delay:0.f options:7 animations:^{
            self.frame = CGRectMake(0, SCREEN_HEIGHT - 200, SCREEN_WIDTH, 200);
        } completion:^(BOOL finished) {
//            [self removeFromSuperview];
        }];
    } else {
        self.frame = CGRectMake(0, SCREEN_HEIGHT- 200, SCREEN_WIDTH, 200);
    }
}

- (void)hideWithAnimated:(BOOL)animated {

    if (animated)
    {
        [UIView animateWithDuration:0.25f delay:0.f options:7 animations:^{
            self.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 200);
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        self.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 200);
        [self removeFromSuperview];
    }
}

- (void)keyboardNotifications:(NSNotification *)notification {
    NSLog(@"%@",notification);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
