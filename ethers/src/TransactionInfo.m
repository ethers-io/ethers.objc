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

#import "TransactionInfo.h"

#import "Account.h"
#import "ApiProvider.h"
#import "Payment.h"
#import "SecureData.h"

@implementation TransactionInfo

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
        
        _transactionHash = queryPath(info, @"dictionary:hash/hash");
        if (!_transactionHash) {
            NSLog(@"ERROR: Missing hash");
            return nil;
        }
        
        _blockHash = queryPath(info, @"dictionary:blockHash/hash");
        
        NSNumber *blockNumber = queryPath(info, @"dictionary:blockNumber/integer");
        if (blockNumber) {
            _blockNumber = [blockNumber integerValue];
        } else {
            _blockNumber = -1;
        }
        
        NSNumber *timestamp = queryPath(info, @"dictionary:timestamp/integer");
        if (!timestamp) {
            timestamp = queryPath(info, @"dictionary:timeStamp/integer");
        }
        if (timestamp) {
            _timestamp = [timestamp longLongValue];
        } else {
            _timestamp = [[NSDate date] timeIntervalSince1970];
        }
        
        _contractAddress = [Address addressWithString:queryPath(info, @"dictionary:contractAddress/string")];
        if (!_contractAddress) {
            _contractAddress = [Address addressWithString:queryPath(info, @"dictionary:creates/string")];
        }
        

        // @TODO: Is this allowed to be nil?
        _fromAddress = [Address addressWithString:queryPath(info, @"dictionary:from/string")];
        if (!_fromAddress) {
            NSLog(@"ERROR: Invalid fromAddress");
            return nil;
        }

        _toAddress = [Address addressWithString:queryPath(info, @"dictionary:to/string")];
        if (!_toAddress) {
            NSLog(@"ERROR: Invalid toAddress");
            return nil;
        }
        
        _gasLimit = queryPath(info, @"dictionary:gasLimit/bigNumber");
        if (!_gasLimit) {
            _gasLimit = queryPath(info, @"dictionary:gas/bigNumber");
            
            if (!_gasLimit) {
                NSLog(@"ERROR: Missing gasLimit");
                return nil;
            }
        }

        _gasPrice = queryPath(info, @"dictionary:gasPrice/bigNumber");
        if (!_gasPrice) {
            NSLog(@"ERROR: Missing gasPrice");
            return nil;
        }

        _gasUsed = queryPath(info, @"dictionary:gasUsed/bigNumber");

        _cumulativeGasUsed = queryPath(info, @"dictionary:cumulativeGasUsed/bigNumber");

        NSNumber *nonce = queryPath(info, @"dictionary:nonce/integer");
        if (!nonce) {
            NSLog(@"ERROR: Missing nonce");
            return nil;
        }
        _nonce = [nonce integerValue];
        
        _data = queryPath(info, @"dictionary:data/data");
        if (!_data) {
            _data = queryPath(info, @"dictionary:input/data");
            if (!_data) {
                _data = NullData;
            }
        }
        
        _value = queryPath(info, @"dictionary:value/bigNumber");
        if (!_value) {
            _value = [BigNumber constantZero];
        }
    }
    return self;
}

- (NSDictionary*)dictionaryRepresentation {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:16];
    
    [info setObject:[_transactionHash hexString] forKey:@"hash"];
    
    if (_blockHash) {
        [info setObject:[_blockHash hexString] forKey:@"blockHash"];
    }
    
    if (_blockNumber) {
        [info setObject:[NSString stringWithFormat:@"%ld", (long)_blockNumber] forKey:@"blockNumber"];
    }
    
    [info setObject:[NSString stringWithFormat:@"%ld", (long)_timestamp] forKey:@"timestamp"];
    
    if (_contractAddress) {
        [info setObject:_contractAddress.checksumAddress forKey:@"contractAddress"];
    }
    
    if (_fromAddress) {
        [info setObject:_fromAddress.checksumAddress forKey:@"from"];
    }
    
    if (_toAddress) {
        [info setObject:_toAddress.checksumAddress forKey:@"to"];
    }
    
    [info setObject:[_gasLimit decimalString] forKey:@"gasLimit"];
    
    if (_gasUsed) {
        [info setObject:[_gasUsed decimalString] forKey:@"gasUsed"];
    }
    
    [info setObject:[_gasPrice decimalString] forKey:@"gasPrice"];
    
    if (_cumulativeGasUsed) {
        [info setObject:[_cumulativeGasUsed decimalString] forKey:@"cumulativeGasUsed"];
    }
    
    [info setObject:[NSString stringWithFormat:@"%ld", (long)_nonce] forKey:@"nonce"];
    
    [info setObject:[SecureData dataToHexString:_data] forKey:@"data"];
    
    [info setObject:[_value decimalString] forKey:@"value"];
    
    return info;
}

+ (instancetype)transactionInfoFromDictionary: (NSDictionary*)info {
    return [[TransactionInfo alloc] initWithDictionary:info];
}

+ (instancetype)transactionInfoFromJSON:(NSString *)json {
    NSError *error = nil;
    NSDictionary *info = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error) {
        NSLog(@"ERROR: %@", error);
        return nil;
    }
    
    return [[TransactionInfo alloc] initWithDictionary:info];
}

+ (instancetype)transactionInfoWithPendingTransaction: (Transaction*)transaction hash: (Hash*)transactionHash {
    NSNumber *timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970]];
    
    NSData *data = transaction.data;
    if (!data) { data = [NSData data]; }
    
    NSDictionary *transactionInfo = @{
                                      @"hash": [transactionHash hexString],
                                      @"timestamp": [timestamp stringValue],
                                      @"from": transaction.fromAddress.checksumAddress,
                                      @"to": transaction.toAddress.checksumAddress,
                                      @"gasLimit": [transaction.gasLimit decimalString],
                                      @"gasPrice": [transaction.gasPrice decimalString],
                                      @"nonce": [@(transaction.nonce) stringValue],
                                      @"data": [SecureData dataToHexString:data],
                                      @"value": [transaction.value decimalString],
                                      };
    
    return [TransactionInfo transactionInfoFromDictionary:transactionInfo];
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
    return [_transactionHash hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[TransactionInfo class]]) { return NO; }
    return [_transactionHash isEqualToHash:((TransactionInfo*)object).transactionHash];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<TransactionInfo hash=%@ blockNumber=%ld blockHash=%@ timestamp=%@ from=%@ to=%@ contractAddress=%@ nonce=%ld gasLimit=%@ gasPrice=%@ gasUsed=%@ cumulativeGasUsed=%@ value=%@ data=%@>",
            [_transactionHash hexString], (unsigned long)_blockNumber, [_blockHash hexString], [NSDate dateWithTimeIntervalSince1970:_timestamp],
            _fromAddress, _toAddress, _contractAddress, (unsigned long)_nonce,
            [_gasLimit decimalString], [_gasPrice decimalString], [_gasUsed decimalString], [_cumulativeGasUsed decimalString],
            [Payment formatEther:_value], [SecureData dataToHexString:_data]
            ];
}

@end
