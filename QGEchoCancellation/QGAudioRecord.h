//
//  QGAudioRecord.h
//  QGAudioRecord
//
//  Created by Hanxiaojie on 2018/6/25.
//  Copyright © 2018年 徐其岗. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class QGAudioRecord;
@protocol QGAudioRecordDelegate <NSObject>

- (void)audioRecord:(QGAudioRecord*)AudioRecord recordCallBack:(AudioBufferList*)bufferList;
- (void)audioPlayer:(QGAudioRecord*)AudioRecord playCallBack:(AudioBufferList*)bufferList inNumberFrames:(UInt32)inNumberFrames;

@end

@interface QGAudioRecord : NSObject

@property (nonatomic, weak) id<QGAudioRecordDelegate> delegate;

+ (instancetype)shareManager;

//- (void)startRecord;
//- (void)stopRecord;
//- (void)startPlay;
//- (void)stopPlay;
- (void)start;
- (void)stop;
- (void)invalid;

@end
