//
//  NVHViewController.m
//  NVHTarGzipExample
//
//  Created by Niels van Hoorn on 26/03/14.
//  Copyright (c) 2014 Niels van Hoorn. All rights reserved.
//

#import "NVHViewController.h"
#import "NVHTarGzip.h"

static void *NVHProgressFractionCompletedObserverContext = &NVHProgressFractionCompletedObserverContext;

@interface NVHViewController ()
@end

@implementation NVHViewController

-(IBAction)unTarGzipFile:(UIButton*)sender {
    sender.enabled = NO;
    NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];
    NSString* keyPath = NSStringFromSelector(@selector(fractionCompleted));
    [progress addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial context:NVHProgressFractionCompletedObserverContext];
    [progress becomeCurrentWithPendingUnitCount:1];
    [[NVHTarGzip shared] unTarGzipFileAtPath:self.demoSourceFilePath toPath:self.demoDestinationFilePath completion:^(NSError* error) {
        [progress resignCurrent];
        [progress removeObserver:self forKeyPath:keyPath];
        if (error != nil) {
            self.progressLabel.text = error.localizedDescription;
        }
    }];
}

-(NSString*)demoSourceFilePath {
    return [[NSBundle mainBundle] pathForResource:@"20news-19997.tar" ofType:@"gz"];
}

-(NSString*)demoDestinationFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentPath = paths[0];
    NSString* destinationPath = [documentPath stringByAppendingPathComponent:@"20news-19997"];
    return destinationPath;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == NVHProgressFractionCompletedObserverContext) {
        NSProgress* progress = object;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.progressView setProgress:progress.fractionCompleted animated:YES];
            self.progressLabel.text = progress.localizedDescription;
        }];
    }
}

@end
