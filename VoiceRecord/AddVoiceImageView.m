//
//  AddVoiceImageView.m
//  VoiceRecord
//
//  Created by 雾霭天涯 on 2019/1/10.
//  Copyright © 2019 雾霭天涯. All rights reserved.
//

#import "AddVoiceImageView.h"
@interface AddVoiceImageView()<UIGestureRecognizerDelegate>

@end
@implementation AddVoiceImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self initializeMethod];
    }
    return self;
}
- (void)initializeMethod
{
    self.image = [UIImage imageNamed:@"btn_normal"];
    self.userInteractionEnabled = YES;
    
    UIImageView *voiceImg = [[UIImageView alloc] initWithFrame:CGRectMake(15,(self.frame.size.height-15)/2.0 , 8.9, 15)];
    voiceImg.image = [UIImage imageNamed:@"icn_three"];
    voiceImg.hidden = YES;
    voiceImg.tag = 10;
    [self addSubview:voiceImg];
    self.voiceImg = voiceImg;
    
    UILabel *lengthLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(voiceImg.frame)+20, voiceImg.frame.origin.y, 80, 15)];
    lengthLbl.text = @"0\"";
    lengthLbl.font = [UIFont systemFontOfSize:15];
    lengthLbl.textColor = [UIColor blackColor];
    self.lengthLbl = lengthLbl;
    lengthLbl.tag = 11;
    lengthLbl.hidden = YES;
    [self addSubview:lengthLbl];
    
    [self addGestureMethod];
    [self pictureChangeAnimationSetting];
}
#pragma mark - 给语音图片添加：长按录音，点击播放的手势
- (void)addGestureMethod
{
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableviewCellLongPressed:)];
    longPress.delegate = self;
    longPress.minimumPressDuration = 0.7;
    [self addGestureRecognizer:longPress];
    
    UITapGestureRecognizer *playTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playVoiceMehtod:)];
    [self addGestureRecognizer:playTapGesture];
    
    UIPanGestureRecognizer *cancelRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCancelRecognizer:)];
    [self addGestureRecognizer:cancelRecognizer];
}
//长按事件的实现方法
- (void) handleTableviewCellLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state ==  UIGestureRecognizerStateBegan) {
        
        if (self.longPressBeginBlock) {
            self.longPressBeginBlock();
        }
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
         [self performSelector:@selector(longPressIsEnd) withObject:nil afterDelay:0.01];
    }
    
}
- (void)longPressIsEnd
{
    if (self.longPressEndBlock) {
        self.longPressEndBlock();
    }
}
#pragma mark - 播放语音
- (void)playVoiceMehtod:(UITapGestureRecognizer *)singleTap
{
    if (self.playVoiceBlock) {
        self.playVoiceBlock();
    }
}
#pragma mark - 上滑取消
- (void)handleCancelRecognizer:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self];
    
    if (translation.y<-20)
    {
        if (self.cancelRecordBlock) {
            self.cancelRecordBlock();
        }
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]
        && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
    {
        return YES;
    }
    else
    {
        return  NO;
    }
}
#pragma mark - 动画效果
- (void)pictureChangeAnimationSetting
{
    NSArray *picArray = @[[UIImage imageNamed:@"icn_one"],
                          [UIImage imageNamed:@"icn_two"],
                          [UIImage imageNamed:@"icn_three"]];
    UIImageView *img = [self viewWithTag:10];
    //imageView的动画图片是数组images
    img.animationImages = picArray;
    //按照原始比例缩放图片，保持纵横比
    img.contentMode = UIViewContentModeScaleAspectFit;
    //切换动作的时间3秒，来控制图像显示的速度有多快，
    img.animationDuration = 1;
    //动画的重复次数，想让它无限循环就赋成0
    img.animationRepeatCount = 0;
}
- (void)startOrStopAnimation:(BOOL)start{
    if (start) {
        [self.voiceImg startAnimating];
    }else{
        [self.voiceImg.layer removeAllAnimations];
    }
}
- (void)showVoiceLengthMethod
{
    self.image = [UIImage imageNamed:@"btn_dialogue"];
    self.voiceImg.hidden = NO;
    self.lengthLbl.hidden = NO;
}
@end
