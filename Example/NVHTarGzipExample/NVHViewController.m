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
@property (weak, nonatomic) IBOutlet UIButton *tarButton;

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

- (IBAction)tarFile:(UIButton*)sender {
    sender.enabled = NO;
    
    self.progressLabel.text = @"Packing...";
    
    //    NSProgress* progress = [NSProgress progressWithTotalUnitCount:1];
    //    NSString* keyPath = NSStringFromSelector(@selector(fractionCompleted));
    //    [progress addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial context:NVHProgressFractionCompletedObserverContext];
    //    [progress becomeCurrentWithPendingUnitCount:1];
    
    [[NVHTarGzip shared] tarFileAtPath:self.demoDestinationFolderPath toPath:self.demoDestinationTarPath completion:^(NSError* error) {
        //        [progress resignCurrent];
        //        [progress removeObserver:self forKeyPath:keyPath];
        
        if (error != nil) {
            self.progressLabel.text = error.localizedDescription;
        } else {
            self.progressLabel.text = @"Done!";
        }
        
        sender.enabled = YES;
    }];
}

- (NSString *)demoSourceTarFilePath {
    return [[NSBundle mainBundle] pathForResource:@"misc.forsale" ofType:@"tar"];
}

- (NSString *)demoSourceTarGzFilePath {
    return [[NSBundle mainBundle] pathForResource:@"misc.forsale.tar" ofType:@"gz"];
}

- (NSString*)demoDestinationTarPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentPath = paths[0];
    NSString* destinationPath = [documentPath stringByAppendingPathComponent:@"misc-forsale.tar"];
    return destinationPath;
}

- (NSString *)demoDestinationFolderPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = paths[0];
    NSString* destinationPath = [documentPath stringByAppendingPathComponent:@"20news-19997"];
    return destinationPath;
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
