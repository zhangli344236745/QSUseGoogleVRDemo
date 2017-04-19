//
//  QSDownloadManager.m
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "QSDownloadManager.h"

@interface QSDownloadManager()<NSCopying, NSURLSessionDelegate>

/** 保存所有任务*/
@property (nonatomic, strong) NSMutableDictionary *tasks;
/** 保存所有下载相关信息字典 */
@property (nonatomic, strong) NSMutableDictionary *sessionModels;

@end

@implementation QSDownloadManager

static QSDownloadManager *_downloadManager;

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _downloadManager = [super allocWithZone:zone];
    });
    
    return _downloadManager;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone{
    
    return _downloadManager;
}

+ (instancetype)sharedInstance{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[self alloc] init];
    });
    
    return _downloadManager;
}

#pragma mark - lazy load
- (NSMutableDictionary *)tasks{
    
    if (!_tasks) {
        _tasks = [NSMutableDictionary dictionary];
    }
    return _tasks;
}

- (NSMutableDictionary *)sessionModels{
    
    if (!_sessionModels) {
        _sessionModels = @{}.mutableCopy;
    }
    return _sessionModels;
}


/**
 *  开启任务下载资源
 */
- (void)download:(NSString *)url progress:(QSDownloadProgressBlock)progressBlock state:(QSDownloadStateBlock)stateBlock{
    
    BOOL isValid = [self validDownloadUrlString:url stateBlock:stateBlock];
    //凡是url为空，重复下载，已经下载过的，都不需要再下载
    if (!isValid) {
        return;
    }
    
    //初始化URLSession
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    // 创建流
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:QSFileFullpath(url) append:YES];
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", QSDownloadLength(url)];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // 创建一个Data任务
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [dataTask setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    // 保存任务
    [self.tasks setValue:dataTask forKey:QSFileName(url)];
    
    QSSessionModel *sessionModel = [[QSSessionModel alloc] init];
    sessionModel.url = url;
    sessionModel.progressBlock = progressBlock;
    sessionModel.stateBlock = stateBlock;
    sessionModel.stream = stream;
    sessionModel.startTime = [NSDate date];
    sessionModel.fileName = QSFileName(url);
    [self.sessionModels setValue:sessionModel forKey:@(dataTask.taskIdentifier).stringValue];

    [self start:url];
}


- (BOOL)validDownloadUrlString:(NSString *)urlString stateBlock:(QSDownloadStateBlock)stateBlock{

    NSLog(@"urlString不可以为空");
    if (!urlString || urlString.length == 0)
        return NO;
    
    if ([self isFileExistsAt:urlString] && stateBlock) {
        stateBlock(DownloadStateCompleted);
        NSLog(@"%@ 已下载完成",urlString);
        return NO;
    }
    
    NSURLSessionDataTask *task = [self getTask:urlString];
    if (task && task.state == NSURLSessionTaskStateRunning) {
        NSLog(@"%@ 正在下载中，请勿重复下载",urlString);
        return NO;
    }
    
    // 创建缓存目录文件
    if (![[NSFileManager defaultManager] fileExistsAtPath:QSCachesDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:QSCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return YES;
}

#pragma mark - operation for url
/**
 *  开始下载
 */
- (void)start:(NSString *)url{
    
    NSURLSessionDataTask *task = [self getTask:url];
    [task resume];
    
    [self getSessionModel:task.taskIdentifier].stateBlock(DownloadStateStart);
}


/**
 *  根据url获得对应的下载任务
 */
- (NSURLSessionDataTask *)getTask:(NSString *)url{
    
    return (NSURLSessionDataTask *)[self.tasks valueForKey:QSFileName(url)];
}

/**
 *  根据url获取对应的下载信息模型
 */
- (QSSessionModel *)getSessionModel:(NSUInteger)taskIdentifier{
    
    return (QSSessionModel *)[self.sessionModels valueForKey:@(taskIdentifier).stringValue];
}

/**
 *  判断该文件是否存在
 */
- (BOOL)isFileExistsAt:(NSString *)url{
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:QSFileFullpath(url)]) {
        return YES;
    }
    return NO;
}



#pragma mark NSURLSessionDataDelegate
/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    QSSessionModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 打开流
    [sessionModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + QSDownloadLength(sessionModel.url);
    sessionModel.totalLength = totalLength;
    
    // 总文件大小
    NSString *fileSizeInUnits = [sessionModel fileSizeInUnitString:(unsigned long long)totalLength];
    sessionModel.totalSize = fileSizeInUnits;
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    
    QSSessionModel *sessionModel = [self getSessionModel:dataTask.taskIdentifier];
    
    // 写入数据
    [sessionModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger receivedSize = QSDownloadLength(sessionModel.url);
    NSUInteger expectedSize = sessionModel.totalLength;
    CGFloat progress = 1.0 * receivedSize / expectedSize;
    
    // 每秒下载速度
    NSTimeInterval downloadTime = -1 * [sessionModel.startTime timeIntervalSinceNow];
    NSUInteger speed = receivedSize / downloadTime;
    if (speed == 0) { return; }
    NSString *speedStr = [NSString stringWithFormat:@"%@/s",[sessionModel fileSizeInUnitString:(unsigned long long) speed]];
    
    // 剩余下载时间
    NSMutableString *remainingTimeStr = [[NSMutableString alloc] init];
    unsigned long long remainingContentLength = expectedSize - receivedSize;
    int remainingTime = (int)(remainingContentLength / speed);
    int hours = remainingTime / 3600;
    int minutes = (remainingTime - hours * 3600) / 60;
    int seconds = remainingTime - hours * 3600 - minutes * 60;
    
    if(hours>0) {[remainingTimeStr appendFormat:@"%d 小时 ",hours];}
    if(minutes>0) {[remainingTimeStr appendFormat:@"%d 分 ",minutes];}
    if(seconds>0) {[remainingTimeStr appendFormat:@"%d 秒",seconds];}
    
    if (sessionModel.stateBlock) {
        sessionModel.stateBlock(DownloadStateDownloading);
    }
    if (sessionModel.progressBlock) {
        sessionModel.progressBlock(progress, speedStr, remainingTimeStr);
    }
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    QSSessionModel *sessionModel = [self getSessionModel:task.taskIdentifier];
    if (!sessionModel) return;
    
    // 关闭流
    [sessionModel.stream close];
    sessionModel.stream = nil;
    
    if ([self isFileExistsAt:sessionModel.url]) {
        // 下载完成
        sessionModel.stateBlock(DownloadStateCompleted);
        
    } else if (error){
        // 下载失败
        sessionModel.stateBlock(DownloadStateFailed);
    }
    sessionModel.endTime = [NSDate date];
    // 清除任务
    [self.tasks removeObjectForKey:QSFileName(sessionModel.url)];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];

    
    // 清除任务
    [self.tasks removeObjectForKey:QSFileName(sessionModel.url)];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    
    if (error.code == -999)
        return;   // cancel
}

#pragma mark - public methods
/**
 *  删除url对应的资源
 */
- (void)deleteFileCacheAt:(NSString *)url{
    
    NSURLSessionDataTask *task = [self getTask:url];
    if (task) {
        // 取消下载
        [task cancel];
    }
    NSString *filePath = QSFileFullpath(url);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        // 删除沙盒中的资源
        [fileManager removeItemAtPath:filePath error:nil];
        // 删除任务
        [self.tasks removeObjectForKey:filePath];
        [self.sessionModels removeObjectForKey:@([self getTask:url].taskIdentifier).stringValue];
    }
}

/**
 *  清空所有下载资源
 */
- (void)deleteAllFileCache{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:QSCachesDirectory]) {
        
        // 删除沙盒中所有资源
        [fileManager removeItemAtPath:QSCachesDirectory error:nil];
        // 删除任务
        [[self.tasks allValues] makeObjectsPerformSelector:@selector(cancel)];
        [self.tasks removeAllObjects];
        
        for (QSSessionModel *sessionModel in [self.sessionModels allValues]) {
            [sessionModel.stream close];
        }
        [self.sessionModels removeAllObjects];
    }
}

@end
