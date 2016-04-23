//
//  MXDownloader.m
//  Pods
//
//  Created by 吴星煜 on 16/3/31.
//
//

#import "MXDownloader.h"
#import <CommonCrypto/CommonDigest.h>

#define UPDATE_INFO_URL     @"http://appmgr.imixun.com/api/app/updateInfo"
#define APP_KEY             @"5718a5cc7c45fwjfiw"
#define APP_SECRET          @"f70551bc7e7388517aa9c5ce3eb8660d"

@implementation MXDownloader

+ (instancetype)downloader
{
    static MXDownloader *downloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[MXDownloader alloc] init];
    });
    return downloader;
}

- (void)getPatchForBuild:(NSString*)strBuild
                 success:(void (^)(NSString* strPatchUrl, NSString* strMD5))success
                 failure:(void (^)(NSError *error))failure
{
    NSString *strNonce = [self getRandomString];
    NSString *strSignature = [self getMD5NSString:[NSString stringWithFormat:@"1%@%@", APP_SECRET, strNonce]];

    NSDictionary *params=@{@"app_type":@"2",
                           @"version_index":strBuild,
                           @"app_key":APP_KEY,
                           @"nonce":strNonce,
                           @"signature":strSignature};
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                 delegate:nil
                                                            delegateQueue:[NSOperationQueue mainQueue]];
    NSString *strUrl = UPDATE_INFO_URL;
    NSInteger iIndex = 0;
    for (NSString *key in params) {
        if (0 == iIndex) {
            strUrl = [strUrl stringByAppendingString:[NSString stringWithFormat:@"?%@=%@", key, params[key]]];
        }
        else {
            strUrl = [strUrl stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", key, params[key]]];
        }
        iIndex ++;
    }
    
    NSURL * url = [NSURL URLWithString:strUrl];
    
    NSURLSessionDataTask * dataTask = [defaultSession dataTaskWithURL:url
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                        if(error == nil)
                                                        {
                                                            NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:data
                                                                                                                           options:NSJSONReadingMutableContainers
                                                                                                                             error:nil];
                                                            NSLog(@"the responseObject is %@", responseObject);
                                                            NSString* strReturn = [responseObject objectForKey:@"Return"];
                                                            if ([@"0" isEqualToString:strReturn]) {
                                                                if (![responseObject objectForKey:@"Data"] || [[responseObject objectForKey:@"Data"] isKindOfClass:[NSNull class]]) {
                                                                    success(nil, nil);
                                                                }
                                                                else {
                                                                    NSDictionary *dicData = [responseObject objectForKey:@"Data"];
                                                                    NSString *strUrl = [[dicData objectForKey:@"current_version_patch"] objectForKey:@"url"];
                                                                    NSString *strMD5 = [[dicData objectForKey:@"current_version_patch"] objectForKey:@"md5_rsa"];
                                                                    if (strUrl && strMD5) {
                                                                        success(strUrl, strMD5);
                                                                    }
                                                                    else {
                                                                        success(nil, nil);
                                                                    }
                                                                }
                                                            }
                                                            else {
                                                                failure([NSError errorWithDomain:@"server" code:[strReturn integerValue] userInfo:nil]);
                                                            }
                                                        }
                                                        else {
                                                            failure(error);
                                                        }
                                                    }];
    
    [dataTask resume];
}

- (void)downPatchFromUrl:(NSString*)strUrl
                 success:(void (^)(NSString* strTmpPath))success
                 failure:(void (^)(NSError *error))failure
{
    NSString *fileName = [strUrl lastPathComponent];
    NSURL * url = [NSURL URLWithString:strUrl];
    
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfigObject
                                                                 delegate:nil
                                                            delegateQueue:[NSOperationQueue mainQueue]];
    
    NSURLSessionDownloadTask * downloadTask = [defaultSession downloadTaskWithURL:url
                                                                completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                                    if(error == nil)
                                                                    {
                                                                        // 保存在tmp目录，按照url的文件名
                                                                        NSString *dstPath = [NSString stringWithFormat:@"%@/%@", [[location path] stringByDeletingLastPathComponent], fileName];
                                                                        [[NSFileManager defaultManager] moveItemAtPath:[location path]
                                                                                                                toPath:dstPath
                                                                                                                 error:nil];
                                                                        success(dstPath);
                                                                    }
                                                                    else {
                                                                        failure(error);
                                                                    }
                                                                }];
    
    [downloadTask resume];
}

#pragma mark - private functions

- (NSString *)getRandomString{
    int NUMBER_OF_CHARS = 10;
    char data[NUMBER_OF_CHARS];
    for (int x=0;x<NUMBER_OF_CHARS;data[x++] = (char)('A' + (arc4random_uniform(26))));
    return [[NSString alloc] initWithBytes:data length:NUMBER_OF_CHARS encoding:NSUTF8StringEncoding];
}

- (NSString*)getMD5NSString:(NSString*)strOrigin
{
    const char *original_str = [strOrigin UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
    {
        [hash appendFormat:@"%02X", result[i]];
    }
    NSString *mdfiveString = [hash lowercaseString];
    return mdfiveString;
}

@end
