//
//  JKDownloadUnit.h
//  JKDownloadManager
//
//  Created by imac on 2021/3/30.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FileDownloadState) {
    FileDownloadStateStart     = 0,     /** 下载中 */
    FileDownloadStateSuspended = 1,     /** 下载暂停 */
    FileDownloadStateCompleted = 2,     /** 下载完成 */
    FileDownloadStateFailed    = 3,     /** 下载失败 */
    FileDownloadStateNone      = 4      /** 未下载 */
};


@interface JKDownloadUnit : NSObject

/** 流 */
@property (nonatomic, strong) NSOutputStream *outputStream;

/** 下载地址 */
@property (nonatomic, copy) NSString *url;

/** 获得服务器这次请求 返回数据的总长度 */
@property (nonatomic, assign) NSInteger totalLength;

/** 获得服务器这次请求 返回数据的类型 */
@property (nonatomic, copy) NSString *mimeType;


/** 下载进度 */
@property (nonatomic, copy) void(^progress)(NSInteger recivedSize, NSInteger expectedSize, CGFloat progress);
/** 下载状态 */
@property (nonatomic, copy) void(^state)(FileDownloadState state);
/** 下载结果 */
@property (nonatomic, copy) void(^completionHandler)(NSString *filePath, NSError *error);


@end

//NS_ASSUME_NONNULL_END
