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

#import "Hash.h"

#import "SecureData.h"


static Hash *ZeroHash = nil;


@implementation Hash

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unsigned char nullBytes[32];
        memset(nullBytes, 0, sizeof(nullBytes));
        ZeroHash = [Hash hashWithData:[NSData dataWithBytes:nullBytes length:sizeof(nullBytes)]];
    });
}

- (instancetype)initWithData: (NSData*)data {
    if (data.length != 32) { return nil; }
    
    self = [super init];
    if (self) {
        _data = [data copy];
        _hexString = [SecureData dataToHexString:_data];
    }
    return self;
}

- (BOOL)isZeroHash {
    return [self isEqualToHash:ZeroHash];
}

+ (instancetype)hashWithData: (NSData*)data {
    return [[Hash alloc] initWithData:data];
}

+ (instancetype)hashWithHexString: (NSString*)hexString {
    return [[Hash alloc] initWithData:[SecureData hexStringToData:hexString]];
}

+ (Hash*)zeroHash {
    return ZeroHash;
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}


#pragma mark - NSObject

- (BOOL)isEqualToHash: (Hash*)hash {
    return [self isEqual:hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Hash class]]) { return NO; }
    return [_hexString isEqualToString:((Hash*)object).hexString];
}

- (NSUInteger)hash {
    return [_hexString hash];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<Hash %@>", _hexString];
}

@end
