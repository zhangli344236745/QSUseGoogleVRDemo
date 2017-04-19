//
//  QSDownloadManager.h

#import <UIKit/UIKit.h>
#import "QSSessionModel.h"

// 缓存主目录
#define QSCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]stringByAppendingPathComponent:@"QSUseGoogleVRDemo"]

// 保存文件名
#define QSFileName(url)  [[url componentsSeparatedByString:@"/"] lastObject]

// 文件的存放路径（caches）
#define QSFileFullpath(url) [QSCachesDirectory stringByAppendingPathComponent:QSFileName(url)]

// 文件的已下载长度
#define QSDownloadLength(url) [[[NSFileManager defaultManager] attributesOfItemAtPath:QSFileFullpath(url) error:nil][NSFileSize] integerValue]

// 存储文件信息的路径（caches）
#define QSDownloadDetailPath [QSCachesDirectory stringByAppendingPathComponent:@"downloadDetail.data"]


@interface QSDownloadManager : NSObject

/**
 *  单例
 */
+ (instancetype)sharedInstance;


/**
 *  开启任务下载资源
 *
 *  @param url           下载地址
 *  @param progressBlock 回调下载进度
 *  @param stateBlock    下载状态
 */
- (void)download:(NSString *)url progress:(QSDownloadProgressBlock)progressBlock state:(QSDownloadStateBlock)stateBlock;


#pragma mark - public methods
/**
 *  删除url对应的资源
 *
 *  @param url 下载地址
 */
- (void)deleteFileCacheAt:(NSString *)url;

/**
 *  清空所有下载资源
 */
- (void)deleteAllFileCache;


@end
