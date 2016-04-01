//
//  MXHotfix.m
//  Pods
//
//  Created by 吴星煜 on 16/3/31.
//
//

#import "MXHotfix.h"
#import "JPEngine.h"
#import "MXDownloader.h"

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
        // 1. 判断本地是否已经有该build的patch
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *docDir = [paths objectAtIndex:0];
        NSString *patchDir = [NSString stringWithFormat:@"%@/%@", docDir, PATCH_DIR];
        NSString* patchFile = [NSString stringWithFormat:@"%@/%@", patchDir, gBuild];
        
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
                //TODO:
                if (YES) {
                    [JPEngine startEngine];
                    NSString *script = [NSString stringWithContentsOfFile:patchFile encoding:NSUTF8StringEncoding error:nil];
                    [JPEngine evaluateScript:script];
                }
            }
        }
        
        // 3. 启动patch下载
        MXDownloader* downloader = [MXDownloader downloader];
        [downloader getPatchForBuild:gBuild
                             success:^(NSString *strPatchUrl, NSString* strMD5) {
                                 if (strPatchUrl) {
                                     // download patch
                                     [downloader downPatchFromUrl:strPatchUrl
                                                          success:^(NSString *strTmpPath) {
                                                              // 4. 解压
                                                              
                                                              // 5. 校验
                                                              
                                                          }
                                                          failure:^(NSError *error) {
                                                              // do nothing
                                                          }];
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

@end
