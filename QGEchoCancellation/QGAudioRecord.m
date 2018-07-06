//
//  QGAudioRecord.m
//  QGAudioRecord
//
//  Created by Hanxiaojie on 2018/6/25.
//  Copyright © 2018年 徐其岗. All rights reserved.
//

#import "QGAudioRecord.h"

#define kRate 16000 //采样率
#define kChannels   (1)//声道数
#define kBits       (16)//位数

@implementation QGAudioRecord
{
    AUGraph _graph;
    AudioUnit _remoteIOUnit;
    AudioStreamBasicDescription _streamFormat;
}

+ (instancetype)shareManager{

    static QGAudioRecord *AudioRecord = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AudioRecord = [[self alloc] init];
    });
    return AudioRecord;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupAUGraph];
        [self setupEchoCancellation];
        [self setupRemoteIOUnit];
        
    }
    return self;
}
- (void)start{
    [self setupSession];

    CheckError(AUGraphInitialize(_graph),"AUGraphInitialize failed");
    CheckError(AUGraphStart(_graph), "AUGraphStart failed");
    AudioOutputUnitStart(_remoteIOUnit);
}
- (void)stop{
    CheckError(AUGraphUninitialize(_graph), "AUGraphInitialize failed");
    CheckError(AUGraphStop(_graph), "AUGraphStop failed");
    AudioOutputUnitStop(_remoteIOUnit);
    NSError *error = nil;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [session setActive:YES error:nil];
}
- (void)startRecord{
    
}
- (void)stopRecord{
    
}
- (void)invalid{
    
}
- (void)setupSession{
    NSError *error = nil;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [session setActive:YES error:nil];
}
- (void)setupAUGraph{
    //Create graph
    CheckError(NewAUGraph(&_graph),
               "NewAUGraph failed");
    
    //Create nodes and add to the graph
    AudioComponentDescription inputcd = {0};
    inputcd.componentType = kAudioUnitType_Output;
    inputcd.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    inputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    inputcd.componentFlagsMask = 0;
    inputcd.componentFlags = 0;
    AUNode remoteIONode;
    //Add node to the graph
    CheckError(AUGraphAddNode(_graph,
                              &inputcd,
                              &remoteIONode),
               "AUGraphAddNode failed");
    
    //Open the graph
    CheckError(AUGraphOpen(_graph),
               "AUGraphOpen failed");
    
    //Get reference to the node
    CheckError(AUGraphNodeInfo(_graph,
                               remoteIONode,
                               &inputcd,
                               &_remoteIOUnit),
               "AUGraphNodeInfo failed");
}

- (void)setupEchoCancellation{
    UInt32 echoCancellation = 1;
    UInt32 size = sizeof(echoCancellation);
    CheckError(AudioUnitSetProperty(_remoteIOUnit,
                                    kAUVoiceIOProperty_BypassVoiceProcessing,
                                    kAudioUnitScope_Input,
                                    0,
                                    &echoCancellation,
                                    size),
               "AudioUnitSetProperty kAUVoiceIOProperty_BypassVoiceProcessing failed");
    
}

- (void)setupRemoteIOUnit{
    
    //启用录音功能
    UInt32 inputEnableFlag = 1;
    CheckError(AudioUnitSetProperty(_remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    1,
                                    &inputEnableFlag,
                                    sizeof(inputEnableFlag)),
               "Open input of bus 1 failed");
//    Open output of bus 0(output speaker)
    //禁用播放功能
    UInt32 outputEnableFlag = 1;
    CheckError(AudioUnitSetProperty(_remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    0,
                                    &outputEnableFlag,
                                    sizeof(outputEnableFlag)),
               "Open output of bus 0 failed");
    //Set up stream format for input and output
    _streamFormat.mFormatID = kAudioFormatLinearPCM;
    _streamFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _streamFormat.mSampleRate = kRate;
    _streamFormat.mFramesPerPacket = 1;
    _streamFormat.mBytesPerFrame = 2;
    _streamFormat.mBytesPerPacket = 2;
    _streamFormat.mBitsPerChannel = kBits;
    _streamFormat.mChannelsPerFrame = kChannels;
    
    CheckError(AudioUnitSetProperty(_remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &_streamFormat,
                                    sizeof(_streamFormat)),
               "kAudioUnitProperty_StreamFormat of bus 0 failed");
    CheckError(AudioUnitSetProperty(_remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    1,
                                    &_streamFormat,
                                    sizeof(_streamFormat)),
               "kAudioUnitProperty_StreamFormat of bus 1 failed");
    
    //音频采集结果回调
    AURenderCallbackStruct recordCallback;
    recordCallback.inputProc = recordCallback_xb;
    recordCallback.inputProcRefCon = (__bridge void *)(self);
    CheckError(AudioUnitSetProperty(_remoteIOUnit,
                                kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Output,
                                    1,
                                    &recordCallback,
                                    sizeof(recordCallback)),
               "couldnt set remote i/o render callback for output");
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = playCallback_xb;
    playCallback.inputProcRefCon = (__bridge void *)(self);
    CheckError(AudioUnitSetProperty(_remoteIOUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Input,
                                    0,
                                    &playCallback,
                                    sizeof(playCallback)),
               "kAudioUnitProperty_SetRenderCallback failed");
}

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}
OSStatus recordCallback_xb(void *inRefCon,
                          AudioUnitRenderActionFlags *ioActionFlags,
                          const AudioTimeStamp *inTimeStamp,
                          UInt32 inBusNumber,
                          UInt32 inNumberFrames,
                          AudioBufferList *ioData){
    QGAudioRecord *audioRecord = (__bridge QGAudioRecord*)inRefCon;
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = 0;
    
    AudioUnitRender(audioRecord->_remoteIOUnit,
                    ioActionFlags,
                    inTimeStamp,
                    1,
                    inNumberFrames,
                    &bufferList);
    //    AudioBuffer buffer = bufferList.mBuffers[0];
    
    //将采集到的声音，进行回调
    if (audioRecord.delegate && [audioRecord.delegate respondsToSelector:@selector(audioRecord:recordCallBack:)])
    {
        [audioRecord.delegate audioRecord:audioRecord recordCallBack:&bufferList];
    }
//
    NSLog(@"InputCallback");
    return noErr;
}
OSStatus playCallback_xb(
                         void *inRefCon,
                         AudioUnitRenderActionFlags     *ioActionFlags,
                         const AudioTimeStamp         *inTimeStamp,
                         UInt32                         inBusNumber,
                         UInt32                         inNumberFrames,
                         AudioBufferList             *ioData)

{
    
    //TODO: implement this function
    memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
    
    QGAudioRecord *audioRecord = (__bridge QGAudioRecord*)inRefCon;
    
    if (audioRecord.delegate && [audioRecord.delegate respondsToSelector:@selector(audioPlayer:playCallBack:inNumberFrames:)]) {
        [audioRecord.delegate audioPlayer:audioRecord playCallBack:ioData inNumberFrames:inNumberFrames];
    }
    
    NSLog(@"outputRenderTone");
    return 0;
}

@end
