//
//  ViewController.m
//  FHKeyBoardDemo
//
//  Created by Moxtra on 2017/8/11.
//  Copyright © 2017年 MADAO. All rights reserved.
//

#import "ViewController.h"
#import "FHKeyboardView.h"

#define EMOJI_CODE_TO_SYMBOL(x) ((((0x808080F0 | (x & 0x3F000) >> 4) | (x & 0xFC0) << 10) | (x & 0x1C0000) << 18) | (x & 0x3F) << 24);

@interface ViewController ()

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) UIButton *emojiButton;

@property (nonatomic, strong) FHKeyboardView *keyboardView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(100, 100, 200, 60)];
    self.textField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.textField];
    
    self.emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.emojiButton.frame = CGRectMake(100, 200, 200, 60);
    [self.emojiButton addTarget:self action:@selector(handleEmojiButtonOnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.emojiButton.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.emojiButton];
}

- (void)handleEmojiButtonOnClicked:(UIButton *)sender {
    if (!self.keyboardView)
    {
        FHKeyboardView *keyboardView = [[FHKeyboardView alloc] initWithEmojiClicked:^(NSString *emoji) {
            self.textField.text = [self.textField.text stringByAppendingString:emoji];
        } deleteClicked:^{
            if (self.textField.text.length == 0)
            {
                return;
            }
            self.textField.text = [self.textField.text substringToIndex:self.textField.text.length - 2];
        }];
        self.keyboardView = keyboardView;
    }
    self.keyboardView.backgroundColor = [UIColor grayColor];
//    self.keyboardView.keyboardHeight = 300.f;
    self.keyboardView.deleteButtonImage = [UIImage imageNamed:@"file_toolbar_delete"];
    [self.keyboardView showInView:self.view animated:YES];
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
    self.textField.text = array[0];
    return array;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.keyboardView hideWithAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
