//
//  MXVertifier.m
//  Pods
//
//  Created by NB-022 on 16/4/6.
//
//

#import "MXVertifier.h"
#import <CommonCrypto/CommonCrypto.h>
#include <OpenSSL/rsa.h>
#include <OpenSSL/pem.h>
#include <OpenSSL/err.h>
#include <OpenSSL/md5.h>

typedef enum {
    RSA_PADDING_TYPE_NONE       = RSA_NO_PADDING,
    RSA_PADDING_TYPE_PKCS1      = RSA_PKCS1_PADDING,
    RSA_PADDING_TYPE_SSLV23     = RSA_SSLV23_PADDING
}RSA_PADDING_TYPE;

#define PADDING   RSA_PADDING_TYPE_PKCS1
#define FileHashDefaultChunkSizeForReadingData 1024*8

@implementation MXVertifier
{
    RSA *_rsa_pub;
}

- (instancetype)init
{
    if (self = [super init]) {
        // 公钥
        NSString *public_key_string = @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCfgJeQprvYbvnujGxYnwttMu5jzT8HehNjrKCgPBE4xdzcHcLKPn1NXRSGZK2+My3tobrjVXnW4SmEi8unyukmBuvfkLs1uzmgyTWz5Bi6sxByHbmtFdf0OS++HPrfNRdGvH6RDKAxxDFNOZjI3bNOiWuHDsk6dUEdBb1xundilwIDAQAB";
        // 导入公钥
        [self importKeyWithString:public_key_string];
    }
    return self;
}

- (void)dealloc
{
    _rsa_pub = NULL;
}

- (BOOL)importKeyWithString:(NSString *)keyString
{
    if (!keyString) {
        return NO;
    }
    
    BOOL status = NO;
    BIO *bio    = NULL;
    RSA *rsa    = NULL;
    bio         = BIO_new(BIO_s_file());
    
    NSString* temPath            = NSTemporaryDirectory();
    NSString* rsaFilePath        = [temPath stringByAppendingPathComponent:@"RSAKEY"];
    NSString* formatRSAKeyString = [self formatRSAKeyWithKeyString:keyString];
    BOOL writeSuccess = [formatRSAKeyString writeToFile:rsaFilePath
                                             atomically:YES
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
    if (!writeSuccess) {
        return NO;
    }
    
    const char* cPath = [rsaFilePath cStringUsingEncoding:NSUTF8StringEncoding];
    BIO_read_filename(bio, cPath);
    
    rsa      = PEM_read_bio_RSA_PUBKEY(bio, NULL, NULL, NULL);
    _rsa_pub = rsa;
    if (rsa != NULL) {
        status = YES;
    } else {
        status = NO;
    }
    BIO_free_all(bio);
    [[NSFileManager defaultManager] removeItemAtPath:rsaFilePath error:nil];
    return status;
}

- (int)getBlockSizeWithRSA_PADDING_TYPE:(RSA_PADDING_TYPE)padding_type andRSA:(RSA*)rsa
{
    int len = RSA_size(rsa);
    if (padding_type == RSA_PADDING_TYPE_PKCS1 || padding_type == RSA_PADDING_TYPE_SSLV23) {
        len -= 11;
    }
    return len;
}

/** 格式化公钥 */
- (NSString*)formatRSAKeyWithKeyString:(NSString*)keyString
{
    NSInteger lineNum       = -1;
    NSMutableString *result = [NSMutableString string];
    [result appendString:@"-----BEGIN PUBLIC KEY-----\n"];
    
    lineNum   = 76;
    int count = 0;
    
    for (int i = 0; i < [keyString length]; ++i) {
        unichar c = [keyString characterAtIndex:i];
        if (c == '\n' || c == '\r') {
            continue;
        }
        [result appendFormat:@"%c", c];
        if (++count == lineNum) {
            [result appendString:@"\n"];
            count = 0;
        }
    }
    [result appendString:@"\n-----END PUBLIC KEY-----"];
    return result;
}

- (NSString *)decryptWithString:(NSString *)content
{
    if (!_rsa_pub) {
        NSLog(@"please import public key first");
        return nil;
    }
    int status;
    NSData *data   = [[NSData alloc] initWithBase64EncodedString:content
                                                         options:NSDataBase64DecodingIgnoreUnknownCharacters];
    int length     = (int)[data length];
    
    NSInteger flen = [self getBlockSizeWithRSA_PADDING_TYPE:PADDING andRSA:_rsa_pub];
    char *decData  = (char*)malloc(flen);
    bzero(decData, flen);
    
    status = RSA_public_decrypt(length, (unsigned char*)[data bytes], (unsigned char*)decData, _rsa_pub, PADDING);
    
    if (status) {
        NSMutableString *decryptString = [[NSMutableString alloc] initWithBytes:decData
                                                                         length:strlen(decData)
                                                                       encoding:NSASCIIStringEncoding];
        free(decData);
        decData = NULL;
        return decryptString;
    }
    
    free(decData);
    decData = NULL;
    return nil;
}

#pragma mark - start 获取文件的MD5值
- (NSString*)getFileMD5WithPath:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData)
{
    // 声明所需的变量，计算结果result和读操作流readStream
    CFStringRef result         = NULL;
    CFReadStreamRef readStream = NULL;
    
    // 获得文件的URL
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                                     (CFStringRef)filePath,
                                                     kCFURLPOSIXPathStyle,
                                                     (Boolean)false);
    if (!fileURL) goto done;
    
    // 创建并打开一个读操作流
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,(CFURLRef)fileURL);
    if (!readStream) goto done;
    
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    // 确保chunkSizeForReadingData是有效可用
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    
    // 将数据赋值给hashObject
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    // 检查读操作是否成功
    didSucceed = !hasMoreData;
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // 若读操作失败，则终止
    if (!didSucceed) goto done;
    
    // 计算结果result字符串
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}
#pragma mark end 获取文件的MD5值

#pragma mark - start 校验MD5值是否相同
- (BOOL)vertifyWithEncryptMD5:(NSString *)strEncryptMD5 fileMD5:(NSString *)strFileMD5
{
    NSString *strDecryptMD5 = [self decryptWithString:strEncryptMD5];
    if ([strDecryptMD5 isEqualToString:strFileMD5]) {
        return YES;
    }
    return NO;
}
#pragma mark end 校验MD5值是否相同

#pragma mark - start 移动文件至document的patch文件夹下
- (BOOL)moveItemAtPath:(NSString *)strSrcPath
{
    NSArray *paths       = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir     = [paths objectAtIndex:0];
    NSString *toPath     = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"patch/%@", [strSrcPath lastPathComponent]]];
    NSFileManager *magr  = [NSFileManager defaultManager];
    NSError *error;
    BOOL didSucceed      = [magr moveItemAtPath:strSrcPath
                                         toPath:toPath
                                          error:&error];
    return didSucceed;
}
#pragma mark end 移动文件至document的patch文件夹下

@end
