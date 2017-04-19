//
//  QSVideoViewController.m
//  QSUseGoogleVRDemo
//
//  Created by zhongpingjiang on 17/4/14.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSVideoViewController.h"
#import "QSVideoView.h"

@interface QSVideoViewController (){

    QSVideoView *_videoView;
}

@end

@implementation QSVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"全景视频+VR";
    
    _videoView = [[QSVideoView alloc]initWithFrame:self.view.bounds];
    [_videoView loadVideoUrlString:@"https://d3fvwbt1l4ic3o.cloudfront.net/video/small/da8e5704-91b2-441c-ae0a-a9fdfadf6923.mp4"
                            ofType:kGVRVideoTypeMono];
    [self.view addSubview:_videoView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
