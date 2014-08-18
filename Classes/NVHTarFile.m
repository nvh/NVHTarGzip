//
//  NVHTarFile.m
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
// Based on NSFileManager+Tar.m by Mathieu Hausherr Octo Technology on 25/11/11.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//



#pragma mark - Definitions

// Logging mode
// Comment this line for production
//#define TAR_VERBOSE_LOG_MODE

// const definition
#define TAR_BLOCK_SIZE                  512
#define TAR_TYPE_POSITION               156
#define TAR_NAME_POSITION               0
#define TAR_NAME_SIZE                   100
#define TAR_SIZE_POSITION               124
#define TAR_SIZE_SIZE                   12
#define TAR_MAX_BLOCK_LOAD_IN_MEMORY    100

// Error const
#define TAR_ERROR_DOMAIN                       @"io.nvh.targzip.tar.error"
#define TAR_ERROR_CODE_BAD_BLOCK               1
#define TAR_ERROR_CODE_SOURCE_NOT_FOUND        2

#import "NVHTarFile.h"

@interface NVHTarFile()
@end

@implementation NVHTarFile

- (NSProgress*)createProgressObject {
    NSProgress* progress = [NSProgress progressWithTotalUnitCount:self.maxTotalUnitCount];
    progress.cancellable = NO;
    progress.pausable = NO;
    return progress;
}

- (BOOL)createFilesAndDirectoriesAtPath:(NSString *)destinationPath error:(NSError **)error {
    NSProgress* progress = [self createProgressObject];
    return [self createFilesAndDirectoriesAtPath:destinationPath withProgress:progress error:error];
}

- (void)createFilesAndDirectoriesAtPath:(NSString *)destinationPath completion:(void (^)(NSError *))completion {
    NSProgress* progress = [self createProgressObject];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError* error = nil;
        [self createFilesAndDirectoriesAtPath:destinationPath withProgress:progress error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    });
}

- (BOOL)createFilesAndDirectoriesAtPath:(NSString *)path withProgress:(NSProgress*)progress error:(NSError **)error
{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    if ([filemanager fileExistsAtPath:self.filePath]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:self.filePath];
        BOOL result = [self createFilesAndDirectoriesAtPath:path withTarObject:fileHandle size:self.fileSize progress:progress error:error];
        [fileHandle closeFile];
        return result;
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Source file not found"
                                                         forKey:NSLocalizedDescriptionKey];
    
    if (error != NULL) *error = [NSError errorWithDomain:TAR_ERROR_DOMAIN code:TAR_ERROR_CODE_SOURCE_NOT_FOUND userInfo:userInfo];
    
    return NO;
}

- (BOOL)createFilesAndDirectoriesAtPath:(NSString *)path withTarObject:(id)object size:(unsigned long long)size progress:(NSProgress*)progress error:(NSError **)error
{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    [filemanager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]; //Create path on filesystem
    
    unsigned long long location = 0; // Position in the file
    while (location < size) {
        progress.completedUnitCount = [self completionUnitCountForBytes:location];
        unsigned long long blockCount = 1; // 1 block for the header
        switch ([NVHTarFile typeForObject:object atOffset:location]) {
            case '0': // It's a File
            {
                @autoreleasepool {
                    NSString *name = [NVHTarFile nameForObject:object atOffset:location];
#ifdef TAR_VERBOSE_LOG_MODE
                    NSLog(@"UNTAR - file - %@", name);
#endif
                    NSString *filePath = [path stringByAppendingPathComponent:name]; // Create a full path from the name
                    
                    unsigned long long size = [NVHTarFile sizeForObject:object atOffset:location];
                    
                    if (size == 0 && name.length) {
#ifdef TAR_VERBOSE_LOG_MODE
                        NSLog(@"UNTAR - empty_file - %@", filePath);
#endif
                        NSError *writeError;
                        BOOL copied = [@"" writeToFile:filePath
                                            atomically:YES
                                              encoding:NSUTF8StringEncoding
                                                 error:&writeError];
                        if (!copied) {
#ifdef TAR_VERBOSE_LOG_MODE
                            NSLog(@"UNTAR - error during writing empty_file - %@", writeError);
#endif
                        }
                        break;
                    }
                    
                    blockCount += (size - 1) / TAR_BLOCK_SIZE + 1; // size/TAR_BLOCK_SIZE rounded up
                    
                    [self writeFileDataForObject:object atLocation:(location + TAR_BLOCK_SIZE) withLength:size atPath:filePath];
                }
                break;
            }
                
            case '5': // It's a directory
            {
                @autoreleasepool {
                    NSString *name = [NVHTarFile nameForObject:object atOffset:location];
#ifdef TAR_VERBOSE_LOG_MODE
                    NSLog(@"UNTAR - directory - %@", name);
#endif
                    NSString *directoryPath = [path stringByAppendingPathComponent:name]; // Create a full path from the name
                    [filemanager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil]; //Write the directory on filesystem
                }
                break;
            }
                
            case '\0': // It's a nul block
            {
#ifdef TAR_VERBOSE_LOG_MODE
                NSLog(@"UNTAR - empty block");
#endif
                break;
            }
                
            case '1':
            case '2':
            case '3':
            case '4':
            case '6':
            case '7':
            case 'x':
            case 'g': // It's not a file neither a directory
            {
#ifdef TAR_VERBOSE_LOG_MODE
                NSLog(@"UNTAR - unsupported block");
#endif
                @autoreleasepool {
                    unsigned long long size = [NVHTarFile sizeForObject:object atOffset:location];
                    blockCount += ceil(size / TAR_BLOCK_SIZE);
                }
                break;
            }
                
            default: // It's not a tar type
            {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Invalid block type found"
                                                                     forKey:NSLocalizedDescriptionKey];
                
                if (error != NULL) *error = [NSError errorWithDomain:TAR_ERROR_DOMAIN code:TAR_ERROR_CODE_BAD_BLOCK userInfo:userInfo];
                
                return NO;
            }
        }
        
        location += blockCount * TAR_BLOCK_SIZE;
    }
    progress.completedUnitCount = progress.totalUnitCount;
    return YES;
}

#pragma mark Private methods implementation

+ (char)typeForObject:(id)object atOffset:(unsigned long long)offset
{
    char type;
    NSUInteger location = (NSUInteger)offset + TAR_TYPE_POSITION;
    memcpy(&type, [self dataForObject:object inRange:NSMakeRange(location, 1) orLocation:offset + TAR_TYPE_POSITION andLength:1].bytes, 1);
    return type;
}

+ (NSString *)nameForObject:(id)object atOffset:(unsigned long long)offset
{
    char nameBytes[TAR_NAME_SIZE + 1]; // TAR_NAME_SIZE+1 for nul char at end
    
    memset(&nameBytes, '\0', TAR_NAME_SIZE + 1); // Fill byte array with nul char
    NSUInteger location = (NSUInteger)offset + TAR_NAME_POSITION;
    memcpy(&nameBytes, [self dataForObject:object inRange:NSMakeRange(location, TAR_NAME_SIZE) orLocation:offset + TAR_NAME_POSITION andLength:TAR_NAME_SIZE].bytes, TAR_NAME_SIZE);
    return [NSString stringWithCString:nameBytes encoding:NSASCIIStringEncoding];
}

+ (unsigned long long)sizeForObject:(id)object atOffset:(unsigned long long)offset
{
    char sizeBytes[TAR_SIZE_SIZE + 1]; // TAR_SIZE_SIZE+1 for nul char at end
    
    memset(&sizeBytes, '\0', TAR_SIZE_SIZE + 1); // Fill byte array with nul char
    NSUInteger location = (NSUInteger)offset + TAR_SIZE_POSITION;
    memcpy(&sizeBytes, [self dataForObject:object inRange:NSMakeRange(location, TAR_SIZE_SIZE) orLocation:offset + TAR_SIZE_POSITION andLength:TAR_SIZE_SIZE].bytes, TAR_SIZE_SIZE);
    return strtol(sizeBytes, NULL, 8); // Size is an octal number, convert to decimal
}

- (void)writeFileDataForObject:(id)object atLocation:(unsigned long long)location withLength:(unsigned long long)length atPath:(NSString *)path
{
    if ([object isKindOfClass:[NSData class]]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:[object subdataWithRange:NSMakeRange((NSUInteger)location, (NSUInteger)length)] attributes:nil]; //Write the file on filesystem
    } else if ([object isKindOfClass:[NSFileHandle class]]) {
        if ([[NSData data] writeToFile:path atomically:NO]) {
            NSFileHandle *destinationFile = [NSFileHandle fileHandleForWritingAtPath:path];
            [object seekToFileOffset:location];
            
            unsigned long long maxSize = TAR_MAX_BLOCK_LOAD_IN_MEMORY * TAR_BLOCK_SIZE;
            
            while (length > maxSize) {
                @autoreleasepool {
                    [destinationFile writeData:[object readDataOfLength:(NSUInteger)maxSize]];
                    location += maxSize;
                    length -= maxSize;
                }
            }
            [destinationFile writeData:[object readDataOfLength:(NSUInteger)length]];
            [destinationFile closeFile];
        }
    }
}

+ (NSData *)dataForObject:(id)object inRange:(NSRange)range orLocation:(unsigned long long)location andLength:(unsigned long long)length
{
    if ([object isKindOfClass:[NSData class]]) {
        return [object subdataWithRange:range];
    } else if ([object isKindOfClass:[NSFileHandle class]]) {
        [object seekToFileOffset:location];
        return [object readDataOfLength:(NSUInteger)length];
    }
    
    return nil;
}
@end
