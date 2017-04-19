//
//  QSVideoView.m
//  QSUseGoogleVRDemo
//
//  Created by zhongpingjiang on 17/4/19.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSVideoView.h"
#import "MBProgressHUD+Load.h"
#import "QSDownloadManager.h"

@interface QSVideoView()<GVRWidgetViewDelegate>

@property (nonatomic,strong)UIImageView *placeholderView;

@end

@implementation QSVideoView

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        [self setupConfig];
    }
    return self;
}

- (void)setupConfig{
    
    //隐藏消息按钮
    self.enableInfoButton = NO;
    self.enableFullscreenButton = NO;
    self.enableCardboardButton = YES;
    self.hidesTransitionView = YES;
    self.enableTouchTracking = YES;
    self.delegate = self;
}

- (UIImageView *)placeholderView{

    if (!_placeholderView) {
        _placeholderView = [[UIImageView alloc]initWithFrame:self.bounds];
        _placeholderView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_placeholderView];
    }
    return _placeholderView;
}

/**
 加载视频的网络链接
 */
- (void)loadVideoUrlString:(NSString *)videoUrlString ofType:(GVRVideoType)videoType{
    
    self.placeholderView.alpha = 1.0f;  //遮盖
    [MBProgressHUD showHUDWithContent:@"视频加载中..." toView:self];
    [[QSDownloadManager sharedInstance]download:videoUrlString progress:^(CGFloat progress, NSString *speed, NSString *remainingTime) {
    NSLog(@"当前下载进度:%.2lf,当前的下载速度是：%@，还需要时间:%@,",progress,speed,remainingTime);
    
    } completedBlock:^(NSString *fileCacheFile) {
    
        NSURL *fileUrl = [NSURL fileURLWithPath:fileCacheFile];
        [self loadFromUrl:fileUrl ofType:videoType];
    }];
}

#pragma mark - GVRVideoViewDelegate
- (void)widgetViewDidTap:(GVRWidgetView *)widgetView {

    NSLog(@"tap View");
}

- (void)widgetView:(GVRWidgetView *)widgetView didLoadContent:(id)content {

    NSLog(@"视频加载结束...");

    [UIView animateWithDuration:1.0 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.placeholderView.alpha = 0;
        
    } completion:^(BOOL finished) {
        
        [_placeholderView removeFromSuperview];
        _placeholderView = nil;
        [MBProgressHUD hideHUDInView:self];
        [self play];
    }];
}

- (void)widgetView:(GVRWidgetView *)widgetView
didFailToLoadContent:(id)content
  withErrorMessage:(NSString *)errorMessage {
    NSLog(@"Failed to load video: %@", errorMessage);
    
    [MBProgressHUD hideHUDInView:self];
}


- (void)videoView:(GVRVideoView*)videoView didUpdatePosition:(NSTimeInterval)position {
    // Loop the video when it reaches the end.
    if (position == videoView.duration) {
        [self seekTo:0];
        [self play];
    }
}


@end
