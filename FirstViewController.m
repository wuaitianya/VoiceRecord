//
//  FirstViewController.m
//  VoiceRecord
//
//  Created by 雾霭天涯 on 2019/1/10.
//  Copyright © 2019 雾霭天涯. All rights reserved.
//  使用示例工程  使用时导入两个头文件即可， 具体用法参考本页面

#import "FirstViewController.h"
#import "PRZRecordingView.h"
#import "AddVoiceImageView.h"
@interface FirstViewController ()
@property (nonatomic,strong) PRZRecordingView* recordingView;
@property (nonatomic,strong) AddVoiceImageView* actionView;
@property (nonatomic,strong) NSString* voiceLength;
@property (nonatomic,copy) NSString* playVoiceUrlStr;
@property (nonatomic,copy) NSString* commitVoiceMP3UrlStr;
@property (nonatomic,assign) BOOL isCancelRecord;
@property (nonatomic,assign) BOOL lastHandleIsCancel;
@end

@implementation FirstViewController

- (PRZRecordingView*)recordingView{
    if (_recordingView == nil) {
        _recordingView = [[PRZRecordingView alloc] initWithFrame:CGRectMake(0, 0, 200, 400)];
    }
    return _recordingView;
}
- (AddVoiceImageView*)actionView{
    if (_actionView == nil) {
        _actionView = [[AddVoiceImageView alloc] initWithFrame:CGRectMake(10, 220, 120, 30)];
        _actionView.backgroundColor = [UIColor orangeColor];
    }
    return _actionView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    _isCancelRecord = NO;
    _lastHandleIsCancel = NO;

    [self.view addSubview:self.actionView];
    
    __weak typeof(self)weakSelf = self;
    
    self.actionView.longPressBeginBlock = ^{
        weakSelf.lastHandleIsCancel = NO;
        [weakSelf.view addSubview:weakSelf.recordingView];
        [weakSelf.recordingView startRecordNotice];
    };
    
    self.actionView.longPressEndBlock = ^{
        if (weakSelf.isCancelRecord == YES)
        {
            weakSelf.lastHandleIsCancel = YES;
            weakSelf.isCancelRecord = NO;
            [weakSelf.recordingView cancelRecordMethod];
            
            weakSelf.actionView.image = [UIImage imageNamed:@"btn_normal"];
            weakSelf.actionView.voiceImg.hidden = YES;
            weakSelf.actionView.lengthLbl.hidden = YES;
        }else
        {
            [weakSelf.recordingView stopRecordNotice];
        }
        
        [weakSelf.recordingView removeFromSuperview];
    };
    
    self.actionView.playVoiceBlock = ^{
        if (weakSelf.lastHandleIsCancel){
            return;
        }
        
        if (weakSelf.playVoiceUrlStr.length > 0)
        {
            [weakSelf.recordingView playRecordWithLocalUrlStr:weakSelf.playVoiceUrlStr];
        }else{
            NSLog(@"语音地址不存在");
        }
    };
    
    self.actionView.cancelRecordBlock = ^{
        weakSelf.recordingView.noticeLabel.text = @"取消录音";
        weakSelf.isCancelRecord = YES;
    };
    

    
   
    
    self.recordingView.showVoiceLengthBlock = ^{
        [weakSelf.actionView showVoiceLengthMethod];
    };
    
    self.recordingView.animationBlock = ^(BOOL startOrStopAnimation) {
        [weakSelf.actionView startOrStopAnimation:startOrStopAnimation];
    };
    
    self.recordingView.endRecordBlock = ^(NSDictionary *recordDic) {
        weakSelf.playVoiceUrlStr = recordDic[@"cafPathStr"];
        weakSelf.commitVoiceMP3UrlStr = recordDic[@"mp3UrlStr"];
        
        weakSelf.actionView.voiceImg.image = [UIImage imageNamed:@"icn_three"];
        weakSelf.voiceLength = [NSString stringWithFormat:@"%@",recordDic[@"length"]];
        weakSelf.actionView.lengthLbl.text = [NSString stringWithFormat:@"%@\"",recordDic[@"length"]];
    };
    
    self.recordingView.showHintBlock = ^(NSString *string) {
        NSLog(@"%@",string);
    };
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.recordingView stopPlayRecord];
    [super viewWillDisappear:animated];
}
- (void)viewDidDisappear:(BOOL)animated{
    _isCancelRecord = NO;
    [super viewDidDisappear:animated];
}

- (void)commitVoiceMethod
{
    if (_lastHandleIsCancel == NO && _commitVoiceMP3UrlStr.length > 0){
        NSData *voiceData = [NSData dataWithContentsOfFile:_commitVoiceMP3UrlStr];
    }
}


@end
