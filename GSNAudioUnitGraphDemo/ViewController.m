//
//  ViewController.m
//  GSNAudioUnitGraphDemo
//
//  Created by 杨浩 on 2019/12/10.
//  Copyright © 2019 杨浩. All rights reserved.
//

#import "ViewController.h"
#import "GSNAudioUnitGraph.h"
@interface ViewController ()

@property (nonatomic, strong) GSNAudioUnitGraph *audioUnitGraph;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)startRecord:(id)sender {
    [self.audioUnitGraph audioUnitStartRecordAndPlay];
}

- (IBAction)stopRecord:(id)sender {
    [self.audioUnitGraph audioUnitStop];
}

- (GSNAudioUnitGraph *)audioUnitGraph {
    if (!_audioUnitGraph) {
        _audioUnitGraph = [[GSNAudioUnitGraph alloc] init];
    }
    return _audioUnitGraph;
}

@end
