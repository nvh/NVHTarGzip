//
//  NVHFile.h
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import <Foundation/Foundation.h>


@interface NSFileManager (NVHFileSize)

- (unsigned long long)fileSizeOfItemAtPath:(NSString *)path;

@end


@interface NVHFile : NSObject

@property (nonatomic, readonly) NSString *filePath;
@property (nonatomic, assign) unsigned long long fileSize;

- (instancetype)initWithPath:(NSString *)filePath;

- (void)setupProgress;
- (void)updateProgressVirtualTotalUnitCountWithFileSize;
- (void)updateProgressVirtualTotalUnitCount:(int64_t)virtualUnitCount;
- (void)updateProgressVirtualCompletedUnitCount:(int64_t)virtualUnitCount;
- (void)updateProgressVirtualCompletedUnitCountWithTotal;

@end
