//
//  QSVideoViewController.m
//  QSUseGoogleVRDemo
//
//  Created by zhongpingjiang on 17/4/14.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSVideoViewController.h"
#import "GVRVideoView.h"

@interface QSVideoViewController ()<GVRVideoViewDelegate>{

    GVRVideoView *_videoView;
    BOOL _isPaused;
}

@end

@implementation QSVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"视频VR";
    
    _videoView = [[GVRVideoView alloc]init];
    _videoView.delegate = self;
    _videoView.enableFullscreenButton = YES;
    _videoView.enableCardboardButton = YES;
    _videoView.enableTouchTracking = YES;
    
    _videoView.frame = self.view.bounds;
    [self.view addSubview:_videoView];
    _isPaused = YES;
    
    // Load the sample 360 video, which is of type stereo-over-under.
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"congo" ofType:@"mp4"];
    [_videoView loadFromUrl:[[NSURL alloc] initFileURLWithPath:videoPath]
                     ofType:kGVRVideoTypeStereoOverUnder];
    
    // Alternatively, this is how to load a video from a URL:
    //NSURL *videoURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/googlevr/gvr-ios-sdk"
    //                                       @"/master/Samples/VideoWidgetDemo/resources/congo.mp4"];
    //[_videoView loadFromUrl:videoURL ofType:kGVRVideoTypeStereoOverUnder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}

#pragma mark - GVRVideoViewDelegate

- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {
    if (_isPaused) {
        [_videoView play];
    } else {
        [_videoView pause];
    }
    _isPaused = !_isPaused;
}

- (void)widgetView:(GVRWidgetView *)widgetView didLoadContent:(id)content {
    NSLog(@"Finished loading video");
    [_videoView play];
    _isPaused = NO;
}

- (void)widgetView:(GVRWidgetView *)widgetView
didFailToLoadContent:(id)content
  withErrorMessage:(NSString *)errorMessage {
    NSLog(@"Failed to load video: %@", errorMessage);
}

- (void)videoView:(GVRVideoView*)videoView didUpdatePosition:(NSTimeInterval)position {
    // Loop the video when it reaches the end.
    if (position == videoView.duration) {
        [_videoView seekTo:0];
        [_videoView play];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
