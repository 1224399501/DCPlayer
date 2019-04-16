//
//  DCLocalMusicPlayUtil.m
//  DCPlayer
//
//  Created by DC on 2019/4/15.
//  Copyright © 2019 DC. All rights reserved.
//

#import "DCLocalMusicPlayUtil.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
@interface DCLocalMusicPlayUtil () <AVAudioPlayerDelegate> {
    
}

@property (nonatomic, strong) AVAudioPlayer *audioPlayer; /**< 音频播放器 */
@end

@implementation DCLocalMusicPlayUtil
+(instancetype)LocalMusicPlayUtil{
    static DCLocalMusicPlayUtil *localMusicPlayUtil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if (!localMusicPlayUtil) {
            localMusicPlayUtil=[[DCLocalMusicPlayUtil alloc]init];
        }
    });
    return localMusicPlayUtil;
}
-(BOOL)PlayWithMusicName:(NSString *)musicName{
    // 异常处理
    if (!musicName || musicName.length == 0) {
        return NO;
    }
    
    NSError *error = nil;
    
    // 获取音乐本地路径
    NSString *path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:musicName];
    
    // 获取音乐本地资源地址
    NSURL *url = [NSURL fileURLWithPath:path];
    
    // 初始化音频播放器
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    
    if (error) {
        NSLog(@"%@",error.localizedDescription);
        return NO;
        
    }else{
        // 初始化成功
        
        // 1、准备播放
       BOOL prepareToPlay=[_audioPlayer prepareToPlay];
        NSLog(@"prepareToPlay:%d",prepareToPlay);
        _audioPlayer.volume=0.5;
      BOOL play= [_audioPlayer play];
         NSLog(@"play:%d",play);
        
        // 3、打印音频播放持续总时间
        NSLog(@"%.lf", _audioPlayer.duration);
        
        // 5、设置代理
        _audioPlayer.delegate = self;
        // 获取路径
        NSString *path = [[NSBundle mainBundle] pathForAuxiliaryExecutable:musicName];
        
        // 根据路径创建URL地址
        NSURL *url = [NSURL fileURLWithPath:path];
        
        // 初始化AVURLAsset
        AVURLAsset *mp3Asset = [AVURLAsset URLAssetWithURL:url options:nil];
        
        // 遍历有效元数据格式
        for (NSString *format in [mp3Asset availableMetadataFormats]) {
            
            NSMutableString *musicInfo = [NSMutableString string];
            
            // 根据数据格式获取AVMetadataItem（数据成员）
            for (AVMetadataItem *metadataItem in [mp3Asset metadataForFormat:format]) {
                
                // NSLog(@"metadataItem = %@", metadataItem);
                
                
                // 获取专辑图片commonKey：AVMetadataCommonKeyArtwork
                if ([metadataItem.commonKey isEqualToString:AVMetadataCommonKeyArtwork]) {
                    UIImage *image = [UIImage imageWithData:(NSData *)metadataItem.value];
                    NSLog(@"%@",image);
                    
                }
                // 获取音乐名字commonKey：AVMetadataCommonKeyTitle
                else if([metadataItem.commonKey isEqualToString:AVMetadataCommonKeyTitle]){
                    [musicInfo insertString:[NSString stringWithFormat:@"%@-", (NSString *)metadataItem.value] atIndex:0];
                }
                // 获取艺术家（歌手）名字commonKey：AVMetadataCommonKeyArtist
                else if ([metadataItem.commonKey isEqual:AVMetadataCommonKeyArtist]){
                    [musicInfo appendString:(NSString *)metadataItem.value];
                }
            }
            NSLog(@"%@",musicInfo);
            
        }
        
        
    }
    return YES;
}

-(void)setPlayCurretnTime:(float)currentTime{
    _audioPlayer.currentTime = currentTime;
}
-(void)setPlayvolume:(float)volume{
      _audioPlayer.volume=volume;
    
}
-(void)play{
    [_audioPlayer play];
}
-(void)pause{
    [_audioPlayer pause];
}
-(float)getCurrentTime{

    return  _audioPlayer.currentTime;
}
#pragma mark - <AVAudioPlayerDelegate>

// 播放完一首歌直接调用
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  
}

/**
 AVAudioPlayer是属于 AVFundation.framework 的一个类，它的功能类似于一个功能强大的播放器，AVAudioPlayer每次播放都需要将上一个player对象释放掉，然后重新创建一个player来进行播放,AVAudioPlayer 支持广泛的音频格式，主要是以下这些格式。
 ACC
 AMR(Adaptive multi-Rate，一种语音格式)
 ALAC (Apple lossless Audio Codec)
 iLBC (internet Low Bitrate Codec，另一种语音格式)
 IMA4 (IMA/ADPCM)
 linearPCM (uncompressed)
 u-law 和 a-law
 MP3 (MPEG-Laudio Layer 3)
 */
/**
 Category
 是否允许音频播放/录音
 是否打断其他不支持混音APP
 是否会被静音键或锁屏键静音
 
 
 
 
 AVAudioSessionCategoryAmbient
 只支持播放
 否
 是
 
 
 AVAudioSessionCategoryAudioProcessing
 不支持播放，不支持录制
 是
 否
 
 
 AVAudioSessionCategoryMultiRoute
 支持播放，支持录制
 是
 否
 
 
 AVAudioSessionCategoryPlayAndRecord
 支持播放，支持录制
 默认YES，可以重写为NO
 否
 
 
 AVAudioSessionCategoryPlayback
 只支持播放
 默认YES，可以重写为NO
 否
 
 
 AVAudioSessionCategoryRecord
 只支持录制
 是
 否（锁屏下仍可录制）
 
 
 AVAudioSessionCategorySoloAmbient
 只支持播放
 是
 是
 
 作者：安东_Ace
 链接：https://www.jianshu.com/p/fb0e5fb71b3c
 来源：简书
 简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。
 
 
 可以看到，其实默认的就是“AVAudioSessionCategorySoloAmbient”类别。从表中我们可以总结如下：
 
 AVAudioSessionCategoryAmbient ： 只用于播放音乐时，并且可以和QQ音乐同时播放，比如玩游戏的时候还想听QQ音乐的歌，那么把游戏播放背景音就设置成这种类别。同时，当用户锁屏或者静音时也会随着静音，这种类别基本使用所有App的背景场景。
 AVAudioSessionCategorySoloAmbient： 也是只用于播放,但是和"AVAudioSessionCategoryAmbient"不同的是，用了它就别想听QQ音乐了，比如不希望QQ音乐干扰的App，类似节奏大师。同样当用户锁屏或者静音时也会随着静音，锁屏了就玩不了节奏大师了。
 AVAudioSessionCategoryPlayback： 如果锁屏了还想听声音怎么办？用这个类别，比如App本身就是播放器，同时当App播放时，其他类似QQ音乐就不能播放了。所以这种类别一般用于播放器类App
 AVAudioSessionCategoryRecord： 有了播放器，肯定要录音机，比如微信语音的录制，就要用到这个类别，既然要安静的录音，肯定不希望有QQ音乐了，所以其他播放声音会中断。想想微信语音的场景，就知道什么时候用他了。
 AVAudioSessionCategoryPlayAndRecord： 如果既想播放又想录制该用什么模式呢？比如VoIP，打电话这种场景，PlayAndRecord就是专门为这样的场景设计的 。
 AVAudioSessionCategoryMultiRoute： 想象一个DJ用的App，手机连着HDMI到扬声器播放当前的音乐，然后耳机里面播放下一曲，这种常人不理解的场景，这个类别可以支持多个设备输入输出。
 AVAudioSessionCategoryAudioProcessing: 主要用于音频格式处理，一般可以配合AudioUnit进行使用
 
 */
@end
