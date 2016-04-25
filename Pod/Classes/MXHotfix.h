//
//  MXHotfix.h
//  Pods
//
//  Created by 吴星煜 on 16/3/31.
//
//

#import <Foundation/Foundation.h>

@interface MXHotfix : NSObject

+(void)startWithAppKey:(NSString*)strKey
             appSecret:(NSString*)strSecret;

/*
    (1)本地是否已经有patch，如果有就执行；
    (2)异步网络请求patch，保存本地，下次执行；
    (3)unzip，RSA 校验；
    (4)crash 检测，到了门限值，下次启动就不执行patch
 */
+(void)sync;

@end
