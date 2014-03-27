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

static const int kNVHGzipChunkSize = 1024;
static const int kNVHGzipDefaultWindowBits = 15;
static const int kNVHGzipDefaultWindowBitsWithGZipHeader = 16 + kNVHGzipDefaultWindowBits;

@interface NVHGzipFile()
@property (nonatomic,assign) CGFloat fileSizeFraction;
@end

@implementation NVHGzipFile
- (void)inflateToPath:(NSString *)destinationPath completion:(void(^)(NSError*))completion {
    NSProgress* progress = [NSProgress progressWithTotalUnitCount:self.maxTotalUnitCount];
    progress.cancellable = NO;
    progress.pausable = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError* error = nil;
        [self inflateFileFromPath:self.filePath toPath:destinationPath withProgress:progress error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    });
}

- (void)inflateFileFromPath:(NSString*)sourcePath toPath:(NSString *)destinationPath withProgress:(NSProgress*)progress error:(NSError**)error{
    NSFileHandle* sourceFile = [NSFileHandle fileHandleForReadingAtPath:sourcePath];
    [[NSFileManager defaultManager] createFileAtPath:destinationPath contents:nil attributes:nil];
    NSFileHandle* destinationFile = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
    NSInteger result = [self inflateFile:sourceFile toFile:destinationFile progress:progress];
    if (result != Z_OK) {
        if (error) {
            *error = [NSError errorWithDomain:NVHGzipFileZlibErrorDomain code:result userInfo:nil];
        }
    }
    [sourceFile closeFile];
    [destinationFile closeFile];
}

/* Decompress from file source to file dest until stream ends or EOF.
 inf() returns Z_OK on success, Z_MEM_ERROR if memory could not be
 allocated for processing, Z_DATA_ERROR if the deflate data is
 invalid or incomplete, Z_VERSION_ERROR if the version of zlib.h and
 the version of the library linked do not match, or Z_ERRNO if there
 is an error reading or writing the files. */
- (NSInteger)inflateFile:(NSFileHandle*)sourceFile toFile:(NSFileHandle*)destinationFile progress:(NSProgress*)progress {
    FILE* source = fdopen([sourceFile fileDescriptor],"r");
    FILE* destination = fdopen([destinationFile fileDescriptor],"w");
    NSInteger ret;
    unsigned have;
    z_stream strm;
    unsigned char in[kNVHGzipChunkSize];
    unsigned char out[kNVHGzipChunkSize];
    /* allocate inflate state */
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = 0;
    strm.next_in = Z_NULL;
    ret = inflateInit2(&strm,kNVHGzipDefaultWindowBitsWithGZipHeader);
    if (ret != Z_OK)
        return ret;
    
    int64_t location = 0;
    /* decompress until deflate stream ends or end of file */
    do {
        strm.avail_in = (uInt)fread(in, 1, kNVHGzipChunkSize, source);
        location += strm.avail_in;
        progress.completedUnitCount = [self completionUnitCountForBytes:location];
        if (ferror(source)) {
            (void)inflateEnd(&strm);
            return Z_ERRNO;
        }
        if (strm.avail_in == 0)
            break;
        strm.next_in = in;
        
        /* run inflate() on input until output buffer not full */
        do {
            strm.avail_out = kNVHGzipChunkSize;
            strm.next_out = out;
            ret = inflate(&strm, Z_NO_FLUSH);
            assert(ret != Z_STREAM_ERROR);  /* state not clobbered */
            switch (ret) {
                case Z_NEED_DICT:
                    ret = Z_DATA_ERROR;     /* and fall through */
                case Z_DATA_ERROR:
                case Z_MEM_ERROR:
                    (void)inflateEnd(&strm);
                    return ret;
            }
            have = kNVHGzipChunkSize - strm.avail_out;
            if (fwrite(out, 1, have, destination) != have || ferror(destination)) {
                (void)inflateEnd(&strm);
                return Z_ERRNO;
            }
        } while (strm.avail_out == 0);
        
        /* done when inflate() says it's done */
    } while (ret != Z_STREAM_END);
    progress.completedUnitCount = progress.totalUnitCount;
    /* clean up and return */
    (void)inflateEnd(&strm);
    return ret == Z_STREAM_END ? Z_OK : Z_DATA_ERROR;
}
@end
