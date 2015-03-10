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

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (weak, nonatomic) IBOutlet UIButton *unTarButton;
@property (weak, nonatomic) IBOutlet UIButton *unGzipButton;
@property (weak, nonatomic) IBOutlet UIButton *unTarGzipButton;
@property (weak, nonatomic) IBOutlet UIButton *tarButton;
@property (weak, nonatomic) IBOutlet UIButton *gzipButton;
@property (weak, nonatomic) IBOutlet UIButton *tarGzipButton;

@property (nonatomic) NSProgress *progress;

@end


@implementation NVHViewController

- (void)setButtonsEnabled:(BOOL)enabled
{
    self.unTarButton.enabled = enabled;
    self.unGzipButton.enabled = enabled;
    self.unTarGzipButton.enabled = enabled;
    self.tarButton.enabled = enabled;
    self.gzipButton.enabled = enabled;
    self.tarGzipButton.enabled = enabled;
}

- (void)prepareAction
{
    [self.progressView setProgress:0 animated:NO];
    [self setButtonsEnabled:NO];
    
    self.progress = [NSProgress progressWithTotalUnitCount:1];
    NSString *keyPath = NSStringFromSelector(@selector(fractionCompleted));
    [self.progress addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionInitial context:NVHProgressFractionCompletedObserverContext];
    [self.progress becomeCurrentWithPendingUnitCount:1];
}

- (void)completeActionWithError:(NSError *)error
{
    [self setButtonsEnabled:YES];
    
    [self.progress resignCurrent];
    NSString *keyPath = NSStringFromSelector(@selector(fractionCompleted));
    [self.progress removeObserver:self forKeyPath:keyPath];
    
    if (error != nil) {
        self.progressLabel.text = error.localizedDescription;
    }
    else
    {
        self.progressLabel.text = @"Done!";
    }
}

- (IBAction)unTarFile:(UIButton*)sender
{
    [self prepareAction];
    [[NVHTarGzip sharedInstance] unTarFileAtPath:self.demoSourceTarFilePath
                                          toPath:self.demoDestinationFolderPath
                                      completion:^(NSError *error)
     {
         [self completeActionWithError:error];
     }];
}

- (IBAction)unGzipFile:(UIButton*)sender
{
    [self prepareAction];
    [[NVHTarGzip sharedInstance] unGzipFileAtPath:self.demoSourceTarGzipFilePath
                                              toPath:self.demoDestinationUnGzipPath
                                          completion:^(NSError *error)
     {
         [self completeActionWithError:error];
     }];
}

- (IBAction)unTarGzipFile:(UIButton*)sender
{
    [self prepareAction];
    [[NVHTarGzip sharedInstance] unTarGzipFileAtPath:self.demoSourceTarGzipFilePath
                                      toPath:self.demoDestinationFolderPath
                                  completion:^(NSError *error)
    {
        [self completeActionWithError:error];
    }];
}

- (IBAction)tarFile:(UIButton*)sender
{
    [self prepareAction];
    [[NVHTarGzip sharedInstance] tarFileAtPath:self.demoDestinationFolderPath
                                toPath:self.demoDestinationTarPath
                            completion:^(NSError *error)
    {
        [self completeActionWithError:error];
    }];
}

- (IBAction)gzipFile:(UIButton*)sender
{
    [self prepareAction];
    [[NVHTarGzip sharedInstance] gzipFileAtPath:self.demoSourceTarFilePath
                                            toPath:self.demoDestinationGzipPath
                                        completion:^(NSError *error)
     {
         [self completeActionWithError:error];
     }];
}

- (IBAction)tarGzipFile:(UIButton*)sender
{
    [self prepareAction];
    [[NVHTarGzip sharedInstance] tarGzipFileAtPath:self.demoDestinationFolderPath
                                            toPath:self.demoDestinationTarGzipPath
                                        completion:^(NSError *error)
    {
        [self completeActionWithError:error];
    }];
}

- (NSString *)demoSourceTarFilePath {
    return [[NSBundle mainBundle] pathForResource:@"misc.forsale" ofType:@"tar"];
}

- (NSString *)demoSourceTarGzipFilePath {
    return [[NSBundle mainBundle] pathForResource:@"misc.forsale.tar" ofType:@"gz"];
}

- (NSString*)demoDestinationTarPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentPath = paths[0];
    NSString* destinationPath = [documentPath stringByAppendingPathComponent:@"misc-forsale-tared.tar"];
    return destinationPath;
}

- (NSString*)demoDestinationTarGzipPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentPath = paths[0];
    NSString* destinationPath = [documentPath stringByAppendingPathComponent:@"misc-forsale-tared.tar.gz"];
    return destinationPath;
}

- (NSString*)demoDestinationUnGzipPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentPath = paths[0];
    NSString* destinationPath = [documentPath stringByAppendingPathComponent:@"misc-forsale-ungzipped.tar"];
    return destinationPath;
}

- (NSString*)demoDestinationGzipPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentPath = paths[0];
    NSString* destinationPath = [documentPath stringByAppendingPathComponent:@"misc-forsale-gzipped.tar.gz"];
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
