//
//  DCRecodeUtil.m
//  DCPlayer
//
//  Created by DC on 2019/4/16.
//  Copyright © 2019 DC. All rights reserved.
//

#import "DCRecodeUtil.h"
#import <AVFoundation/AVFoundation.h>
#define kSandboxPathStr [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]

#define kAACFileName @"AACRecord.aac"
#define kCafFileName @"CAFRecord.caf"
@interface DCRecodeUtil ()<AVAudioRecorderDelegate>{
    NSString *_PathStr;
    NSTimer  *_levelTimer;
}
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;//音频录音机
@end
@implementation DCRecodeUtil
#pragma amrk--构造方法
+(instancetype)shareRecordUtils{
    static DCRecodeUtil *sharedRecordUtils;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        if (!sharedRecordUtils) {
            sharedRecordUtils = [[self alloc] init];
            [sharedRecordUtils initData];
        }
        
    });
    return sharedRecordUtils;
}
-(void)initData{
   
    _levelTimer= [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(levelTimerCallback:) userInfo: nil repeats: YES];
    _levelTimer.fireDate= [NSDate distantFuture];
}
#pragma mark--接口方法
#pragma mark--开始录音
-(void)StartRecordWithAAC{
     _PathStr = [kSandboxPathStr stringByAppendingPathComponent:kAACFileName];
    [self startRecord];
}
-(void)startRecordWithCAF{
     _PathStr = [kSandboxPathStr stringByAppendingPathComponent:kCafFileName];
    [self startRecord];
}
#pragma mark--结束录音
- (void)stopRecord
{
    _levelTimer.fireDate= [NSDate distantFuture];
    [_audioRecorder stop];
}
#pragma mark--获取音频时长
- (NSString *)getRecodeDataDuration:(NSData *)recodeData{
    if (!recodeData||![recodeData isKindOfClass:[NSData class]]) {
        return @"0";
    }
    NSError *error = nil;
    AVAudioPlayer *tempPlayer = [[AVAudioPlayer alloc]initWithData:recodeData error:&error];
    NSString *durationStr = [NSString stringWithFormat:@"%f",tempPlayer.duration];
    
    //    NSLog(@"durationStr : %@ ,duration : %d ,error : %@ ",durationStr,duration,error);
    return durationStr;
}
#pragma mark--私有方法
#pragma mark--开始真正的录音
- (void)startRecord{
  
    if ([_audioRecorder isRecording]) {
        [_audioRecorder stop];
    }
     _audioRecorder=nil;
    [self deleteOldRecordFile];  //如果不删掉，会在原文件基础上录制；虽然不会播放原来的声音，但是音频长度会是录制的最大长度。
   
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    [self.audioRecorder record];//首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
    _levelTimer.fireDate= [NSDate date];
    
}
#pragma mark--监听音量变化
/* 该方法确实会随环境音量变化而变化，但具体分贝值是否准确暂时没有研究 */
- (void)levelTimerCallback:(NSTimer *)timer {
    [_audioRecorder updateMeters];
    float   level;                // The linear 0.0 .. 1.0 value we need.
    float   minDecibels = -80.0f; // Or use -60dB, which I measured in a silent room.
    float   decibels    = [_audioRecorder averagePowerForChannel:0];
    
    if (decibels < minDecibels)
    {
        level = 0.0f;
    }
    else if (decibels >= 0.0f)
    {
        level = 1.0f;
    }
    else
    {
        float   root            = 2.0f;
        float   minAmp          = powf(10.0f, 0.05f * minDecibels);
        float   inverseAmpRange = 1.0f / (1.0f - minAmp);
        float   amp             = powf(10.0f, 0.05f * decibels);
        float   adjAmp          = (amp - minAmp) * inverseAmpRange;
        
        level = powf(adjAmp, 1.0f / root);
    }
    if (_recordChangeBlock) {
        
        _recordChangeBlock([NSString stringWithFormat:@"%f",level*7]);
    }
    NSLog(@"level%f",level*7);
}
#pragma mark--删除旧的录音文件
-(void)deleteOldRecordFile{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:_PathStr];
    if (!blHave) {
        
        return ;
    }else {
        
        BOOL blDele= [fileManager removeItemAtPath:_PathStr error:nil];
        if (blDele) {
            //            NSLog(@"删除成功");
        }else {
            NSLog(@"删除失败");
        }
    }
}


#pragma mark--AVAudioRecorderDelegate
//  结束录音 代理方法
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (flag) {
        
        NSData *data = [NSData dataWithContentsOfFile:_PathStr];
        if (_backResultBlock) {
            NSString *durationStr;
            
            durationStr=[self getRecodeDataDuration:data];
            NSMutableDictionary *dic=[NSMutableDictionary dictionary];
            [dic setValue:durationStr forKey:@"duration"];
            [dic setValue:data forKey:@"data"];
            
            _backResultBlock(dic);
            
        }
    }
    //    otherAudioPlaying 当然，也可以通过otherAudioPlaying变量来提前判断当前是否有其他App在播放音频。
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
  
}

#pragma mark -  Getter
-(AVAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
        //创建录音文件保存路径
        NSURL *url=[NSURL URLWithString:_PathStr];
        //创建录音格式设置
        NSDictionary *setting;
        if ([_PathStr.lastPathComponent isEqualToString:kAACFileName]) {
            setting=[self audioRecordSettingsWithAAC];
        }else{
            setting=[self audioRecordSettingsWithCAF];
        }
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
/**
 *  取得录音文件设置
 */
-(NSDictionary *)audioRecordSettingsWithCAF{
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
- (NSDictionary *)audioRecordSettingsWithAAC{
    
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              
                              [NSNumber numberWithFloat:44100.0],AVSampleRateKey ,    //采样率 8000/44100/96000
                              
                              [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,  //录音格式
                              
                              [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,   //线性采样位数  8、16、24、32
                              
                              [NSNumber numberWithInt:2],AVNumberOfChannelsKey,      //声道 1，2
                              
                              [NSNumber numberWithInt:AVAudioQualityLow],AVEncoderAudioQualityKey, //录音质量
                              
                              nil];
    return (settings);
}
@end
