//
//  MXVertifier.h
//  Pods
//
//  Created by NB-022 on 16/4/6.
//
//

#import <Foundation/Foundation.h>

@interface MXVertifier : NSObject

/**
 * 解密
 * @param  : content 需要解密的文本
 * @return : 返回解密后的文本
 */
- (NSString *)decryptWithString:(NSString *)content;

/**
 * 获取文件的MD5值
 * @param  : path 文件路径
 * @return : 返回文件的MD5值
 */
- (NSString*)getFileMD5WithPath:(NSString*)path;

/**
 * 校验MD5值
 * @param  : strEncryptMD5 服务端返回的MD5值
 * @param  : strFileMD5 客户端计算的文件的MD5值
 * @return : 校验成功与否
 */
- (BOOL)vertifyWithEncryptMD5:(NSString *)strEncryptMD5 fileMD5:(NSString *)strFileMD5;

/**
 * 移动文件到document的patch文件夹下
 * @param  : strSrcPath 源文件路径
 * @param  : fileName   需要保存的文件名
 * @return : 是否移动成功
 */
- (BOOL)moveAndCoverItemAtPath:(NSString *)strSrcPath targetFileName:(NSString *)fileName;

@end
