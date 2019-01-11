//
//  PRZRecordingView.m
//  VoiceRecord
//
//  Created by 雾霭天涯 on 2019/1/10.
//  Copyright © 2019 雾霭天涯. All rights reserved.
//

#import "PRZRecordingView.h"
#import <AVFoundation/AVFoundation.h>
#import "lame/lame.h"

#define kSCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define kSCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define RGB(r,g,b) RGBA(r,g,b,1.0f)

#define kSandboxPathStr [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]
#define kMp3FileName @"myRecord.mp3"
#define kCafFileName @"myRecord.caf"

@interface PRZRecordingView()<AVAudioPlayerDelegate,AVAudioRecorderDelegate,UIGestureRecognizerDelegate>
@property (nonatomic,strong) UIView *recordView;
@property (nonatomic,strong) UILabel *timeLabel;  //录音计时
@property (nonatomic,strong) NSTimer *voiceLengthTimer;  //控制录音时长显示更新
@property (weak ,nonatomic) NSTimer *volumeTimer;//音量动画更新定时器
@property (nonatomic,assign) NSInteger voiceLength;//录音计时（秒）
@property (nonatomic,copy) NSString *cafPathStr;
@property (nonatomic,copy) NSString *mp3PathStr;
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;//音频录音机
@property (nonatomic, strong) UIImageView *volumeImgView;
@end

@implementation PRZRecordingView
/**
 *存放所有的音乐播放器
 */
static NSMutableDictionary *_musices;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self initializeMethod];
    }
    return self;
}
- (void)initializeMethod
{
    [self addSubview:self.recordView];
    self.cafPathStr = [kSandboxPathStr stringByAppendingPathComponent:kCafFileName];
    self.mp3PathStr =  [kSandboxPathStr stringByAppendingPathComponent:kMp3FileName];
}

-(UIView *)recordView{
    if (_recordView == nil) {
        
        _recordView = [[UIView alloc]initWithFrame:CGRectMake((kSCREEN_WIDTH-128.5)/2.0, (kSCREEN_HEIGHT - 128.5)/2.0-80, 128.5, 128.5)];
        _recordView.backgroundColor = [UIColor whiteColor];
        
        UIImageView *leftImg = [[UIImageView alloc] initWithFrame:CGRectMake(25, 28, 39, 56.5)];
        leftImg.image = [UIImage imageNamed:@"icn_voice_gray"];
        [_recordView addSubview:leftImg];
        
        _volumeImgView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftImg.frame)+20.5, 30.5, 34, 55)];
        _volumeImgView.image = [UIImage imageNamed:@"icn_voice_1"];
        [_recordView addSubview:_volumeImgView];
        
        _noticeLabel = [[UILabel alloc]init];
        _noticeLabel.frame = CGRectMake(8, CGRectGetMaxY(leftImg.frame)+19, _recordView.frame.size.width-16, 12);
        _noticeLabel.textAlignment = NSTextAlignmentCenter;
        _noticeLabel.textColor = [UIColor greenColor];
        _noticeLabel.font = [UIFont systemFontOfSize:12];
        _noticeLabel.text = @"手指上滑，取消录音";
        [_recordView addSubview:_noticeLabel];
        
    }
    return _recordView;
}
-(UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc]init];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:42];
        _timeLabel.text = @"00:00";
        _timeLabel.textColor = RGB(215, 155, 252);
    }
    return _timeLabel;
}
- (void)changeRecordTime
{
    self.voiceLength += 1;
    NSInteger min = self.voiceLength/60;
    NSInteger sec = self.voiceLength - min * 60;
    self.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",min,sec];
}
#pragma mark - 删除当前录音
- (void)deleteCurrentRecord
{
    [self stopPlayRecord];
    [self deleteOldRecordFile];
    self.timeLabel.text = @"00:00";
}
- (void)playRecordWithUrl:(NSString *)aurl
{
    NSURL *url = [[NSURL alloc]initWithString:aurl];
    NSData * audioData = [NSData dataWithContentsOfURL:url];
    //将数据保存到本地指定位置
    static NSInteger originalCount = 2;
    originalCount ++;
    NSString *docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/temp%ld.mp3", docDirPath ,originalCount];
    NSString *oldVoicefilePath = [NSString stringWithFormat:@"%@/temp%ld.mp3", docDirPath ,originalCount-1];
    if (originalCount >= 50)
    {
        originalCount = 2;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:oldVoicefilePath])
    {
        NSError *error = nil;
        BOOL removeSuccess = [fileManager removeItemAtPath:oldVoicefilePath error:&error];
        if (removeSuccess)
        {
            NSLog(@"删除成功");
        }
    }

    if (audioData == nil)
    {
        [self showHintText:@"语音地址无效"];
        return;
    }else
    {
        [audioData writeToFile:filePath atomically:YES];
        [self playRecordWithLocalUrlStr:filePath];
    }
}

- (void)showHintText:(NSString *)error
{
    if (self.showHintBlock) {
        self.showHintBlock(error);
    }
}

#pragma mark - 录音方法
- (void)startRecordNotice{

    self.noticeLabel.text = @"手指上滑，取消录音";
    [self stopMusicWithUrl:[NSURL URLWithString:self.cafPathStr]];

    if(self.animationBlock){
        self.animationBlock(NO);
    }
    
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
    }
    
    //NSLog(@"----------开始录音----------");
    [self deleteOldRecordFile];
    //如果不删掉，会在原文件基础上录制；虽然不会播放原来的声音，但是音频长度会是录制的最大长度。
    
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

    if (![self.audioRecorder isRecording]) {
        //0--停止、暂停，1-录制中
        [self.audioRecorder record];//首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
        self.voiceLength = 0;
        NSTimeInterval timeInterval =1 ; //0.1s
        self.voiceLengthTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval  target:self selector:@selector(changeRecordTime)  userInfo:nil  repeats:YES];
        self.volumeTimer=[NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
        [self.voiceLengthTimer fire];
    }
}


- (void)stopRecordNotice
{
    [self.audioRecorder stop];
    [self.voiceLengthTimer invalidate];
    [self.volumeTimer invalidate];
    self.voiceLengthTimer = nil;
    self.volumeTimer = nil;
    
    [self setPlayImgSubView];
    [self audio_PCMtoMP3];
    
    //计算文件大小
//    long long fileSize = [self fileSizeAtPath:self.mp3PathStr]/1024.0;
//    NSString *fileSizeStr = [NSString stringWithFormat:@"%lld",fileSize];
    self.timeLabel.text = @"00:00";
    NSDictionary *recordDic = @{@"mp3UrlStr":self.mp3PathStr,
                                @"cafPathStr":self.cafPathStr,
                                @"length":@(self.voiceLength)
                                };
    if (self.endRecordBlock) {
        self.endRecordBlock(recordDic);
    }
    //NSLog(@"timer isValid:%d",self.voiceLengthTimer.isValid);
    //    NSLog(@"mp3PathStr:%@",self.mp3PathStr);
    //NSLog(@"countNum %ld , fileSizeStr : %@",self.voiceLength,fileSizeStr);
}

#pragma mark - 播放
- (void)playRecord
{
    [self stopAllMusic];
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];  //此处需要恢复设置回放标志，否则会导致其它播放声音也会变小
    [self playMusicWithUrl:[NSURL URLWithString:self.cafPathStr]];
    if(self.animationBlock){
        self.animationBlock(YES);
    }
}

- (void)playRecordWithLocalUrlStr:(NSString *)url
{
    [self stopAllMusic];
    self.cafPathStr = url;
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];  //此处需要恢复设置回放标志，否则会导致其它播放声音也会变小
    [self playMusicWithUrl:[NSURL URLWithString:url]];
    if(self.animationBlock){
        self.animationBlock(YES);
    }
}

- (void)stopPlayRecord
{
    [self stopMusicWithUrl:[NSURL URLWithString:self.cafPathStr]];
    if(self.animationBlock){
        self.animationBlock(NO);
    }
}
- (void)cancelRecordMethod
{
    [self.audioRecorder stop];
    [self.voiceLengthTimer invalidate];
    [self.volumeTimer invalidate];
    self.voiceLengthTimer = nil;
    self.volumeTimer = nil;
}
- (void)setPlayImgSubView
{
    if (self.showVoiceLengthBlock) {
        self.showVoiceLengthBlock();
    }
}
-(void)deleteOldRecordFile{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:self.cafPathStr];
    if (!blHave) {
        NSLog(@"不存在");
        return ;
    }else {
        NSLog(@"存在");
        BOOL blDele= [fileManager removeItemAtPath:self.cafPathStr error:nil];
        if (blDele) {
            NSLog(@"删除成功");
        }else {
            NSLog(@"删除失败");
        }
    }
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //NSLog(@"----------------播放完毕--------");
    if(self.animationBlock){
        self.animationBlock(NO);
    }
    [self setPlayImgSubView];
}

#pragma mark - caf转mp3
- (void)audio_PCMtoMP3
{
    @try {
        int read, write;
        FILE *pcm = fopen([self.cafPathStr cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([self.mp3PathStr cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        lame_t lame = lame_init();
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_VBR(lame, vbr_default);
        lame_init_params(lame);
        do {
            read = fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSLog(@"MP3生成成功: %@",self.mp3PathStr);
    }
    
}
/**
 *  获得录音机对象
 *
 *  @return 录音机对象
 */
-(AVAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
        //创建录音文件保存路径
        NSURL *url=[NSURL URLWithString:self.cafPathStr];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}


#pragma mark - AudioPlayer方法
/**
 *播放音乐文件
 */
- (BOOL)playMusicWithUrl:(NSURL *)fileUrl
{
    //其他播放器停止播放
    [self stopAllMusic];
    
    if (!fileUrl) return NO;
    
    AVAudioSession *session=[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];  //此处需要恢复设置回放标志，否则会导致其它播放声音也会变小
    [session setActive:YES error:nil];
    
    AVAudioPlayer *player=[self musices][fileUrl];
    
    if (!player) {
        //2.2创建播放器
        player=[[AVAudioPlayer alloc]initWithContentsOfURL:fileUrl error:nil];
    }
    
    player.delegate = self;
    
    if (![player prepareToPlay]){
        NSLog(@"缓冲失败--");
        //        [self myToast:@"播放器缓冲失败"];
        return NO;
    }
    
    [player play];
    
    //2.4存入字典
    [self musices][fileUrl]=player;
    //NSLog(@"musices:%@ musices",self.musices);
    return YES;//正在播放，那么就返回YES
}
/**
 *停止播放音乐文件
 */
- (void)stopMusicWithUrl:(NSURL *)fileUrl{
    if (!fileUrl) return;//如果没有传入文件名，那么就直接返回
    
    //1.取出对应的播放器
    AVAudioPlayer *player=[self musices][fileUrl];
    
    //2.停止
    if ([player isPlaying]) {
        [player stop];
        NSLog(@"播放结束:%@--------",fileUrl);
    }
    
    if ([[self musices].allKeys containsObject:fileUrl]) {
        [[self musices] removeObjectForKey:fileUrl];
    }
}

- (BOOL)isPlayingWithUniqueID:(NSString *)uniqueID
{
    if ([[self musices].allKeys containsObject:uniqueID]) {
        AVAudioPlayer *player=[self musices][uniqueID];
        return [player isPlaying];
    }else{
        return NO;
    }
    
}
- (void)stopAllMusic
{
    if ([self musices].allKeys.count > 0) {
        for ( NSString *playID in [self musices].allKeys) {
            AVAudioPlayer *player=[self musices][playID];
            [player stop];
        }
    }
}
- (NSMutableDictionary *)musices
{
    if (_musices==nil) {
        _musices=[NSMutableDictionary dictionary];
    }
    return _musices;
}
/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
-(NSDictionary *)getAudioSetting{
    //LinearPCM 是iOS的一种无损编码格式,但是体积较为庞大
    //录音设置
    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    //录音格式 无法使用
    [recordSettings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey: AVFormatIDKey];
    //采样率
    [recordSettings setValue :[NSNumber numberWithFloat:11025.0] forKey: AVSampleRateKey];//44100.0
    //通道数
    [recordSettings setValue :[NSNumber numberWithInt:2] forKey: AVNumberOfChannelsKey];
    //线性采样位数
    //[recordSettings setValue :[NSNumber numberWithInt:16] forKey: AVLinearPCMBitDepthKey];
    //音频质量,采样质量
    [recordSettings setValue:[NSNumber numberWithInt:AVAudioQualityMin] forKey:AVEncoderAudioQualityKey];
    
    return recordSettings;
}

#pragma mark - 文件转换
// 二进制文件转为base64的字符串
- (NSString *)Base64StrWithMp3Data:(NSData *)data{
    if (!data) {
        NSLog(@"Mp3Data 不能为空");
        return nil;
    }
    //    NSString *str = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *str = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return str;
}

// base64的字符串转化为二进制文件
- (NSData *)Mp3DataWithBase64Str:(NSString *)str{
    if (str.length ==0) {
//        NSLog(@"Mp3DataWithBase64Str:Base64Str 不能为空");
        return nil;
    }
    NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
//    NSLog(@"Mp3DataWithBase64Str:转换成功");
    return data;
}

//单个文件的大小
- (long long) fileSizeAtPath:(NSString*)filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }else{
        //NSLog(@"计算文件大小：文件不存在");
    }
    return 0;
}


- (BOOL)isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

/**
 *  录音声波状态设置
 */
-(void)audioPowerChange{
    [self.audioRecorder updateMeters];//更新测量值
    float power= [self.audioRecorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围时-160到0
    //NSLog(@"分贝值--%@",@(power));
    power = [self customDBRange:power];
    
    NSString *imgStr = @"";
    if (power>=0 && power < 20)
    {
        imgStr = @"icn_voice_1";
    }else if (power>=20 && power < 40)
    {
        imgStr = @"icn_voice_2";
    }else if (power>=40 && power < 60)
    {
        imgStr = @"icn_voice_3";
    }else if (power>=60 && power < 80)
    {
        imgStr = @"icn_voice_4";
    }else if (power>=80 && power <= 100)
    {
        imgStr = @"icn_voice_5";
    }
    _volumeImgView.image = [UIImage imageNamed:imgStr];
}

- (CGFloat)customDBRange:(CGFloat )originalNum
{
    //比如把-60作为最低分贝
    float minValue = -60;
    //把60作为获取分配的范围
    float range = 60;
    //把100作为输出分贝范围
    float outRange = 100;
    //确保在最小值范围内
    if (originalNum < minValue)
    {
        originalNum = minValue;
    }
    
    //计算显示分贝
    float decibels = (originalNum + range) / range * outRange;
    return decibels;
}

@end
