//
//  QSVideoView.h
//  QSUseGoogleVRDemo
//
//  Created by zhongpingjiang on 17/4/19.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "GVRVideoView.h"

/**
 全景视频播放 + VR
 */
@interface QSVideoView : GVRVideoView

/**
 加载视频的网络链接
 */
- (void)loadVideoUrlString:(NSString *)videoUrlString ofType:(GVRVideoType)videoType;


/**
 取消当前的下载
 */
- (void)cancelCurrentDownLoad;

@end
