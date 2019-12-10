//
//  GSNAudioUnitManager.m
//  RecordDemo
//
//  Created by 杨浩 on 2019/8/27.
//  Copyright © 2019 杨浩. All rights reserved.
//

#import "GSNAudioUnitGraph.h"
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>


#define kInputBus 1
#define kOutputBus 0
FILE *file = NULL;
@interface GSNAudioUnitGraph ()

@property (nonatomic, copy) NSString *pathStr;

@end

@implementation GSNAudioUnitGraph {
    AVAudioSession *audioSession;
    AUGraph auGraph;
    AudioUnit remoteIOUnit;
    AUNode remoteIONode;
    AURenderCallbackStruct inputProc;
}

#pragma mark - CallBack
static OSStatus inputCallBack(
                         void                        *inRefCon,
                         AudioUnitRenderActionFlags     *ioActionFlags,
                         const AudioTimeStamp         *inTimeStamp,
                         UInt32                         inBusNumber,
                         UInt32                         inNumberFrames,
                         AudioBufferList             *ioData)
{
    GSNAudioUnitGraph *THIS=(__bridge GSNAudioUnitGraph*)inRefCon;

    OSStatus renderErr = AudioUnitRender(THIS->remoteIOUnit,
                                         ioActionFlags,
                                         inTimeStamp,
                                         1,
                                         inNumberFrames,
                                         ioData);
    
    [THIS writePCMData:ioData->mBuffers->mData size:ioData->mBuffers->mDataByteSize];
    return renderErr;
}

#pragma mark Init
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self audioUnitInit];
    }
    return self;
}

#pragma mark Check Error
static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char str[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
    exit(1);
    
}

#pragma mark Public API
- (void)audioUnitStartRecordAndPlay {
    CheckError(AUGraphStart(auGraph),"couldn't AUGraphStart");
    CAShow(auGraph);
}

- (void)audioUnitStop {
    CheckError(AUGraphStop(auGraph), "couldn't AUGraphStop");
}

#pragma mark Private API
- (void)audioUnitInit
{
    // 设置需要生成pcm的文件路径
    self.pathStr = [self documentsPath:@"/mixRecord.pcm"];
    
    [self initAudioSession];
    
    [self newAndOpenAUGraph];
    
    [self initAudioComponent];
    
    [self initFormat];
    
    [self initInputCallBack];
    
    [self initAndUpdateAUGraph];
    
}

- (void)writePCMData:(char *)buffer size:(int)size {
    if (!file) {
        file = fopen(self.pathStr.UTF8String, "w");
    }
    fwrite(buffer, size, 1, file);
}

- (NSString *)documentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}
#pragma mark - AudioUnitInitMethod
- (void)initAudioSession {
    audioSession = [AVAudioSession sharedInstance];

    NSError *error;
    // set Category for Play and Record
    // [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetoothA2DP error:&error];
     [audioSession setPreferredIOBufferDuration:0.01 error:&error];
}

- (void)newAndOpenAUGraph {
    CheckError(NewAUGraph(&auGraph),"couldn't NewAUGraph");
    CheckError(AUGraphOpen(auGraph),"couldn't AUGraphOpen");
}

- (void)initAudioComponent {
    AudioComponentDescription componentDesc;
    componentDesc.componentType = kAudioUnitType_Output;
    componentDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    componentDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    componentDesc.componentFlags = 0;
    componentDesc.componentFlagsMask = 0;
    
    CheckError (AUGraphAddNode(auGraph,&componentDesc,&remoteIONode),"couldn't add remote io node");
    CheckError(AUGraphNodeInfo(auGraph,remoteIONode,NULL,&remoteIOUnit),"couldn't get remote io unit from node");
}

- (void)initFormat {
    //set BUS
    UInt32 oneFlag = 1;
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    kOutputBus,
                                    &oneFlag,
                                    sizeof(oneFlag)),"couldn't kAudioOutputUnitProperty_EnableIO with kAudioUnitScope_Output");

    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    kInputBus,
                                    &oneFlag,
                                    sizeof(oneFlag)),"couldn't kAudioOutputUnitProperty_EnableIO with kAudioUnitScope_Input");
    
    AudioStreamBasicDescription mAudioFormat;
    mAudioFormat.mSampleRate         = 44100.0;//采样率
    mAudioFormat.mFormatID           = kAudioFormatLinearPCM;//PCM采样
    mAudioFormat.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    mAudioFormat.mReserved           = 0;
    mAudioFormat.mChannelsPerFrame   = 1;//1单声道，2立体声，但是改为2也并不是立体声
    mAudioFormat.mBitsPerChannel     = 16;//语音每采样点占用位数
    mAudioFormat.mFramesPerPacket    = 1;//每个数据包多少帧
    mAudioFormat.mBytesPerFrame      = (mAudioFormat.mBitsPerChannel / 8) * mAudioFormat.mChannelsPerFrame; // 每帧的bytes数
    mAudioFormat.mBytesPerPacket     = mAudioFormat.mBytesPerFrame;//每个数据包的bytes总数，每帧的bytes数＊每个数据包的帧数
    
    UInt32 size = sizeof(mAudioFormat);
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    kInputBus,
                                    &mAudioFormat,
                                    size),"couldn't set kAudioUnitProperty_StreamFormat with kAudioUnitScope_Output");
    
    CheckError(AudioUnitSetProperty(remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    kOutputBus,
                                    &mAudioFormat,
                                    size),"couldn't set kAudioUnitProperty_StreamFormat with kAudioUnitScope_Input");
}

- (void)initInputCallBack {
    inputProc.inputProc = inputCallBack;
    inputProc.inputProcRefCon = (__bridge void *)(self);
    
    CheckError(AUGraphSetNodeInputCallback(auGraph, remoteIONode, 0, &inputProc),"Error setting io input callback");
}

- (void)initAndUpdateAUGraph {
    CheckError(AUGraphInitialize(auGraph),"couldn't AUGraphInitialize" );
    CheckError(AUGraphUpdate(auGraph, NULL),"couldn't AUGraphUpdate" );
}


@end
