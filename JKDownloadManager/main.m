//
//  main.m
//  JKDownloadManager
//
//  Created by imac on 2021/3/30.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    NSLog(@"main");
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
