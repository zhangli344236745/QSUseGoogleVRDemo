//
//  QSDownloadManager.h

#import <UIKit/UIKit.h>
#import "QSDownLoadDefine.h"

#pragma mark - QSSessionModel
@interface QSSessionModel : NSObject

@property (nonatomic, strong) NSOutputStream *stream;  //输出流
@property (nonatomic, copy) NSString *url;  //下载url地址
@property (nonatomic, copy) NSString *fileCachePath;  //文件缓存路径
@property (nonatomic, copy) NSString *totalSize;  //文件大小描述 如1MB，200KB
@property (nonatomic, assign) NSInteger totalLength; //数据的总长度（字节数）
@property (nonatomic, strong) NSDate *startTime;  //开始时间
@property (nonatomic, assign)QSDownloadState state;  //下载的状态

@property (nonatomic, copy) QSDownloadProgressBlock progressBlock; //下载进度
@property (nonatomic, copy) QSDownloadCompletedBlock completedBlock; //下载完成处理

/**
 返回文件的大小描述,如1MB，200KB
 */
- (NSString *)fileSizeInUnitString:(unsigned long long)contentLength;

@end


#pragma mark - QSDownloadManager
@interface QSDownloadManager : NSObject

/**
 *  单例
 */
+ (instancetype)sharedInstance;

/**
 *  下载资源
 */
- (void)download:(NSString *)url progress:(QSDownloadProgressBlock)progressBlock completedBlock:(QSDownloadCompletedBlock)completedBlock;


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
