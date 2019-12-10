//
//  GSNAudioUnitGraph.h
//  RecordDemo
//
//  Created by 杨浩 on 2019/8/27.
//  Copyright © 2019 杨浩. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GSNAudioUnitGraph : NSObject

- (void)audioUnitStartRecordAndPlay;
- (void)audioUnitStop;

@end


NS_ASSUME_NONNULL_END
