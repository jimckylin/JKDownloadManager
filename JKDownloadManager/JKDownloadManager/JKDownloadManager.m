//
//  JKDownloadManager.m
//  JKDownloadManager
//
//  Created by imac on 2021/3/30.
//

#import "JKDownloadManager.h"

@interface JKDownloadManager ()<NSURLSessionDataDelegate>

@property (nonatomic, copy) NSString *cachePath;
@property (nonatomic, copy) NSString *fileSizePath;

@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *sessionUnits;

@end



static JKDownloadManager *_manager;

@implementation JKDownloadManager

+ (instancetype)manager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[JKDownloadManager alloc] init];
        
        NSString *cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"filePatch"];
        _manager.cachePath = cachePath;
        _manager.fileSizePath = [cachePath stringByAppendingPathComponent:@"fileSize.plist"];
        
        _manager.tasks = [NSMutableDictionary dictionary];
        _manager.sessionUnits = [NSMutableDictionary dictionary];
    });
    
    return _manager;
}


- (void)download:(NSString *)url progress:(void (^)(NSInteger, NSInteger, CGFloat))progress state:(void (^)(FileDownloadState))state completionHandler:(void (^)(NSString * _Nonnull, NSError * _Nonnull))completionHandler {
    
    if (!url) {
        return;
    }
    
    if ([self fileDownloadStateWithUrl:url] == FileDownloadStateCompleted) {
        state(FileDownloadStateCompleted);
        NSLog(@"----该资源已下载完成");
        return;
    }
    
    // 暂停
    if ([self.tasks valueForKey:[self fileName:url]]) {
        [self handlerUrl:url];
        return;
    }
    
    // 创建缓存目录
    [self createCacheDirectory:url];
    
    // 创建会话
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue new]];
    
    // 创建流
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:[self filePathWithUrl:url] append:YES];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", [self fileDownloadLength:url]];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    // 创建一个Data任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    
    NSUInteger taskIdentifier = arc4random()%(arc4random()%10000 + arc4random()%10000);
    [task setValue:@(taskIdentifier) forKey:@"taskIdentifier"];
    
    // 保存任务
    [self.tasks setValue:task forKey:[self fileName:url]];
    
    
    JKDownloadUnit *sessionUnit = [JKDownloadUnit new];
    sessionUnit.url = url;
    sessionUnit.outputStream = outputStream;
    sessionUnit.progress = progress;
    sessionUnit.state = state;
    sessionUnit.completionHandler = completionHandler;
    
    [self.sessionUnits setValue:sessionUnit forKey:@(task.taskIdentifier).stringValue];
    
    // 开始下载
    [self start:url];
    
}

- (CGFloat)getProgress:(NSString *)url {
    
    NSUInteger receivedSize = [self fileDownloadLength:url];
    NSUInteger expectedSize = [self fileTotalLength:url];
    CGFloat progress = 1.0 * receivedSize/expectedSize;
    
    if (isnan(progress) || isinf(progress)) {
        progress = 0.0;
    }
    
    return progress;
}


- (BOOL)deleteFile:(NSString *)url {
    
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self filePathWithUrl:url]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self filePathWithUrl:url] error:&error];
    }
    if (error) {
        return NO;
    }
    
    return YES;
}





#pragma mark - Private

- (void)handlerUrl:(NSString *)url {
    
    NSURLSessionDataTask *task = [self getTask:url];
    if (task.state == NSURLSessionTaskStateRunning) {
        [task suspend];
    }else {
        [task resume];
    }
    
}

- (NSURLSessionDataTask *)getTask:(NSString *)url {
    
    return (NSURLSessionDataTask *)[self.tasks objectForKey:[self fileName:url]];
}

- (void)start:(NSString *)url {
    
    NSURLSessionDataTask *task = [self getTask:url];
    [task resume];
    
}

- (void)pause:(NSString *)url {
    
    NSURLSessionDataTask *task = [self getTask:url];
    [task suspend];
}


- (JKDownloadUnit *)getSessionUnit:(NSUInteger)identifier {
    
    return [self.sessionUnits objectForKey:@(identifier).stringValue];
}


/**
    创建缓存目录
 */
- (void)createCacheDirectory:(NSString *)url {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.cachePath]) {
        [fileManager createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

/**
    查看文件的下载状态
 */
- (FileDownloadState)fileDownloadStateWithUrl:(NSString *)url {
    if ([self fileTotalLength:url]) {
        if ([self fileDownloadLength:url] == [self fileTotalLength:url]) {
            return FileDownloadStateCompleted;
        }else {
            return FileDownloadStateSuspended;
        }
    }
    return FileDownloadStateNone;
}

/**
    查看下载文件的大小
 */
- (NSInteger)fileDownloadLength:(NSString *)url {
    
    NSInteger length = [[[NSFileManager defaultManager] attributesOfItemAtPath:[self filePathWithUrl:url] error:nil][NSFileSize] integerValue];
    return length;
}

/**
    查看文件的总大小
 */
- (NSInteger)fileTotalLength:(NSString *)url {
    return [[NSDictionary dictionaryWithContentsOfFile:self.fileSizePath][[self fileName:url]] integerValue];
}

/**
    下载文件的路径
 */
- (NSString *)filePathWithUrl:(NSString *)url {
    return [self.cachePath stringByAppendingPathComponent:[self fileName:url]];
}

/**
    下载文件的名称
 */
- (NSString *)fileName:(NSString *)url {
    return [[url componentsSeparatedByString:@"/"] lastObject];
}



#pragma mark -
/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                 didReceiveResponse:(NSHTTPURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    JKDownloadUnit *sessionUnit = [self getSessionUnit:dataTask.taskIdentifier];
    
    // 打开流
    [sessionUnit.outputStream open];
    
    // 获取服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + [self fileDownloadLength:sessionUnit.url];
    sessionUnit.totalLength = totalLength;
    sessionUnit.mimeType = response.allHeaderFields[@"Content-Type"];
    
    // 储存总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.fileSizePath];
    if (dict == nil) {
        dict = [NSMutableDictionary dictionary];
    }
    dict[[self fileName:sessionUnit.url]] = @(totalLength);
    [dict writeToFile:self.fileSizePath atomically:YES];
    
    // 接手请求，允许接受服务器的数据
    completionHandler(NSURLSessionResponseAllow);
    
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    JKDownloadUnit *sessionUnit = [self getSessionUnit:dataTask.taskIdentifier];
    
    // 写入数据
    [sessionUnit.outputStream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSUInteger receivedSize = [self fileDownloadLength:sessionUnit.url];
    NSUInteger expectedSize = sessionUnit.totalLength;
    CGFloat progress = 1.0 * receivedSize/expectedSize;
    
    //NSLog(@"----------receivedSize:%zd, expectedSize:%zd", receivedSize, expectedSize);
    
    sessionUnit.progress(receivedSize, expectedSize, progress);
}

/**
 * 请求完毕（成功|失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    JKDownloadUnit *sessionUnit = [self getSessionUnit:task.taskIdentifier];
    if (!sessionUnit) return;
    
    if ([self fileDownloadStateWithUrl:sessionUnit.url] == FileDownloadStateCompleted) {
        // 下载完成
        sessionUnit.state(FileDownloadStateCompleted);
        
    }else if(error) {
        // 下载失败
        sessionUnit.state(FileDownloadStateFailed);
    }
    
    sessionUnit.completionHandler([self filePathWithUrl:sessionUnit.url], error);
    
    // 关闭流
    [sessionUnit.outputStream close];
    sessionUnit.outputStream = nil;
    
    // 清楚任务
    [self.tasks removeObjectForKey:[self fileName:sessionUnit.url]];
    [self.sessionUnits removeObjectForKey:@(task.taskIdentifier).stringValue];
    
}



@end
