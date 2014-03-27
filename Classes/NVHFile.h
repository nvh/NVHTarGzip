//
//  NVHFile.h
//  Pods
//
//  Created by Niels van Hoorn on 26/03/14.
//
//

#import <Foundation/Foundation.h>

@interface NVHFile : NSObject
/** Using a small maximum total unit count instead of using self.fileSize
 * directly is recommended to let it work nicely with parent progress objects
 * because of this bug rdar://16444353 (http://openradar.appspot.com/radar?id=5775860476936192)
 *
 * Default is 100;
 */
@property (nonatomic,assign) CGFloat maxTotalUnitCount;
@property (nonatomic,readonly) NSString* filePath;
- (instancetype)initWithPath:(NSString*)filePath;
- (unsigned long long)fileSize;
- (int64_t)completionUnitCountForBytes:(unsigned long long)bytesCompleted;
@end
