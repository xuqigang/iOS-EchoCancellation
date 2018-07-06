//
//  ViewController.m
//  QGAudioRecord
//
//  Created by Hanxiaojie on 2018/6/25.
//  Copyright © 2018年 徐其岗. All rights reserved.
//

#import "ViewController.h"
#import "QGAudioRecord.h"

#define subPathPCM @"/Documents/recordAudio.pcm"
#define stroePath [NSHomeDirectory() stringByAppendingString:subPathPCM]
@interface A : NSObject
@property (nonatomic, assign) AudioBuffer buffer;
@end
@implementation A

@end
@interface ViewController ()<QGAudioRecordDelegate>
{
    NSMutableArray<A *> *_pcmTemQueue;
}

@end

@implementation ViewController
UInt32 _readerLength;
- (void)viewDidLoad {
    [super viewDidLoad];
    _pcmTemQueue = [NSMutableArray arrayWithCapacity:10];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self delete];
    [[QGAudioRecord shareManager] setDelegate:self];
    
    
//    [[QGAudioPlayer shareManager] setDelegate:self];
   
}
#pragma mark QGAudioRecordDelegate <NSObject>

- (void)audioRecord:(QGAudioRecord*)AudioRecord recordCallBack:(AudioBufferList*)bufferList{
    
    
//    A *a = [A new];
//    a.buffer = bufferList->mBuffers[0];
    //将pcm存储到本地
    NSString *savePath = stroePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:savePath] == false)
    {
        [[NSFileManager defaultManager] createFileAtPath:savePath contents:nil attributes:nil];
    }
    NSFileHandle * handle = [NSFileHandle fileHandleForWritingAtPath:savePath];
    [handle seekToEndOfFile];
    AudioBuffer buffer = bufferList->mBuffers[0];
    NSData *pcmBlock =[NSData dataWithBytes:buffer.mData length:buffer.mDataByteSize];
    [handle writeData:pcmBlock];
    
    //将pcm 存放到临时数组中
//    [_pcmTemQueue addObject:a];
}

#pragma mark QGAudioPlayerDelegate <NSObject>
- (void)audioPlayer:(QGAudioRecord*)AudioRecord playCallBack:(AudioBufferList*)bufferList inNumberFrames:(UInt32)inNumberFrames{
    
    static NSInteger count = 0;
    if (count > 20) {
        AudioBuffer buffer = bufferList->mBuffers[0];
        char data[buffer.mDataByteSize];
        int len = readData(data, buffer.mDataByteSize);
        memcpy(buffer.mData, data, len);
        buffer.mDataByteSize = len;
        
    } else {
        count ++;
    }
    
    
    //在这里进行音频数据的输入，PCM格式，将pcm流拷贝到buffer.mData中即可
//    A *pcmData = [_pcmTemQueue firstObject];
//
//    if (pcmData) {
//
//        buffer.mDataByteSize = pcmData.buffer.mDataByteSize;
//        memcpy(buffer.mData, pcmData.buffer.mData, pcmData.buffer.mDataByteSize);
//        [_pcmTemQueue removeObjectAtIndex:0];
//    }
    
    
}
- (void)delete{
    NSString *pcmPath = stroePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:pcmPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:pcmPath error:nil];
    }
}
int readData(char *data, int len)
{
    NSData *dataStore = [NSData dataWithContentsOfFile:stroePath];
    NSData *subData = [dataStore subdataWithRange:NSMakeRange(_readerLength, len)];
    Byte *tempByte = (Byte *)[subData bytes];
    memcpy(data,tempByte,len);
    _readerLength = _readerLength + len;
    return len;
}
- (IBAction)start:(id)sender {
    
    [[QGAudioRecord shareManager] start];
//    [[QGAudioPlayer shareManager] startPlay];
    
    
}
- (IBAction)stop:(id)sender {
//    [[QGAudioPlayer shareManager] stopPlay];
    [[QGAudioRecord shareManager] stop];
}

- (void)savePcmToLocol{
    
}

@end
