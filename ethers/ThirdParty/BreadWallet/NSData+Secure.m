//
//  NSData+Bitcoin.m
//  BreadWallet
//
//  Created by Aaron Voisine on 10/9/13.
//  Copyright (c) 2013 Aaron Voisine <voisine@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NSData+Secure.h"

#import "NSMutableData+Secure.h"

#import <CommonCrypto/CommonCrypto.h>

#include "sha3.h"

@implementation NSData (Bitcoin)

+ (instancetype)dataWithInteger:(NSUInteger)value {
    
    unsigned char bytes[sizeof(NSUInteger)];
    int offset = sizeof(bytes);
    
    while (value) {
        bytes[--offset] = (value & 0xff);
        value >>= 8;
    }

    return [NSData dataWithBytes:&bytes[offset] length:(sizeof(bytes) - offset)];
}

- (NSData *)SHA1 {
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(self.bytes, (CC_LONG)self.length, d.mutableBytes);
    return d;
}

- (NSData *)SHA256 {
    NSMutableData *d = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(self.bytes, (CC_LONG)self.length, d.mutableBytes);
    return d;
}

- (NSData*)KECCAK256 {
    NSMutableData *d = [NSMutableData dataWithLength:(256 / 8)];
    
    SHA3_CTX context;
    keccak_256_Init(&context);
    keccak_Update(&context, self.bytes, (size_t)self.length);
    keccak_Final(&context, d.mutableBytes);
    return d;
}

- (NSData *)reverse {
    NSUInteger len = self.length;
    NSMutableData *d = [NSMutableData dataWithLength:len];
    uint8_t *b1 = d.mutableBytes;
    const uint8_t *b2 = self.bytes;
    
    for (NSUInteger i = 0; i < len; i++) {
        b1[i] = b2[len - i - 1];
    }

    return d;
}

- (NSString*)hexEncodedString {
    const uint8_t *bytes = self.bytes;
    
    NSMutableString *hex = CFBridgingRelease(CFStringCreateMutable(SecureAllocator(), self.length * 2 + 2));
    [hex appendString:@"0x"];
    
    for (NSUInteger i = 0; i < self.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    
    return hex;
}

@end
