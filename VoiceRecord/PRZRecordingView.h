//
//  PRZRecordingView.h
//  VoiceRecord
//
//  Created by 雾霭天涯 on 2019/1/10.
//  Copyright © 2019 雾霭天涯. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PRZRecordingView : UIView
@property (nonatomic,strong)UILabel *noticeLabel;
@property (nonatomic,strong) void(^endRecordBlock)(NSDictionary* recordDic);
@property (nonatomic,strong) void(^animationBlock)(BOOL startOrStopAnimation);
@property (nonatomic,strong) void(^showVoiceLengthBlock)(void);
@property (nonatomic,strong) void(^showHintBlock)(NSString* string);//显示提示信息

- (void)startRecordNotice;
- (void)stopRecordNotice;
//播放本地语音
- (void)playRecordWithLocalUrlStr:(NSString *)url;
//播放在线语音
- (void)playRecordWithUrl:(NSString *)aurl;
- (void)cancelRecordMethod;
- (void)stopPlayRecord;
@end

