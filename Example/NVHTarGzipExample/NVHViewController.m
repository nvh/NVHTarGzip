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
@property (weak, nonatomic) IBOutlet UIButton *unTarGzipButton;
@property (weak, nonatomic) IBOutlet UIButton *unTarButton;
@end

@implementation NVHViewController

- (IBAction)unTarGzipFile:(UIButton*)sender {
    [self.progressView setProgress:0 animated:NO];
    self.unTarButton.enabled = NO;
    self.unTarGzipButton.enabled = NO;
    
    NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];
    NSString* keyPath = NSStringFromSelector(@selector(fractionCompleted));
    [progress addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial context:NVHProgressFractionCompletedObserverContext];
    [progress becomeCurrentWithPendingUnitCount:1];
    
    [[NVHTarGzip shared] unTarGzipFileAtPath:self.demoSourceTarGzFilePath toPath:self.demoDestinationFolderPath completion:^(NSError* error) {
    
        self.unTarButton.enabled = YES;
        self.unTarGzipButton.enabled = YES;
        
        [progress resignCurrent];
        [progress removeObserver:self forKeyPath:keyPath];
        
        if (error != nil) {
            self.progressLabel.text = error.localizedDescription;
        }
        else
        {
            self.progressLabel.text = @"Done!";
        }
    }];
}

- (IBAction)unTarFile:(UIButton*)sender {
    [self.progressView setProgress:0 animated:NO];
    self.unTarButton.enabled = NO;
    self.unTarGzipButton.enabled = NO;

    NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];
    NSString* keyPath = NSStringFromSelector(@selector(fractionCompleted));
    [progress addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial context:NVHProgressFractionCompletedObserverContext];
    [progress becomeCurrentWithPendingUnitCount:1];
    
    [[NVHTarGzip shared] unTarFileAtPath:self.demoSourceTarFilePath toPath:self.demoDestinationFolderPath completion:^(NSError* error) {
        self.unTarButton.enabled = YES;
        self.unTarGzipButton.enabled = YES;
        
        [progress resignCurrent];
        [progress removeObserver:self forKeyPath:keyPath];
        
        if (error != nil) {
            self.progressLabel.text = error.localizedDescription;
        }
        else
        {
            self.progressLabel.text = @"Done!";
        }
    }];
}

- (NSString *)demoSourceTarFilePath {
    return [[NSBundle mainBundle] pathForResource:@"misc.forsale" ofType:@"tar"];
}

- (NSString *)demoSourceTarGzFilePath {
    return [[NSBundle mainBundle] pathForResource:@"misc.forsale.tar" ofType:@"gz"];
}

- (NSString *)demoDestinationFolderPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = paths[0];
    return documentPath;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == NVHProgressFractionCompletedObserverContext) {
        NSProgress *progress = object;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.progressView setProgress:progress.fractionCompleted animated:YES];
            self.progressLabel.text = progress.localizedDescription;
        }];
    }
}

@end
