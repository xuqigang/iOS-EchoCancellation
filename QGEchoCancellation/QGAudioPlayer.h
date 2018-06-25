//
//  QGAudioPlayer.h
//  QGEchoCancellation
//
//  Created by Hanxiaojie on 2018/6/25.
//  Copyright © 2018年 徐其岗. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class QGAudioPlayer;
@protocol QGAudioPlayerDelegate <NSObject>

- (void)audioPlayer:(QGAudioPlayer*)audioPlayer playCallBack:(AudioBufferList*)bufferList inNumberFrames:(UInt32)inNumberFrames;

@end

@interface QGAudioPlayer : NSObject

@property (nonatomic, weak) id<QGAudioPlayerDelegate> delegate;

+ (instancetype)shareManager;

- (void)startPlay;
- (void)stopPlay;

- (void)invalid;

@end

