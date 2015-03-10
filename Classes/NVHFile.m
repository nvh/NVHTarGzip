//
//  NVHFile.m
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import "NVHFile.h"


/** Using a small maximum total unit count instead of using self.fileSize
 * directly is recommended to let it work nicely with parent progress objects
 * because of this bug rdar://16444353 (http://openradar.appspot.com/radar?id=5775860476936192)
 *
 * Default is 100;
 */
const int64_t NVHProgressMaxTotalUnitCount = 100;


@interface NVHProgress : NSObject

- (instancetype)initWithVirtualTotalUnitCount:(int64_t)virtualTotalUnitCount;
- (void)setVirtualCompletedUnitCount:(int64_t)virtualUnitCount;

@end


@interface NVHProgress ()

@property (nonatomic) NSProgress *progress;
@property (nonatomic, assign) CGFloat countFraction;

@end


@implementation NVHProgress

- (instancetype)initWithVirtualTotalUnitCount:(int64_t)virtualTotalUnitCount
{
    self = [super init];
    if (!self) { return nil; }
    
    self.progress = [NSProgress progressWithTotalUnitCount:NVHProgressMaxTotalUnitCount];
    self.progress.cancellable = NO;
    self.progress.pausable = NO;
    
    self.countFraction = NVHProgressMaxTotalUnitCount / (float)virtualTotalUnitCount;

    return self;
}

- (void)setVirtualCompletedUnitCount:(int64_t)virtualUnitCount
{
    self.progress.completedUnitCount = roundf( self.countFraction * virtualUnitCount );
}

- (void)setVirtualCompletedUnitCountToTotal
{
    self.progress.completedUnitCount = NVHProgressMaxTotalUnitCount;
}

@end


@interface NVHFile ()

@property (nonatomic) NVHProgress *progress;
@property (nonatomic, strong) NSString *filePath;

@end


@implementation NVHFile

- (instancetype)initWithPath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.filePath = filePath;
    }
    return self;
}

- (unsigned long long)fileSize {
    NSError* error = nil;
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&error];
    if (error != nil) {
        return 0;
    }
    return [attr fileSize];
}

- (void)setupProgressForFileSize
{
    self.progress = [[NVHProgress alloc] initWithVirtualTotalUnitCount:self.fileSize];
}

- (void)updateProgressWithVirtualCompletedUnitCount:(int64_t)virtualUnitCount
{
    [self.progress setVirtualCompletedUnitCount:virtualUnitCount];
}

- (void)updateProgressWithTotalVirtualCompletedUnitCount
{
    [self.progress setVirtualCompletedUnitCountToTotal];
}

@end
