//
//  AddVoiceImageView.h
//  VoiceRecord
//
//  Created by 雾霭天涯 on 2019/1/10.
//  Copyright © 2019 雾霭天涯. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AddVoiceImageView : UIImageView
@property (nonatomic,strong)UIImageView* voiceImg;
@property (nonatomic,strong)UILabel* lengthLbl;
@property (nonatomic,strong) void(^longPressBeginBlock)(void);
@property (nonatomic,strong) void(^longPressEndBlock)(void);
@property (nonatomic,strong) void(^playVoiceBlock)(void);
@property (nonatomic,strong) void(^cancelRecordBlock)(void);

- (void)pictureChangeAnimationSetting;
- (void)startOrStopAnimation:(BOOL)start;
- (void)showVoiceLengthMethod;
@end

NS_ASSUME_NONNULL_END
