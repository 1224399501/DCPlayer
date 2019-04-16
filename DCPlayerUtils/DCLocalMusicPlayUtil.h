//
//  DCLocalMusicPlayUtil.h
//  DCPlayer
//
//  Created by DC on 2019/4/15.
//  Copyright © 2019 DC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DCLocalMusicPlayUtil : NSObject
+(instancetype)LocalMusicPlayUtil;
-(BOOL)PlayWithMusicName:(NSString *)musicName;
-(void)setPlayCurretnTime:(float)currentTime;
-(void)setPlayvolume:(float)volume;
-(void)play;
-(void)pause;
-(float)getCurrentTime;
@end

NS_ASSUME_NONNULL_END
