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

#import "BlockInfo.h"

#import "ApiProvider.h"

@implementation BlockInfo

static NSData *NullData = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NullData = [NSData data];
    });
}

- (instancetype)initWithDictionary: (NSDictionary*)info {
    self = [super init];
    if (self) {        
        _blockHash = queryPath(info, @"dictionary:hash/hash");
        if (!_blockHash) {
            NSLog(@"ERROR: Missing hash");
            return nil;
        }
        
        NSNumber *blockNumber = queryPath(info, @"dictionary:number/integer");
        if (!blockNumber) {
            NSLog(@"ERROR: Missing blockNumber");
            return nil;
        }
        _blockNumber = [blockNumber integerValue];
        
        _parentHash = queryPath(info, @"dictionary:parentHash/hash");
        if (!_blockHash) {
            NSLog(@"ERROR: Missing hash");
            return nil;
        }

        NSNumber *timestamp = queryPath(info, @"dictionary:timestamp/integer");
        if (!timestamp) {
            NSLog(@"ERROR: Missing timestamp");
            return nil;
        }
        _timestamp = [timestamp longLongValue];

        NSNumber *nonce = queryPath(info, @"dictionary:nonce/integer");
        if (!nonce) {
            NSLog(@"ERROR: Missing nonce");
            return nil;
        }
        _nonce = [nonce integerValue];
        
        _extraData = queryPath(info, @"dictionary:extraData/data");
        if (!_extraData) { _extraData = NullData; }

        _gasLimit = queryPath(info, @"dictionary:gasLimit/bigNumber");
        if (!_gasLimit) {
            NSLog(@"ERROR: Missing gasLimit");
            return nil;
        }
        
        _gasUsed = queryPath(info, @"dictionary:gasUsed/bigNumber");
        if (!_gasUsed) {
            NSLog(@"ERROR: Missing gasUsed");
            return nil;
        }
    }
    return self;
}

- (NSDictionary*)dictionaryRepresentation {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:16];

    [info setObject:[_blockHash hexString] forKey:@"hash"];
    [info setObject:[NSString stringWithFormat:@"%ld", (long)_blockNumber] forKey:@"number"];
    [info setObject:[_parentHash hexString] forKey:@"parentHash"];
    [info setObject:[NSString stringWithFormat:@"%ld", (long)_timestamp] forKey:@"timestamp"];
    [info setObject:[NSString stringWithFormat:@"%ld", (long)_nonce] forKey:@"nonce"];
    [info setObject:_extraData forKey:@"extraData"];
    [info setObject:[_gasLimit decimalString] forKey:@"gasLimit"];
    [info setObject:[_gasUsed decimalString] forKey:@"gasUsed"];
    
    return info;
}

+ (instancetype)blockInfoFromDictionary: (NSDictionary*)info {
    return [[BlockInfo alloc] initWithDictionary:info];
}

+ (instancetype)blockInfoFromJSON:(NSString *)json {
    NSError *error = nil;
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        NSLog(@"ERROR: %@", error);
        return nil;
    }
    
    return [[BlockInfo alloc] initWithDictionary:info];
}

- (NSString*)jsonRepresentation {
    NSDictionary *info = [self dictionaryRepresentation];
    
    NSError *error = nil;
    NSData *json = [NSJSONSerialization dataWithJSONObject:info options:0 error:&error];
    if (error) {
        NSLog(@"ERROR: %@", error);
        return nil;
    }
    
    return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}


#pragma mark - NSObject

- (NSUInteger)hash {
    return [_blockHash hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[BlockInfo class]]) { return NO; }
    return [_blockHash isEqualToHash:((BlockInfo*)object).blockHash];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<BlockInfo hash=%@ blockNumber=%ld parentHash=%@ timestamp=%@ nonce=%ld extraData=%@  gasLimit=%@ gasUsed=%@>",
            [_blockHash hexString], (unsigned long)_blockNumber, [_parentHash hexString], [NSDate dateWithTimeIntervalSince1970:_timestamp],
            (unsigned long)_nonce, _extraData, [_gasLimit decimalString], [_gasUsed decimalString]];
}


@end
