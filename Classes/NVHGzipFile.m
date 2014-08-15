//
//  NVHGzip.m
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import <zlib.h>
#import "NVHGzipFile.h"

NSString * const NVHGzipFileZlibErrorDomain = @"io.nvh.targzip.zlib.error";

@interface NVHGzipFile()
@property (nonatomic,assign) CGFloat fileSizeFraction;
@end

@implementation NVHGzipFile
- (NSProgress*)createProgressObject {
    NSProgress* progress = [NSProgress progressWithTotalUnitCount:self.maxTotalUnitCount];
    progress.cancellable = NO;
    progress.pausable = NO;
    return progress;
}

- (BOOL)inflateToPath:(NSString *)destinationPath error:(NSError**)error {
    NSProgress* progress = [self createProgressObject];
    return [self inflateToPath:destinationPath withProgress:progress error:error];
}

- (void)inflateToPath:(NSString *)destinationPath completion:(void(^)(NSError*))completion {
    NSProgress* progress = [self createProgressObject];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError* error = nil;
        [self inflateToPath:destinationPath withProgress:progress error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    });
}

- (BOOL)inflateToPath:(NSString *)destinationPath withProgress:(NSProgress*)progress error:(NSError**)error{
    [[NSFileManager defaultManager] createFileAtPath:destinationPath contents:nil attributes:nil];
    NSInteger result = [self inflateGzip:self.filePath toDest:destinationPath progress:progress];
    NSString* localizedDescription;
    switch (result) {
        case -1:
            localizedDescription = NSLocalizedString(@"Decompression failed", @"");
            break;
        case -2:
            localizedDescription = NSLocalizedString(@"Unexpected state from zlib", @"");
            break;
        default:
            localizedDescription = NSLocalizedString(@"Unknown error",@"");
            break;
    }
    [NSError errorWithDomain:NVHGzipFileZlibErrorDomain
                        code:result
                    userInfo:@{NSLocalizedDescriptionKey:localizedDescription}];
    BOOL success = result == 0;
    return success;
}

- (NSInteger)inflateGzip:(NSString *)sourcePath toDest:(NSString *)destPath progress:(NSProgress*)progress {
    CFWriteStreamRef writeStream = (__bridge CFWriteStreamRef)[NSOutputStream outputStreamToFileAtPath:destPath append:NO];
    CFWriteStreamOpen(writeStream);
    
	//Convert source path into something a C library can handle
	const char* sourceCString = [sourcePath cStringUsingEncoding:NSASCIIStringEncoding];
    
	gzFile *source = gzopen(sourceCString, "rb");
    
	unsigned int length = 1024*256;	//Thats like 256Kb
	void *buffer = malloc(length);
    
	while (true)
	{
		NSInteger read = gzread(source, buffer, length);
        NSInteger dataOffSet = gzoffset(source);
        progress.completedUnitCount = [self completionUnitCountForBytes:dataOffSet];
		if (read > 0)
		{
            CFWriteStreamWrite(writeStream, buffer, read);
		}
        
		else if (read == 0)
			break;
		else
        {
            if (buffer) {
                free(buffer);
            }
            if  (read == -1)
            {
                return -1;
            }
            else
            {
                return -2;
            }
        }

	}
    progress.completedUnitCount = progress.totalUnitCount;
	gzclose(source);
	free(buffer);
    CFWriteStreamClose(writeStream);
	return 0;
}
@end
