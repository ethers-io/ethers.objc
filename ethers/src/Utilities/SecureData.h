/**
 *  MIT License
 *
 *  Copyright (c) 2017 Richard Moore <me@ricmoo.com>
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included
 *  in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 *  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */

/**
 *  SecureData
 *
 *  SecureData encapsulates a NSMutableData, which is securely allocated (and
 *  eventually released).
 *
 *  All NSData and NSString instances returned from this class have been
 *  initialized with a secure allocator, which keeps the underlying bytes
 *  in memory, and once released zeros the memory before giving it back to
 *  the OS.
 */

#import <Foundation/Foundation.h>

@interface SecureData : NSObject <NSCopying>

+ (NSData*)hexStringToData: (NSString*)hexString;
+ (NSString*)dataToHexString: (NSData*)data;

+ (NSData*)SHA256: (NSData*)data;
+ (NSData*)KECCAK256: (NSData*)data;


+ (instancetype)secureData;
+ (instancetype)secureDataWithCapacity: (NSUInteger)capacity;
+ (instancetype)secureDataWithData: (NSData*)data;
+ (instancetype)secureDataWithHexString: (NSString*)hexString;
+ (instancetype)secureDataWithLength: (NSUInteger)length;


@property (nonatomic, readonly) NSUInteger length;
@property (nonatomic, readonly) const void *bytes;
@property (nonatomic, readonly) void *mutableBytes;


- (void)append: (SecureData*)secureData;
- (void)appendByte:(unsigned char)byte;
- (void)appendData: (NSData*)data;

- (SecureData*)subdataWithRange: (NSRange)range;
- (SecureData*)subdataFromIndex: (NSUInteger)fromIndex;
- (SecureData*)subdataToIndex: (NSUInteger)toIndex;

- (SecureData*)SHA1;
- (SecureData*)SHA256;
- (SecureData*)KECCAK256;

- (NSData*)data;
- (NSString*)hexString;

@end
