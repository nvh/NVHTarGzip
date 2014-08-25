//
//  NVHTarGzip.m
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import "NVHTarGzip.h"
#import "NVHGzipFile.h"
#import "NVHTarFile.h"

@interface NVHTarGzip()

@end

@implementation NVHTarGzip
+(NVHTarGzip*)shared {
    static dispatch_once_t onceToken;
    static NVHTarGzip* tarGzip;
    dispatch_once(&onceToken, ^{
        tarGzip = [NVHTarGzip new];
    });
    return tarGzip;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths firstObject];
        self.cachePath = [cachesDirectory stringByAppendingPathComponent:NSStringFromClass([self class])];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}

- (BOOL)unGzipFileAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError**)error {
    NVHGzipFile* gzipFile = [[NVHGzipFile alloc] initWithPath:sourcePath];
    return [gzipFile inflateToPath:destinationPath error:error];
}

- (BOOL)unTarFileAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError**)error {
    NVHTarFile* tarFile = [[NVHTarFile alloc] initWithPath:sourcePath];
    return [tarFile createFilesAndDirectoriesAtPath:destinationPath error:error];
}

- (BOOL)unTarGzipFileAtPath:(NSString*)sourcePath toPath:(NSString*)destinationPath error:(NSError**)error {
    NSString* cachePath = [self cacheFilePathForSource:sourcePath];
    NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
    [progress becomeCurrentWithPendingUnitCount:1];
    [self unGzipFileAtPath:sourcePath toPath:cachePath error:error];
    [progress resignCurrent];
    if (*error != nil) {
        return NO;
    }
    [progress becomeCurrentWithPendingUnitCount:1];
    [self unTarFileAtPath:cachePath toPath:destinationPath error:error];
    NSError* removeCacheError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:cachePath error:&removeCacheError];
    if (*error != nil) {
        return NO;
    }
    if (removeCacheError != nil) {
        *error = removeCacheError;
        return NO;
    }
    [progress resignCurrent];
    return YES;
}


- (void)unGzipFileAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath completion:(void(^)(NSError*))completion {
    NVHGzipFile* gzipFile = [[NVHGzipFile alloc] initWithPath:sourcePath];
    [gzipFile inflateToPath:destinationPath completion:completion];
}

- (void)unTarFileAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath completion:(void(^)(NSError*))completion {
    NVHTarFile* tarFile = [[NVHTarFile alloc] initWithPath:sourcePath];
    [tarFile createFilesAndDirectoriesAtPath:destinationPath completion:completion];
}

- (void)unTarGzipFileAtPath:(NSString*)sourcePath toPath:(NSString*)destinationPath completion:(void(^)(NSError*))completion {
    NSString* cachePath = [self cacheFilePathForSource:sourcePath];
    NSProgress* progress = [NSProgress progressWithTotalUnitCount:2];
    [progress becomeCurrentWithPendingUnitCount:1];
    [self unGzipFileAtPath:sourcePath toPath:cachePath completion:^(NSError* gzipError) {
        [progress resignCurrent];
        if (gzipError != nil) {
            completion(gzipError);
            return;
        }
        [progress becomeCurrentWithPendingUnitCount:1];
        [self unTarFileAtPath:cachePath toPath:destinationPath completion:^(NSError* tarError) {
            NSError* error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:cachePath error:&error];
            [progress resignCurrent];
            if (tarError != nil) {
                error = tarError;
            }
            completion(error);
        }];
    }];
}


- (NSString*)cacheFilePathForSource:(NSString*)sourcePath {
    NSString *UUIDString = [[NSUUID UUID] UUIDString];
    NSString* filename = [[sourcePath lastPathComponent] stringByDeletingPathExtension];
    NSString* cacheFile = [filename stringByAppendingFormat:@"-%@",UUIDString];
    NSString* cachePath = [self.cachePath stringByAppendingPathComponent:cacheFile];
    if (![[cachePath pathExtension] isEqualToString:@"tar"]) {
        cachePath = [cachePath stringByAppendingPathExtension:@"tar"];
    }
    return cachePath;
}

@end
