//
//  ViewController.m
//  QGAudioRecord
//
//  Created by Hanxiaojie on 2018/6/25.
//  Copyright © 2018年 徐其岗. All rights reserved.
//

#import "ViewController.h"
#import "QGAudioRecord.h"
#import "QGAudioPlayer.h"

#define subPathPCM @"/Documents/recordAudio.pcm"
#define stroePath [NSHomeDirectory() stringByAppendingString:subPathPCM]

@interface ViewController ()<QGAudioRecordDelegate,QGAudioPlayerDelegate>
{
    NSMutableArray<NSData*> *_pcmTemQueue;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _pcmTemQueue = [NSMutableArray arrayWithCapacity:10];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[QGAudioRecord shareManager] setDelegate:self];
    [[QGAudioRecord shareManager] startRecord];
    
    [[QGAudioPlayer shareManager] setDelegate:self];
    [[QGAudioPlayer shareManager] startPlay];
}
#pragma mark QGAudioRecordDelegate <NSObject>

- (void)audioRecord:(QGAudioRecord*)AudioRecord recordCallBack:(AudioBufferList*)bufferList{
    
    AudioBuffer buffer = bufferList->mBuffers[0];
    NSData *pcmBlock = [NSData dataWithBytes:buffer.mData length:buffer.mDataByteSize];
    //将pcm存储到本地
//    NSString *savePath = stroePath;
//    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath] == false)
//    {
//        [[NSFileManager defaultManager] createFileAtPath:savePath contents:nil attributes:nil];
//    }
//    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:savePath];
//    [handle seekToEndOfFile];
//    [handle writeData:pcmBlock];
    
    //将pcm 存放到临时数组中
    [_pcmTemQueue addObject:pcmBlock];
}

#pragma mark QGAudioPlayerDelegate <NSObject>

- (void)audioPlayer:(QGAudioPlayer*)audioPlayer playCallBack:(AudioBufferList*)bufferList inNumberFrames:(UInt32)inNumberFrames{
    AudioBuffer buffer = bufferList->mBuffers[0];
    
    //在这里进行音频数据的输入，PCM格式，将pcm流拷贝到buffer.mData中即可
    NSData *pcmData = [_pcmTemQueue firstObject];
    if (pcmData) {
        Byte *tempByte = (Byte *)[pcmData bytes];
        buffer.mDataByteSize = pcmData.length;
        memcpy(buffer.mData, tempByte, pcmData.length);
        [_pcmTemQueue removeObjectAtIndex:0];
    }
    

//    static long readerLength = 0;
//    NSData *dataStore = [NSData dataWithContentsOfFile:stroePath];
//
//    NSData *subData = [dataStore subdataWithRange:NSMakeRange(readerLength, buffer.mDataByteSize)];
    
//    readerLength = readerLength + buffer.mDataByteSize;
}


- (void)savePcmToLocol{
    
}

@end
