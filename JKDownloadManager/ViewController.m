//
//  ViewController.m
//  JKDownloadManager
//
//  Created by imac on 2021/3/30.
//

#import "ViewController.h"
#import "JKDownloadManager/JKDownloadManager.h"

@interface ViewController ()

@property (nonatomic, strong) NSArray  *urls;

@property (nonatomic, strong) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView2;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView3;
@property (nonatomic, strong) IBOutlet UIProgressView *progressView4;

@end

@implementation ViewController

+ (void)initialize {
    NSLog(@"initialize");
}

+ (void)load {
    NSLog(@"load");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSArray *urls = [NSArray arrayWithObjects:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg",
                     @"https://issuecdn.baidupcs.com/issue/netdisk/MACguanjia/BaiduNetdisk_mac_3.6.5.dmg",
                     @"https://xiazai.zol.com.cn/index.php?c=Detail_DetailMini&n=df8100ccec3c7fa05&softid=439337",
                     @"http://media.blizzard.com/sc2/media/videos/sc2-intro-cinematic/sc2-intro-cinematic.flv", nil];
    self.urls = urls;
    
    self.progressView.progress = [[JKDownloadManager manager] getProgress:urls[0]];
    self.progressView2.progress = [[JKDownloadManager manager] getProgress:urls[1]];
    self.progressView3.progress = [[JKDownloadManager manager] getProgress:urls[2]];
    self.progressView4.progress = [[JKDownloadManager manager] getProgress:urls[3]];
}


- (IBAction)deleteFile:(id)sender {
    
    BOOL delete = [[JKDownloadManager manager] deleteFile:self.urls[0]];
    if (delete) {
        self.progressView.progress = 0.0;
    }
}

- (IBAction)deleteFile2:(id)sender {
    
    BOOL delete = [[JKDownloadManager manager] deleteFile:self.urls[1]];
    if (delete) {
        self.progressView2.progress = 0.0;
    }
}

- (IBAction)deleteFile3:(id)sender {
    
    BOOL delete = [[JKDownloadManager manager] deleteFile:self.urls[2]];
    if (delete) {
        self.progressView3.progress = 0.0;
    }
}

- (IBAction)deleteFile4:(id)sender {
    
    BOOL delete = [[JKDownloadManager manager] deleteFile:self.urls[3]];
    if (delete) {
        self.progressView4.progress = 0.0;
    }
}



- (IBAction)download:(id)sender {
    
    dispatch_queue_t queue = dispatch_queue_create("net.test.download", DISPATCH_QUEUE_SERIAL);
    
    // 获得主队列 == 串行队列
    //dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    // 全局并发队列
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    
    // 队列组
    
    dispatch_async(globalQueue, ^{
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_async(queue, ^{
            [self downloadMethodWithUrl:0 progress:^(CGFloat progress) {

                CGFloat p = [[NSString stringWithFormat:@"%0.1f", progress] floatValue];
                if (p == 0.5) {
                    dispatch_semaphore_signal(semaphore);
                    [[JKDownloadManager manager] pause:self.urls[0]];
                }
            }];
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"===========一个下载任务执行完成");
        
        dispatch_async(queue, ^{
            [self downloadMethodWithUrl:1 progress:^(CGFloat progress) {
                
                if (progress == 1) {
                    [self downloadMethodWithUrl:0 progress:^(CGFloat progress2) {

                        if (progress2 == 1) {
                            dispatch_semaphore_signal(semaphore);
                        }
                    }];
                }
            }];
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"===========两个下载任务执行完成");
    });
    
    
    
    
//    dispatch_group_notify(groupQueue, dispatch_get_main_queue(), ^{
//
//        NSLog(@"===========两个下载任务执行完成");
//    });
    
    
    
    
    return;
    dispatch_sync(queue, ^{
        [self downloadMethodWithUrl:0 progress:^(CGFloat progress) {
            
        }];
    });
    
    dispatch_sync(queue, ^{
        [self downloadMethodWithUrl:1 progress:^(CGFloat progress) {
            
        }];
    });
    
    /* // 栅栏方法
    dispatch_barrier_sync(queue, ^{
        NSLog(@"dispatch_barrier_async");
    });*/
    
    
    dispatch_sync(queue, ^{
        [self downloadMethodWithUrl:2 progress:^(CGFloat progress) {
            
        }];
    });
    dispatch_sync(queue, ^{
        [self downloadMethodWithUrl:3 progress:^(CGFloat progress) {
            
        }];
    });
    
    
//    [self downloadMethodWithUrl:0];
//    [self downloadMethodWithUrl:1];
//    [self downloadMethodWithUrl:2];
//    [self downloadMethodWithUrl:3];
}

- (IBAction)download2:(id)sender {
    
    //[self downloadMethodWithUrl:1];
}

- (IBAction)download3:(id)sender {
    
    //[self downloadMethodWithUrl:2];
}

- (IBAction)download4:(id)sender {
    

    //[self downloadMethodWithUrl:3];
}




- (void)downloadMethodWithUrl:(NSInteger)index progress:(void(^)(CGFloat progress))progress1 {
    
    NSString *url = self.urls[index];
    
    JKDownloadManager *manager = [JKDownloadManager manager];
    [manager download:url progress:^(NSInteger recivedSize, NSInteger expectedSize, CGFloat progress) {
        
        progress1(progress);
        
        NSLog(@"progress%ld====%f", index, progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            switch (index) {
                case 0:
                    self.progressView.progress = progress;
                    break;
                case 1:
                    self.progressView2.progress = progress;
                    break;
                case 2:
                    self.progressView3.progress = progress;
                    break;
                case 3:
                    self.progressView4.progress = progress;
                    break;
                    
                default:
                    break;
            }
            
        });
        
    } state:^(FileDownloadState state) {
        
        if (state == FileDownloadStateNone) {
            NSLog(@"--------未下载");
        }
        
    } completionHandler:^(NSString * _Nonnull filePath, NSError * _Nonnull error) {
        
        if (!error) {
            NSLog(@"--------下载完成：%@", filePath);
        }
            
    }];
}


@end
