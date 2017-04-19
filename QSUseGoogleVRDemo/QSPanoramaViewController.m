//
//  QSPanoramaViewController.m
//  QSUseGoogleVRDemo
//
//  Created by zhongpingjiang on 17/4/14.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSPanoramaViewController.h"
#import "GVRPanoramaView.h"

@interface QSPanoramaViewController ()<GVRWidgetViewDelegate>{

    GVRPanoramaView *_panoView;
}

@end

@implementation QSPanoramaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"全景图片VR";
    
    _panoView = [[GVRPanoramaView alloc] init];
    _panoView.delegate = self;
    _panoView.enableFullscreenButton = YES;
    _panoView.enableCardboardButton = YES;
    _panoView.enableTouchTracking = YES;
    [_panoView loadImage:[UIImage imageNamed:@"andes.jpg"]
                  ofType:kGVRPanoramaImageTypeStereoOverUnder];
    _panoView.frame = self.view.bounds;
 
    [self.view addSubview:_panoView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
 
    // Dispose of any resources that can be recreated.
}


#pragma mark - GVRWidgetViewDelegate

- (void)widgetView:(GVRWidgetView *)widgetView didLoadContent:(id)content {
    NSLog(@"Loaded panorama image");
}


@end
