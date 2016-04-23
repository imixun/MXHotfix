//
//  MXDownloader.m
//  Pods
//
//  Created by 吴星煜 on 16/3/31.
//
//

#import "MXDownloader.h"
#import "AFNetworking.h"
#import <CommonCrypto/CommonDigest.h>

#define BASE_URL    @"http://appmgr.imixun.com/"
#define APP_KEY     @"5718a5cc7c45fwjfiw"
#define APP_SECRET  @"f70551bc7e7388517aa9c5ce3eb8660d"

@interface MXDownloader()

@property (strong, nonatomic) AFHTTPSessionManager*    mHttpMgr;

@end

@implementation MXDownloader

+ (instancetype)downloader
{
    static MXDownloader *downloader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[MXDownloader alloc] init];
        [downloader initDownloader];
    });
    return downloader;
}

- (void)initDownloader
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _mHttpMgr = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:BASE_URL]
                                           sessionConfiguration:configuration];
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

    [_mHttpMgr GET:@"api/app/updateInfo"
         parameters:params
           progress:^(NSProgress * _Nonnull uploadProgress) {
           }
            success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
            failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                failure(error);
            }];
}

- (void)downPatchFromUrl:(NSString*)strUrl
                 success:(void (^)(NSString* strTmpPath))success
                 failure:(void (^)(NSError *error))failure
{
    NSURLSessionDownloadTask *downloadTask = [_mHttpMgr downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]]
                                                                       progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                       }
                                                                    destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                                        NSURL *tmpDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
                                                                        return [tmpDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
                                                                    }
                                                              completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                                  if (error) {
                                                                      failure(error);
                                                                  }
                                                                  else {
                                                                      success([filePath path]);
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
