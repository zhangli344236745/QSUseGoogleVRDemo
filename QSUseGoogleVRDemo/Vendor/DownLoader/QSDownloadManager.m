//
//  QSDownloadManager.m


#import "QSDownloadManager.h"

#pragma mark - QSSessionModel
@implementation QSSessionModel

- (NSString *)fileSizeInUnitString:(unsigned long long)contentLength{
    
    CGFloat fileSize = 0.0f;
    NSString *unitStr = @"";
    if(contentLength >= pow(1024, 3)) {
        fileSize =  contentLength * 1.0 / pow(1024, 3);
        unitStr = @"GB";
    }
    else if (contentLength >= pow(1024, 2)) {
        
        fileSize = contentLength * 1.0 / pow(1024, 2);
        unitStr = @"MB";
    }else if (contentLength >= 1024) {
        
        fileSize = contentLength * 1.0 / 1024;
        unitStr = @"KB";
    }else {
        fileSize = contentLength * 1.0;
        unitStr = @"B";
    }
    
    NSString *fileSizeInUnitStr = [NSString stringWithFormat:@"%.2f %@",
                                   fileSize,unitStr];
    return fileSizeInUnitStr;
}

@end


#pragma mark - QSDownloadManager
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
 *  下载资源
 */
- (void)download:(NSString *)url progress:(QSDownloadProgressBlock)progressBlock completedBlock:(QSDownloadCompletedBlock)completedBlock{
    
    //初始化
    QSSessionModel *sessionModel = [[QSSessionModel alloc] init];
    sessionModel.url = url;
    sessionModel.fileCachePath = QSFileFullpath(url);
    sessionModel.progressBlock = progressBlock;
    sessionModel.completedBlock = completedBlock;
    
    BOOL isValid = [self validDownload:url sessionModel:sessionModel];
    //凡是url为空，重复下载,都不需要再下载
    if (!isValid) {
        return;
    }
    
    if ([self isFileExistsAt:url] && sessionModel) {
        sessionModel.state = QSDownloadStateCompleted;
        if (completedBlock && sessionModel.fileCachePath) {
            completedBlock(sessionModel.fileCachePath);
        }
        NSLog(@"%@ 已下载完成",url);
        return;
    }
    
    //初始化URLSession
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    // 创建流
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:sessionModel.fileCachePath append:YES];
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", QSDownloadLength(url)];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // 创建一个Data任务
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [dataTask setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
   
    sessionModel.state = QSDownloadStateStart;
    sessionModel.stream = stream;
    sessionModel.startTime = [NSDate date];
    
    //fileName(key) --> task
    //taskIdentifier(key) --> seesionModel
    
    // 缓存任务
    [self.tasks setValue:dataTask forKey:QSFileName(url)];
    //缓存model到内存
    [self.sessionModels setValue:sessionModel forKey:@(dataTask.taskIdentifier).stringValue];
    //开始下载
    [self start:url];
}

- (BOOL)validDownload:(NSString *)url sessionModel:(QSSessionModel *)sessionModel{
    
    if (!url || url.length == 0){
        NSLog(@"urlString不可以为空");
        return NO;
    }
    
    NSURLSessionDataTask *task = [self getTask:url];
    if (task && task.state == NSURLSessionTaskStateRunning) {
        NSLog(@"%@ 正在下载中，请勿重复下载",url);
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
}


/**
 *  根据url获得对应的下载任务
 */
- (NSURLSessionDataTask *)getTask:(NSString *)url{
    
    NSURLSessionDataTask *task  = (NSURLSessionDataTask *)[self.tasks valueForKey:QSFileName(url)];
    if (!task) {
        NSLog(@"没有获得指定task");
    }
    return task;
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
    
    sessionModel.state = QSDownloadStateDownloading;
    
    //下载进度
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
    
    NSString *costTimeStr = [NSString stringWithFormat:@"%.3lf",[[NSDate date] timeIntervalSinceDate:sessionModel.startTime]];
    if ([self isFileExistsAt:sessionModel.url]) {
        // 下载完成
        sessionModel.state = QSDownloadStateCompleted;
        if (sessionModel.completedBlock && sessionModel.fileCachePath) {
            NSLog(@"%@下载成功",sessionModel.url);
            sessionModel.completedBlock(sessionModel.fileCachePath);
        }
        
    } else if (error){
        // 下载失败
        sessionModel.state = QSDownloadStateFailed;
        [self deleteFileCacheAt:sessionModel.url];
        NSLog(@"%@下载失败了",sessionModel.url);
    }
    
    NSLog(@"%@下载花费时间: %@",sessionModel.url,costTimeStr);

    // 清除任务
    [self.tasks removeObjectForKey:QSFileName(sessionModel.url)];
    [self.sessionModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    
    //取消请求
    if (error.code == -999){
        [self deleteFileCacheAt:sessionModel.url];
        return;
    }
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
