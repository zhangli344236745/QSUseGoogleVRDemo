//
//  QSPanoramaView.h
//  QSUseGoogleVRDemo
//
//  Created by zhongpingjiang on 17/4/19.
//  Copyright © 2017年 shaoqing. All rights reserved.
//

#import "GVRPanoramaView.h"

/**
 全景图片播放 + VR
 */
@interface QSPanoramaView : GVRPanoramaView

/**
 加载图片的网络链接
 */
- (void)loadImageUrlString:(NSString *)imageUrl
                    ofType:(GVRPanoramaImageType)imageType;


/**
 取消当前的下载
 */
- (void)cancelCurrentDownLoad;


@end
