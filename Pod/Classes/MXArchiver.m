//
//  MXArchiver.m
//  Pods
//
//  Created by NB-022 on 16/4/1.
//
//

#import "MXArchiver.h"
#import "ZipArchive.h"

@implementation MXArchiver

+ (NSString *)unzipFileAtPath:(NSString *)strZipPath toDestination:(NSString *)strDestinationPath
{
    NSString *destinationPath;
    if (!strDestinationPath) { // 若解压目录为空，则默认和压缩文件目录一致
        destinationPath = [strZipPath stringByDeletingLastPathComponent];
    }else {
        destinationPath = strDestinationPath;
    }
    
    // 获得压缩包名称
    NSString *lastPath  = [strZipPath lastPathComponent];
    // 去掉扩展名后到文件名
    NSString *fileName  = [lastPath stringByDeletingPathExtension];
    // 解压
    BOOL unZipSuccess   = [SSZipArchive unzipFileAtPath:strZipPath toDestination:destinationPath];
    
    if (YES == unZipSuccess) { // 解压成功
        return [destinationPath stringByAppendingPathComponent:fileName];
    }else { // 解压失败
        return @"";
    }
    
}

@end
