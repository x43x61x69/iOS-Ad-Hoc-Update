//
//  UIAdHocUpdate.m
//  UIAdHocUpdate
//
//  The MIT License (MIT)
//
//  Copyright © 2017 Zhi-Wei Cai. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#define kITMSServicesAction @"itms-services://?action=download-manifest&url="

#import "UIAdHocUpdate.h"

@implementation UIAdHocUpdate

+ (void)checkForUpdate:(NSURL *)manifestURL
{
    [[self class] checkForUpdate:manifestURL terminationHandler:^{ return YES; }];
}

+ (void)checkForUpdate:(NSURL *)manifestURL terminationHandler:(BOOL (^)(void))terminationHandler
{
#ifndef IS_APP_STORE
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:manifestURL];
        
        if (dict) {
            
            NSString *remoteVersion = dict[@"items"][0][@"metadata"][@"bundle-version"];
            
            if ([self comparesToVersion:remoteVersion] == NSOrderedAscending) {
                
                NSString *minimumVersion = dict[@"items"][0][@"metadata"][@"minimum-version"];
                
                BOOL isForced = [self comparesToVersion:minimumVersion] == NSOrderedAscending;
                
                [[[UIApplication sharedApplication] keyWindow] makeKeyAndVisible];
                
                UIAlertController *alert
                = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"LOCAL_UPDATE_AVAILABLE", @"New Version Available: %@"), remoteVersion]
                                                      message:isForced ?
                   NSLocalizedString(@"LOCAL_UPDATE_AVAILABLE_FORCED_MSG", @"A newer version contains bugfix and improvements is now available. You must before you can continue to use this application.\n\nApplication will quit and unsaved data will be lost.") :
                   NSLocalizedString(@"LOCAL_UPDATE_AVAILABLE_MSG", @"A newer version contains bugfix and improvements is now available.\n\nApplication will quit and unsaved data will be lost.")
                                               preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction *defaultAction
                = [UIAlertAction actionWithTitle:NSLocalizedString(@"LOCAL_UPDATE_NOW", @"Update Now")
                                           style:UIAlertActionStyleCancel
                                         handler:^(UIAlertAction * action) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 if (terminationHandler() == YES) {
                                                     [[UIApplication sharedApplication] openURL:
                                                      [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                                                            kITMSServicesAction,
                                                                            [manifestURL absoluteString]]]];
                                                     kill(getpid(), SIGKILL);
                                                 }
                                             });
                                         }];
                
                UIAlertAction *cencelAction
                = [UIAlertAction actionWithTitle:isForced ?
                   NSLocalizedString(@"LOCAL_UPDATE_QUIT", @"Quit This App") :
                   NSLocalizedString(@"LOCAL_UPDATE_CANCEL", @"Cancel")
                                           style:UIAlertActionStyleDestructive
                                         handler:^(UIAlertAction * action) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 if (isForced) {
                                                     kill(getpid(), SIGKILL);
                                                 }
                                             });
                                         }];
                
                [alert addAction:cencelAction];
                [alert addAction:defaultAction];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[[[UIApplication sharedApplication] keyWindow] rootViewController]
                     presentViewController:alert
                     animated:YES
                     completion:nil];
                });
            }
        }
    });
#endif
}

+ (NSComparisonResult)comparesToVersion:(NSString *)version
{
    NSString *local
    = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    if (!local ||
        !version ||
        !local.length ||
        !version.length) {
        return NSOrderedSame;
    }
    
    NSArray *o = [local componentsSeparatedByString:@"."];
    NSArray *r = [version componentsSeparatedByString:@"."];
    
    NSInteger p = 0;
    
    while ([o count] > p ||
           [r count] > p) {
        NSInteger a = [o count] > p ? [[o objectAtIndex:p] integerValue] : 0;
        NSInteger b = [r count] > p ? [[r objectAtIndex:p] integerValue] : 0;
        if (a < b) {
            return NSOrderedAscending;
        } else if (a > b) {
            return NSOrderedDescending;
        }
        p++;
    }
    
    return NSOrderedSame;
}

@end
