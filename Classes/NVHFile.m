//
//  NVHFile.m
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import "NVHFile.h"
@interface NVHFile()
@property (nonatomic,strong) NSString* filePath;
@property (nonatomic,assign) CGFloat fileSizeFraction;
@end
@implementation NVHFile
- (instancetype)initWithPath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.filePath = filePath;
        self.maxTotalUnitCount = 100;
    }
    return self;
}

- (void)setMaxTotalUnitCount:(CGFloat)maxTotalUnitCount {
    _maxTotalUnitCount = maxTotalUnitCount;
    self.fileSizeFraction = self.maxTotalUnitCount / self.fileSize;
}

- (unsigned long long)fileSize {
    NSError* error = nil;
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:&error];
    if (error != nil) {
        return 0;
    }
    return [attr fileSize];
}

-(int64_t)completionUnitCountForBytes:(unsigned long long)bytesCompleted {
    return roundf( self.fileSizeFraction * bytesCompleted );
}
@end
