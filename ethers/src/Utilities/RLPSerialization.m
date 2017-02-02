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


#import "RLPSerialization.h"

#import "SecureData.h"
#import "Utilities.h"


NSErrorDomain RLPSerializationErrorDomain = @"RLPCoderError";

static void appendByte(NSMutableData *data, unsigned char value) {
    [data appendBytes:&value length:1];
}


@implementation RLPSerialization


NSUInteger getDataLength(NSData *data, NSInteger offset, NSInteger length) {
    unsigned char *bytes = (unsigned char*)data.bytes;
    
    NSUInteger result = 0;
    for (NSInteger i = 0; i < length; i++) {
        result <<= 8;
        result += bytes[offset + i];
    }
    
    return result;
}

+ (NSData*)dataWithObject:(NSObject *)object error:(NSError *__autoreleasing *)error {
    if ([object isKindOfClass:[NSData class]]) {
        NSData *data = (NSData*)object;
        
        if (data.length == 1 && ((unsigned char*)(data.bytes))[0] <= 0x7f) {
            NSMutableData *result = [NSMutableData dataWithCapacity:1];
            [result appendData:data];
            return result;
    
        } else if (data.length <= 55) {
            NSMutableData *result = [NSMutableData dataWithCapacity:1 + data.length];
            appendByte(result, 0x80 + data.length);
            [result appendData:data];
            return result;
        
        } else {
            NSData *length = convertIntegerToData(data.length);
            NSMutableData *result = [NSMutableData dataWithCapacity:1 + length.length + data.length];
            appendByte(result, 0xb7 + length.length);
            [result appendData:length];
            [result appendData:data];
            return result;
        }
        
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray*)object;
        
        NSMutableData *payload = [NSMutableData data];
        for (NSObject *child in array) {
            NSError *childError = nil;
            NSData *encoded = [RLPSerialization dataWithObject:child error:&childError];
            if (childError) {
                NSDictionary *userInfo = @{
                                           @"reason": @"invalid child object",
                                           @"object": [object description],
                                           @"child": [child description]
                                           };
                *error = [NSError errorWithDomain:RLPSerializationErrorDomain code:kRLPSerializationErrorInvalidObject userInfo:userInfo];
                return nil;
            }
            [payload appendData:encoded];
        }
        
        if (payload.length <= 55) {
            NSMutableData *result = [NSMutableData dataWithCapacity:1 + payload.length];
            appendByte(result, 0xc0 + payload.length);
            [result appendData:payload];
            return result;
            
        } else {
            NSData *length = convertIntegerToData(payload.length);
            NSMutableData *result = [NSMutableData dataWithCapacity:1 + length.length + payload.length];
            appendByte(result, 0xf7 + length.length);
            [result appendData:length];
            [result appendData:payload];
            return result;
        }
    }
    
    if (error) {
        NSDictionary *userInfo = @{
                                   @"reason": @"invalid object",
                                   @"object": [object description]
                                   };
        *error = [NSError errorWithDomain:RLPSerializationErrorDomain code:kRLPSerializationErrorInvalidObject userInfo:userInfo];
    }
    
    return nil;
}

+ (NSObject*)_decode: (NSData*)data offset: (NSUInteger)offset consumed: (NSInteger*)consumed {
    
    if (data.length == 0) { return nil; }
    
    unsigned char *bytes = (unsigned char*)data.bytes;
    
    if (bytes[offset] >= 0xf8) {
        // Array with extra length prefix
        
        NSUInteger lengthLength = (bytes[offset] - 0xf7);
        if (offset + 1 + lengthLength > data.length) {
            *consumed = -1;
            return nil;
        }
        
        NSUInteger length = getDataLength(data, offset + 1, lengthLength);
        if (offset + 1 + lengthLength + length > data.length) {
            *consumed = -1;
            return nil;
        }

        NSMutableArray *result = [NSMutableArray array];
        NSUInteger childOffset = offset + 1 + lengthLength;
        while (childOffset < offset + 1 + lengthLength + length) {
            NSInteger childConsumed = 0;
            NSObject *child = [RLPSerialization _decode:data offset:childOffset consumed:&childConsumed];
            if (!child || childConsumed == -1) {
                *consumed = -1;
                return nil;
            }
            [result addObject:child];
            
            childOffset += childConsumed;
            if (childOffset > offset + 1 + lengthLength + length) {
                *consumed = -1;
                return nil;
            }
        }
        
        *consumed = 1 + lengthLength + length;
        return result;

    } else if (bytes[offset] >= 0xc0) {
        // Array (short-ish)

        NSUInteger length = (bytes[offset] - 0xc0);
        if (offset + 1 + length > data.length) {
            *consumed = -1;
            return nil;
        }
        
        NSMutableArray *result = [NSMutableArray array];
        NSUInteger childOffset = offset + 1;
        while (childOffset < offset + 1 + length) {
            NSInteger childConsumed = 0;
            NSObject *child = [RLPSerialization _decode:data offset:childOffset consumed:&childConsumed];
            if (!child || childConsumed == -1) {
                *consumed = -1;
                return nil;
            }
            [result addObject:child];
            
            childOffset += childConsumed;
            if (childOffset > offset + 1 + length) {
                *consumed = -1;
                return nil;
            }
        }
        
        *consumed = 1 + length;
        return result;

    } else if (bytes[offset] >= 0xb8) {
        // String with extra length prefix

        NSUInteger lengthLength = (bytes[offset] - 0xb7);
        if (offset + 1 + lengthLength > data.length) {
            *consumed = -1;
            return nil;
        }
        
        NSUInteger length = getDataLength(data, offset + 1, lengthLength);
        if (offset + 1 + lengthLength + length > data.length) {
            *consumed = -1;
            return nil;
        }

        NSMutableData *result = [NSMutableData dataWithCapacity:length];
        [result appendData:[data subdataWithRange:NSMakeRange(offset + 1 + lengthLength, length)]];
        *consumed = 1 + lengthLength + length;
        return result;

    } else if (bytes[offset] >= 0x80) {
        // String (short-ish)
        
        NSUInteger length = (bytes[offset] - 0x80);
        if (offset + 1 + length > data.length) {
            *consumed = -1;
            return nil;
        }
        
        NSMutableData *result = [NSMutableData dataWithCapacity:length];
        [result appendData:[data subdataWithRange:NSMakeRange(offset + 1, length)]];
        *consumed = 1 + length;
        return result;
    }

    NSMutableData *result = [NSMutableData dataWithCapacity:1];
    appendByte(result, bytes[offset]);
    *consumed = 1;
    return result;
}

+ (NSObject*)objectWithData:(NSData *)data error:(NSError *__autoreleasing *)error {
    NSInteger consumed = 0;
    NSObject *result = [RLPSerialization _decode:data offset:0 consumed:&consumed];
    if (consumed != data.length) { result = nil; }
    if (!result && error) {
        NSDictionary *userInfo = @{ @"reason": @"invalid data" };
        *error = [NSError errorWithDomain:RLPSerializationErrorDomain code:kRLPSerializationErrorInvalidData userInfo:userInfo];
    }
    return result;
}

@end
