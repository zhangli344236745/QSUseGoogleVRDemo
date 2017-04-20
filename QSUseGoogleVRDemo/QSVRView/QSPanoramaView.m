//
//  QSPanoramaView.m
//  QSUseGoogleVRDemo
//
//  Created by zhongpingjiang on 17/4/19.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "QSPanoramaView.h"
#import "QSDownloadManager.h"
#import "MBProgressHUD+Load.h"

@interface QSPanoramaView()<GVRWidgetViewDelegate>

@property (nonatomic,copy)NSString *imageUrlString;
@property (nonatomic,strong)UIImageView *placeholderView;

@end

@implementation QSPanoramaView

- (instancetype)initWithFrame:(CGRect)frame{

    self = [super initWithFrame:frame];
    if (self) {
        [self setupConfig];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(badNetWorkNotification:)   name:
         QSNetworkBadNotification object:nil];
    }
    return self;
}

- (void)setupConfig{

    //隐藏消息按钮
    self.enableInfoButton = NO;
    //
    self.enableFullscreenButton = NO;
    //
    self.enableCardboardButton = YES;
    //隐藏
    self.hidesTransitionView = YES;
    //允许手势控制
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

- (void)loadImageUrlString:(NSString *)imageUrlString ofType:(GVRPanoramaImageType)imageType{
    
    //新的链接或是原来没有下载链接
    if ((!self.imageUrlString || self.imageUrlString.length == 0) || ![self.imageUrlString isEqualToString:imageUrlString]) {
        
        [self cancelCurrentDownLoad];
        //更新urlStirng
        self.imageUrlString = imageUrlString;
    }else{
        return;
    }

    self.placeholderView.alpha = 1.0f; //遮盖
    [MBProgressHUD showHUDWithContent:@"图片加载中..." toView:self];
    
    [[QSDownloadManager sharedInstance]download:imageUrlString
                                       progress:^(CGFloat progress, NSString *speed, NSString *remainingTime) {

                                           NSLog(@"当前下载进度:%.2lf%%,当前的下载速度是：%@，还需要时间:%@,",progress * 100,speed,remainingTime);
        
                                       } completedBlock:^(NSString *fileCacheFile) {
                                           
                                           NSData *imageData = [NSData dataWithContentsOfFile:fileCacheFile];
                                           UIImage *image = [UIImage imageWithData:imageData];
                                           [self loadImage:image ofType:imageType];
                                       }];
}

- (void)cancelCurrentDownLoad{
    
    [[QSDownloadManager sharedInstance] cancelDownLoad:self.imageUrlString];
    
}

#pragma mark - GVRWidgetViewDelegate
- (void)widgetView:(GVRWidgetView *)widgetView didLoadContent:(id)content {
    
    NSLog(@"图片加载完成...");
    [UIView animateWithDuration:1.0 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.placeholderView.alpha = 0;
        
    } completion:^(BOOL finished) {
        
        [_placeholderView removeFromSuperview];
        _placeholderView = nil;
        [MBProgressHUD hideHUDInView:self];
    }];
}

- (void)badNetWorkNotification:(NSNotification*)notification{
    
    [MBProgressHUD hideHUDInView:self];
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"⚠️"  message:@"网络太差，请稍后再试..." delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alertView show];
}





@end
