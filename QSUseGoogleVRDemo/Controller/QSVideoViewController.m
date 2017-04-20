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
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    _videoView = [[QSVideoView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 64)];
    [_videoView loadVideoUrlString:@"https://d3fvwbt1l4ic3o.cloudfront.net/video/small/da8e5704-91b2-441c-ae0a-a9fdfadf6923.mp4"
                            ofType:kGVRVideoTypeMono];
    [self.view addSubview:_videoView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
    [_videoView cancelCurrentDownLoad];
    
}

- (void)dealloc{
    
    NSLog(@"全景视频+VR VC释放");
    
}


@end
