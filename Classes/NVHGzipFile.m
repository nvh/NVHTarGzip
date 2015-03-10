//
//  NVHGzip.m
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import <zlib.h>
#import "NVHGzipFile.h"

NSString *const NVHGzipFileZlibErrorDomain = @"io.nvh.targzip.zlib.error";


typedef NS_ENUM(NSInteger, NVHGzipFileErrorType)
{
    NVHGzipFileErrorTypeNone = 0,
    NVHGzipFileErrorTypeDecompressionFailed = -1,
    NVHGzipFileErrorTypeUnexpectedZlibState = -2,
    NVHGzipFileErrorTypeSourceFilePathIsNil = -3,
    NVHGzipFileErrorTypeUnknown = -4
};


@interface NVHGzipFile ()

@property (nonatomic,assign) CGFloat fileSizeFraction;

@end


@implementation NVHGzipFile

- (BOOL)inflateToPath:(NSString *)destinationPath error:(NSError **)error {
    [self setupProgress];
    return [self innerInflateToPath:destinationPath error:error];
}

- (void)inflateToPath:(NSString *)destinationPath completion:(void(^)(NSError *))completion {
    [self setupProgress];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        [self innerInflateToPath:destinationPath error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    });
}

- (BOOL)innerInflateToPath:(NSString *)destinationPath error:(NSError **)error {
    [self updateProgressVirtualTotalUnitCountWithFileSize];
    
    NVHGzipFileErrorType result = NVHGzipFileErrorTypeNone;
    
    if (self.filePath)
    {
        [[NSFileManager defaultManager] createFileAtPath:destinationPath contents:nil attributes:nil];
        result = [self inflateGzip:self.filePath destination:destinationPath];
    }
    else
    {
        result = NVHGzipFileErrorTypeSourceFilePathIsNil;
    }

    BOOL success = (result == NVHGzipFileErrorTypeNone);

    if (!success && error != NULL) {
        NSString *localizedDescription = nil;

        switch (result) {
            case NVHGzipFileErrorTypeDecompressionFailed:
                localizedDescription = NSLocalizedString(@"Decompression failed", @"");
                break;
            case NVHGzipFileErrorTypeUnexpectedZlibState:
                localizedDescription = NSLocalizedString(@"Unexpected state from zlib", @"");
                break;
            case NVHGzipFileErrorTypeSourceFilePathIsNil:
                localizedDescription = NSLocalizedString(@"Source file path is nil", @"");
                break;
            case NVHGzipFileErrorTypeUnknown:
                localizedDescription = NSLocalizedString(@"Unknown error",@"");
                break;
            default:
                localizedDescription = @"";
                break;
        }

        *error = [NSError errorWithDomain:NVHGzipFileZlibErrorDomain
                                     code:result
                                 userInfo:@{NSLocalizedDescriptionKey:localizedDescription}];
    }

    return success;
}

- (NSInteger)inflateGzip:(NSString *)sourcePath destination:(NSString *)destinationPath {
    CFWriteStreamRef writeStream = (__bridge CFWriteStreamRef)[NSOutputStream outputStreamToFileAtPath:destinationPath append:NO];
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
        [self updateProgressVirtualCompletedUnitCount:dataOffSet];
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
                return NVHGzipFileErrorTypeDecompressionFailed;
            }
            else
            {
                return NVHGzipFileErrorTypeUnexpectedZlibState;
            }
        }

	}
    [self updateProgressVirtualCompletedUnitCountWithTotal];
	gzclose(source);
	free(buffer);
    CFWriteStreamClose(writeStream);
	return NVHGzipFileErrorTypeNone;
}
@end
