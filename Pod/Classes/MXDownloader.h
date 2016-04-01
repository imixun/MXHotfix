//
//  MXDownloader.h
//  Pods
//
//  Created by 吴星煜 on 16/3/31.
//
//

#import <Foundation/Foundation.h>

@interface MXDownloader : NSObject

+ (instancetype)downloader;

- (void)getPatchForBuild:(NSString*)strBuild
                 success:(void (^)(NSString* strPatchUrl))success
                 failure:(void (^)(NSError *error))failure;

- (void)downPatchFromUrl:(NSString*)strUrl
                 success:(void (^)(NSString* strPatchUrl))success
                 failure:(void (^)(NSError *error))failure;

@end
