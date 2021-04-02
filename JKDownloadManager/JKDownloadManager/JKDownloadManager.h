//
//  JKDownloadManager.h
//  JKDownloadManager
//
//  Created by imac on 2021/3/30.
//

#import <Foundation/Foundation.h>
#import "JKDownloadUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface JKDownloadManager : NSObject

/**
 单例
 */
+ (instancetype)manager;


/**
 开启任务下载资源
 */
- (void)download:(NSString *)url
        progress:(void(^)(NSInteger recivedSize, NSInteger expectedSize, CGFloat progress))progress
           state:(void(^)(FileDownloadState state))state
completionHandler:(nullable void(^)(NSString *filePath, NSError *error))completionHandler;

/**
 下载资源进度
 */
- (CGFloat)getProgress:(NSString *)url;


/**
 删除下载文件
 */
- (BOOL)deleteFile:(NSString *)url;


- (void)start:(NSString *)url;
- (void)pause:(NSString *)url;


@end

NS_ASSUME_NONNULL_END
