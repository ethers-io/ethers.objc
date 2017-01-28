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

#import "Transaction.h"

#import "Account.h"
#import "RLPSerialization.h"
#import "NSData+Secure.h"
#import "NSMutableData+Secure.h"
#import "NSString+Secure.h"

static NSErrorDomain ErrorDomain = @"io.ethers.TransactionError";

NSData *stripDataZeros(NSData *data) {
    const char *bytes = data.bytes;
    NSUInteger offset = 0;
    while (offset < data.length && bytes[offset] == 0) { offset++; }
    return [data subdataWithRange:NSMakeRange(offset, data.length - offset)];
}

static NSData *NullData = nil;


#pragma mark -
#pragma mark - Signature (private)

@interface Signature ()

- (instancetype)initWithData: (NSData*)data recoveryParam: (char)recoveryParam;

@end


#pragma mark -
#pragma mark - Transaction

@implementation Transaction

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NullData = [NSData data];
    });
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (instancetype)initWithFromAddress: (Address*)fromAddress {
    self = [self init];
    if (self) {
        _fromAddress = fromAddress;
    }
    return self;
}

- (void)_setSignature: (Signature*)signature {
    _signature = signature;
}

- (instancetype)copy {
    Transaction *transaction = [Transaction transactionWithFromAddress:self.fromAddress];
    transaction.toAddress = self.toAddress;
    transaction.gasLimit = [self.gasLimit copy];
    transaction.gasPrice = [self.gasPrice copy];
    transaction.value = [self.value copy];
    transaction.nonce = self.nonce;
    transaction.data = [self.data copy];
    [transaction _setSignature:_signature];
    
    return transaction;
}

+ (instancetype)transaction {
    return [[Transaction alloc] init];
}

+ (instancetype)transactionWithFromAddress:(Address*)fromAddress {
    return [[Transaction alloc] initWithFromAddress:fromAddress];
}

+ (instancetype)transactionWithData: (NSData*)transactionData {
    
    // Thinking out loud: Is there ANY difference between a transaction without a gasPrice
    // and one with a gasPrice of zero? If not, we should instantiate BigNumbers for
    // gasPrice, gasLimit, value and NSData for data
    
    // Decode the RLP
    NSError *error = nil;
    NSArray *raw = (NSArray*)[RLPCoder objectWithData:transactionData error:&error];
    if (error || ![raw isKindOfClass:[NSArray class]]) { return nil; }
    
    // @TODO: Is this right? Or is an unsigned transaction still 9 elements?
    if (raw.count != 6 && raw.count != 9) { return nil; }

    // Check that every item is data (and not a nested array)
    for (NSData *item in raw) {
        if (![item isKindOfClass:[NSData class]]) {
            return nil;
        }
    }
    
    Transaction *transaction = [Transaction transaction];
    
    {
        BigNumber *nonce = [BigNumber bigNumberWithData:[raw objectAtIndex:0]];
        if (!nonce.isSafeUnsignedIntegerValue) {
            NSLog(@"WARNING: Nonce is out of range (%@)", nonce);
        }
        transaction.nonce = [nonce unsignedIntegerValue];
    }
    
    {
        NSData *gasPrice = [raw objectAtIndex:1];
        if (gasPrice.length > 32) {
            return nil;
        } else if (gasPrice.length) {
            transaction.gasPrice = [BigNumber bigNumberWithData:gasPrice];
        }
    }

    {
        NSData *gasLimit = [raw objectAtIndex:2];
        if (gasLimit.length > 32) {
            return nil;
        } else if (gasLimit.length) {
            transaction.gasLimit = [BigNumber bigNumberWithData:gasLimit];
        }
    }

    {
        NSData *toAddress = [raw objectAtIndex:3];
        if (toAddress.length) {
            transaction.toAddress = [Address addressWithData:toAddress];
            if (!transaction.toAddress) { return nil; }
        }
    }
    
    {
        NSData *value = [raw objectAtIndex:4];
        if (value.length > 32) {
            return nil;
        } else if (value.length) {
            transaction.value = [BigNumber bigNumberWithData:value];
        }
    }
    
    transaction.data = [raw objectAtIndex:5];

    // @TODO: Check signature (if it exists) and create a transaction with a from
    
    return transaction;
}
/*
- (void)setTo:(NSString *)to {
    if (to) { to = ; }
    _to = to;
}

- (void)setGasPrice:(BigNumber *)gasPrice {
    if (gasPrice && [gasPrice hexString].length > 34) { gasPrice = nil; }
    _gasPrice = gasPrice;
}

- (void)setGasLimit:(BigNumber *)gasLimit {
    if (gasLimit && [gasLimit hexString].length > 34) { gasLimit = nil; }
    _gasLimit = gasLimit;
}

- (void)setValue:(BigNumber *)value {
    if (value && [value hexString].length > 34) { value = nil; }
    _value = value;
}
*/
/*
- (BOOL)isValidTransaction {
    if (stripDataZeros([[self.gasPrice hexString] hexToData]).length > 32) { return NO; }
    if (stripDataZeros([[self.gasLimit hexString] hexToData]).length > 32) { return NO; }
    if (stripDataZeros([[self.value hexString] hexToData]).length > 32) { return NO; }
    if (![Account normalizeAddress:self.toAddress]) { return NO; }
    return YES;
}
*/
//
//- (void)setData:(NSData *)data {
//    if (![data isKindOfClass:[NSData class]]) {
//        @throw [NSError errorWithDomain:ErrorDomain code:-100 userInfo:@{@"reason": @"invalid data"}];
//    }
//    _data = data;
//}
//
//- (void)setData:(NSData *)data {
//    if (![data isKindOfClass:[NSData class]]) {
//        @throw [NSError errorWithDomain:ErrorDomain code:-100 userInfo:@{@"reason": @"invalid data"}];
//    }
//    _data = data;
//}

/*
 var transactionFields = [
 {name: 'nonce',    maxLength: 32, },
 {name: 'gasPrice', maxLength: 32, },
 {name: 'gasLimit', maxLength: 32, },
 {name: 'to',          length: 20, },
 {name: 'value',    maxLength: 32, },
 {name: 'data'},
 ];
 */

- (NSMutableArray*)_packBasic {
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:9];
    
    {
        NSData *nonceData = stripDataZeros([NSData dataWithInteger:self.nonce]);
        if (nonceData.length > 32) { return nil; }
        [result addObject:nonceData];
    }
    
    if (self.gasPrice) {
        NSData *gasPriceData = stripDataZeros([[self.gasPrice hexString] dataUsingHexEncoding]);
        if (gasPriceData.length > 32) { return nil; }
        [result addObject:gasPriceData];
    } else {
        [result addObject:NullData];
    }

    if (self.gasLimit) {
        NSData *gasLimitData = stripDataZeros([[self.gasLimit hexString] dataUsingHexEncoding]);
        if (gasLimitData.length > 32) { return nil; }
        [result addObject:gasLimitData];
    } else {
        [result addObject:NullData];
    }
    
    if (self.toAddress) {
        [result addObject:self.toAddress.data];
    } else {
        [result addObject:NullData];
    }
    
    if (self.value) {
        NSData *valueData = stripDataZeros([[self.value hexString] dataUsingHexEncoding]);
        if (valueData.length > 32) { return nil; }
        [result addObject:valueData];
    } else {
        [result addObject:NullData];
    }

    if (self.data) {
        [result addObject:self.data];
    } else {
        [result addObject:NullData];
    }

    return result;
}


- (void)sign:(Account *)account {
    if (account) {
        NSMutableArray *raw = [self _packBasic];
        if (_chainId) {
            [raw addObject:[NSData dataWithInteger:_chainId]];
            [raw addObject:NullData];
            [raw addObject:NullData];
        }

        NSError *error = nil;
        NSData *digest = [[RLPCoder dataWithObject:raw error:&error] KECCAK256];
        _fromAddress = account.address;
        _signature = [account signDigest:digest];
    } else {
        _signature = nil;
    }
}

- (NSData*)serialize {
    NSMutableArray *raw = [self _packBasic];
    
    if (self.signature) {
        uint8_t v = 27 + self.signature.v;
        if (_chainId) { v += _chainId * 2 + 8; }
        [raw addObject:[NSData dataWithInteger:v]];
        [raw addObject:stripDataZeros(self.signature.r)];
        [raw addObject:stripDataZeros(self.signature.s)];
    } else {
        [raw addObject:[NSData dataWithInteger:(_chainId ? _chainId: 28)]];
        [raw addObject:NullData];
        [raw addObject:NullData];
    }
    
    NSError *error = nil;
    NSData *encodedTransaction = [RLPCoder dataWithObject:raw error:&error];
    if (error) {
        NSLog(@"Error Serializing: %@", error);
    }
    return encodedTransaction;
}


- (NSString*)description {
    return [NSString stringWithFormat:@"<Transaction to=%@ nonce=%ld gasPrice=%@ gasLimit=%@ value=%@ data=%@>",
            self.toAddress, (unsigned long)self.nonce, [self.gasPrice decimalString], [self.gasLimit decimalString],
            [self.value decimalString], [self.data hexEncodedString]];
}

@end
