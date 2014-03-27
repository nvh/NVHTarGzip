//
//  NVHGzip.h
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import <Foundation/Foundation.h>
#import "NVHFile.h"

@interface NVHGzipFile : NVHFile
- (void)inflateToPath:(NSString *)destinationPath completion:(void(^)(NSError*))completion;
@end
