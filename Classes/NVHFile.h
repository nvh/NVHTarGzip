//
//  NVHFile.h
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import <Foundation/Foundation.h>


@interface NVHFile : NSObject

@property (nonatomic, readonly) NSString *filePath;
@property (nonatomic, assign) unsigned long long fileSize;

- (instancetype)initWithPath:(NSString *)filePath;

- (void)setupProgressForFileSize;
- (void)updateProgressWithVirtualCompletedUnitCount:(int64_t)virtualUnitCount;
- (void)updateProgressWithTotalVirtualCompletedUnitCount;

@end
