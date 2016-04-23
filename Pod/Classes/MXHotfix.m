//
//  MXHotfix.m
//  Pods
//
//  Created by 吴星煜 on 16/3/31.
//
//

#import "MXHotfix.h"
#import "JPEngine.h"
#import <CrashReporter/CrashReporter.h>
#import "MXDownloader.h"
#import "MXArchiver.h"
#import "MXVertifier.h"

static NSString*    gAppKey;
static NSString*    gBuild;

#define PATCH_DIR   @"patch"

@implementation MXHotfix

+(void)startWithAppKey:(NSString*)strKey
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gAppKey = strKey;
        
        gBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    });
}

+(void)sync
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *patchRecord = [NSUserDefaults standardUserDefaults];
        // 1. 判断本地是否已经有该build的patch
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *docDir = [paths objectAtIndex:0];
        NSString *patchDir = [NSString stringWithFormat:@"%@/%@", docDir, PATCH_DIR];
        NSString* patchFile = [self patchPathForBuild:gBuild];
        
        NSFileManager* fileMgr = [NSFileManager defaultManager];
        if (NO == [fileMgr fileExistsAtPath:patchDir]) {
            [fileMgr createDirectoryAtPath:patchDir
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:nil];
        }
        else {
            if (YES == [fileMgr fileExistsAtPath:patchFile]) {
                // 2. 判断是否可以执行？
                NSString *strCrashCount = [patchRecord objectForKey:@"crash_count"];
                NSInteger iCrashCount = [strCrashCount integerValue];
                if (strCrashCount && 3 < [strCrashCount integerValue]) {
                    // crash 超 3 次，禁用 patch，直到后台更新 patch
                }
                else {
                    [JPEngine startEngine];
                    NSString *script = [NSString stringWithContentsOfFile:patchFile encoding:NSUTF8StringEncoding error:nil];
                    [JPEngine evaluateScript:script];
                }
                
                PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
                if ([crashReporter hasPendingCrashReport]) {
                    iCrashCount ++;
                    
                    [patchRecord setObject:[NSString stringWithFormat:@"%ld", iCrashCount] forKey:@"crash_count"];
                    [patchRecord synchronize];
                    
                    [crashReporter purgePendingCrashReport];
                }
            }
        }
        
        // 3. 启动patch下载
        MXDownloader* downloader = [MXDownloader downloader];
        [downloader getPatchForBuild:gBuild
                             success:^(NSString *strPatchUrl, NSString* strMD5) {
                                 if (strPatchUrl) {
                                     NSString *strCurrentPatch = [patchRecord objectForKey:@"patch_md5"];
                                     
                                     if (NO == [strMD5 isEqualToString:strCurrentPatch]) {
                                         // 和本地已存在的patch不同，才download patch
                                         [downloader downPatchFromUrl:strPatchUrl
                                                              success:^(NSString *strTmpPath) {
                                                                  // 4. 校验（是对压缩包校验的）
                                                                  // 计算文件的MD5值
                                                                  MXVertifier *vertf    = [[MXVertifier alloc] init];
                                                                  NSString *fileMD5     = [vertf getFileMD5WithPath:strTmpPath];
                                                                  
                                                                  if ([vertf vertifyWithEncryptMD5:strMD5 fileMD5:fileMD5]) {
                                                                      // 5. 解压
                                                                      NSString *srcPath = [MXArchiver unzipFileAtPath:strTmpPath toDestination:nil];
                                                                      NSString *toPath = [self patchPathForBuild:gBuild];
                                                                      NSFileManager *magr  = [NSFileManager defaultManager];
                                                                      if ([magr fileExistsAtPath:toPath]) {
                                                                          //若目标文件存在则先删除
                                                                          [magr removeItemAtPath:toPath error:nil];
                                                                      }
                                                                      if ([magr moveItemAtPath:srcPath
                                                                                        toPath:toPath
                                                                                         error:nil]) {
                                                                          [patchRecord setObject:strMD5 forKey:@"patch_md5"];
                                                                          [patchRecord synchronize];
                                                                      }
                                                                      else { //移动失败
                                                                          // do nothing
                                                                      }
                                                                  }
                                                              }
                                                              failure:^(NSError *error) {
                                                                  // do nothing
                                                              }];
                                     }
                                 }
                                 else {
                                     // 没有 patch url，相当于作废之前的（删除）
                                     [fileMgr removeItemAtPath:patchFile error:nil];
                                 }
                             }
                             failure:^(NSError *error) {
                                 // do nothing
                             }];
    });
}

+(NSString*)patchPathForBuild:(NSString*)build
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *docDir = [paths objectAtIndex:0];
    NSString *patchDir = [NSString stringWithFormat:@"%@/%@", docDir, PATCH_DIR];
    NSString* patchFile = [NSString stringWithFormat:@"%@/%@", patchDir, build];

    return patchFile;
}

@end
