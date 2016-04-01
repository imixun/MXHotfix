//
//  MXArchiver.h
//  Pods
//
//  Created by NB-022 on 16/4/1.
//
//

#import <Foundation/Foundation.h>

@interface MXArchiver : NSObject

/**
 *  解压zip
 *  @param: strZipPath 解压包的路径
 *  @param: strDestinationPath 解压到的目录
 *  return: 返回解压路径
 */
+ (NSString *)unzipFileAtPath:(NSString *)strZipPath toDestination:(NSString *)strDestinationPath;

@end
