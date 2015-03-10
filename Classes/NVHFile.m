//
//  NVHFile.m
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import "NVHFile.h"


@implementation NSFileManager (NVHFileSize)

- (unsigned long long)fileSizeOfItemAtPath:(NSString *)path {
    NSError *error = nil;
    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (error != nil)
    {
        return 0;
    }
    return [attributes fileSize];
}

@end


/** Using a small maximum total unit count instead of using self.fileSize
 * directly is recommended to let it work nicely with parent progress objects
 * because of this bug rdar://16444353 (http://openradar.appspot.com/radar?id=5775860476936192)
 *
 * Default is 100;
 */
const int64_t NVHProgressMaxTotalUnitCount = 100;


@interface NVHProgress : NSObject

- (void)setVirtualTotalUnitCount:(int64_t)virtualTotalUnitCount;
- (void)setVirtualCompletedUnitCount:(int64_t)virtualUnitCount;

@end


@interface NVHProgress ()

@property (nonatomic) NSProgress *progress;
@property (nonatomic, assign) CGFloat countFraction;

@end


@implementation NVHProgress

// Designated initializer;
- (instancetype)init
{
    self = [super init];
    if (!self) { return nil; }
    
    self.progress = [NSProgress progressWithTotalUnitCount:NVHProgressMaxTotalUnitCount];
    self.progress.cancellable = NO;
    self.progress.pausable = NO;
    
    return self;
}

- (void)setVirtualTotalUnitCount:(int64_t)virtualTotalUnitCount
{
    self.countFraction = NVHProgressMaxTotalUnitCount / (float)virtualTotalUnitCount;
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
    return [[NSFileManager defaultManager] fileSizeOfItemAtPath:self.filePath];
}

- (void)setupProgress
{
    self.progress = [[NVHProgress alloc] init];
}

- (void)updateProgressVirtualTotalUnitCount:(int64_t)virtualUnitCount
{
    [self.progress setVirtualTotalUnitCount:virtualUnitCount];
}

- (void)updateProgressVirtualCompletedUnitCount:(int64_t)virtualUnitCount
{
    [self.progress setVirtualCompletedUnitCount:virtualUnitCount];
}

- (void)updateProgressVirtualTotalUnitCountWithFileSize
{
    [self updateProgressVirtualTotalUnitCount:self.fileSize];
}

- (void)updateProgressVirtualCompletedUnitCountWithTotal
{
    [self.progress setVirtualCompletedUnitCountToTotal];
}

@end
