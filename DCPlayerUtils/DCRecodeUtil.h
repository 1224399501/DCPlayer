//
//  DCRecodeUtil.h
//  DCPlayer
//
//  Created by DC on 2019/4/16.
//  Copyright © 2019 DC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCRecodeUtil : NSObject
+(instancetype)shareRecordUtils;

typedef void(^RecordChangeBlock)(id responseObject);
@property(nonatomic,copy)RecordChangeBlock recordChangeBlock;
typedef void(^BackResultBlock)(id responseObject);
@property(nonatomic,copy)BackResultBlock backResultBlock;

-(void)StartRecordWithAAC;
-(void)startRecordWithCAF;
- (void)stopRecord;
- (NSString *)getRecodeDataDuration:(NSData *)recodeData;
@end


