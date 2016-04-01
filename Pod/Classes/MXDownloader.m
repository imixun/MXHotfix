//
//  MXDownloader.m
//  Pods
//
//  Created by 吴星煜 on 16/3/31.
//
//

#import "MXDownloader.h"
#import "AFNetworking.h"

#define BASE_URL    @"http://lyblddev.imaibei.com"

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
    _mHttpMgr = [AFHTTPSessionManager manager];
    [_mHttpMgr initWithBaseURL:[NSURL URLWithString:BASE_URL]
          sessionConfiguration:configuration];
}

- (void)getPatchForBuild:(NSString*)strBuild
                 success:(void (^)(NSString* strPatchUrl, NSString* strMD5))success
                 failure:(void (^)(NSError *error))failure
{
    NSDictionary *params=@{@"app_type":@"2", @"version_index":strBuild};
    [_mHttpMgr POST:@"/Api/Index/getVersionPatch"
        parameters:params
           success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
               NSLog(@"the responseObject is %@", responseObject);
               NSString* strReturn = [responseObject objectForKey:@"Return"];
               if ([@"0" isEqualToString:strReturn]) {
                   if (![responseObject objectForKey:@"Data"] || [[responseObject objectForKey:@"Data"] isKindOfClass:[NSNull class]]) {
                       success(nil, nil);
                   }
                   else {
                       success([[responseObject objectForKey:@"Data"] objectForKey:@"patch_url"], [[responseObject objectForKey:@"Data"] objectForKey:@"md5_rsa"]);
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
                                                                      success(filePath);
                                                                  }
                                                                  
                                                              }];
    [downloadTask resume];
}

@end
