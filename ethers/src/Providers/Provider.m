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

#import <UIKit/UIKit.h>

#import "Provider.h"
#import "TransactionInfo.h"


// Convert a BlockTag to its canonical string value
NSString *getBlockTag(BlockTag blockTag) {
    switch (blockTag) {
        case BLOCK_TAG_LATEST:
            return @"latest";
        case BLOCK_TAG_PENDING:
            return @"pending";
        default:
            if (blockTag >= 0) {
                return [[BigNumber bigNumberWithInteger:blockTag] hexString];
            }
            break;
    }
    
    return nil;
}


#pragma mark - Notifications

const NSNotificationName ProviderDidReceiveNewBlockNotification = @"ProviderDidReceiveNewBlockNotification";
const NSNotificationName ProviderEtherPriceChangedNotification = @"ProviderEtherPriceChangedNotification";


#pragma mark - Errors

NSErrorDomain ProviderErrorDomain = @"ProviderErrorDomain";


#pragma mark - Provider

@implementation Provider {
    NSInteger _blockNumber;
    float _etherPrice;
}

#pragma mark - Life-Cycle
//+ (void)setUserInfoValueProviderForDomain:(NSErrorDomain)errorDomain provider:(id _Nullable (^ _Nullable)(NSError *err, NSString *userInfoKey))provider NS_AVAILABLE(10_11, 9_0);

static NSString *UserAgent = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSError setUserInfoValueProviderForDomain:ProviderErrorDomain provider:^id(NSError *error, NSString *userInfoKey) {
            if ([userInfoKey isEqualToString:NSLocalizedDescriptionKey]) {
                switch ((ProviderError)error.code) {
                    case ProviderErrorTimeout:
                        return @"Timeout";
                    case ProviderErrorThrottled:
                        return @"Throttled";
                    case ProviderErrorBadRequest:
                        return @"Bad Request";
                    case ProviderErrorBadResponse:
                        return @"Bad Response";
                    case ProviderErrorUnknownError:
                        return @"Unknown Error";
                    case ProviderErrorNotAuthorized:
                        return @"Not Authorized";
                    case ProviderErrorNotImplemented:
                        return @"Not Implmented";
                    case ProviderErrorConnectionFailed:
                        return @"Connection Failed";
                    case ProviderErrorInvalidParameters:
                        return @"Invalid Parameters";
                    case ProviderErrorServerUnknownError:
                        return @"Server Unknown Error";
                    case ProviderErrorUnsupportedNetwork:
                        return @"Unsupported Network";
                    default:
                        break;
                }
            }
            return nil;
        }];
        
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *version = [info objectForKey:@"CFBundleShortVersionString"];
        NSString *platform = [UIDevice currentDevice].systemVersion;
        UserAgent = [NSString stringWithFormat:@"io.ethers.app/%@ (iOS/%@)", version, platform];
    });
}

+ (NSString*)userAgent {
    return UserAgent;
}


- (instancetype)initWithTestnet:(BOOL)testnet {
    self = [super init];
    if (self) {
        _testnet = testnet;
        _blockNumber = -1;
    }
    return self;
}

- (void)reset {
    [self setBlockNumber:-1];
}

- (void)startPolling {
    _polling = YES;
    
}

- (void)stopPolling {
    _polling = NO;
}


#pragma mark - Provider API

- (void)setBlockNumber:(NSInteger)blockNumber {
    if (_blockNumber >= blockNumber && blockNumber >= 0) { return; }
    
    _blockNumber = blockNumber;

    [[NSNotificationCenter defaultCenter] postNotificationName:ProviderDidReceiveNewBlockNotification
                                                        object:self
                                                      userInfo:@{@"blockNumber": @(blockNumber)}];
}

- (void)setEtherPrice: (float)etherPrice {
    if (etherPrice == _etherPrice) { return; }
    
    NSLog(@"Ether Price: $%.02f/ether", etherPrice);

    _etherPrice = etherPrice;

    [[NSNotificationCenter defaultCenter] postNotificationName:ProviderEtherPriceChangedNotification
                                                        object:self
                                                      userInfo:@{@"price": @(etherPrice)}];
}

#pragma mark - Call

- (id)sendNotImplemented: (NSString*)method promiseClass: (Class)promiseClass {
    NSDictionary *userInfo = @{@"method": method};
    return [promiseClass rejected:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorNotImplemented userInfo:userInfo]];
}

#pragma mark - Methods

- (BigNumberPromise*)getBalance: (Address*)address {
    return [self getBalance:address blockTag:BLOCK_TAG_LATEST];
}

- (BigNumberPromise*)getBalance: (Address*)address blockTag: (BlockTag)blockTag {
    return [self sendNotImplemented:@"getBalance" promiseClass:[BigNumberPromise class]];
}

- (IntegerPromise*)getTransactionCount: (Address*)address {
    return [self getTransactionCount:address blockTag:BLOCK_TAG_LATEST];
}

- (IntegerPromise*)getTransactionCount: (Address*)address blockTag: (BlockTag)blockTag {
    return [self sendNotImplemented:@"getTransactionCount" promiseClass:[IntegerPromise class]];
}

- (IntegerPromise*)getBlockNumber {
    return [self sendNotImplemented:@"getBlockNumber" promiseClass:[IntegerPromise class]];
}

- (BigNumberPromise*)getGasPrice {
    return [self sendNotImplemented:@"getGasPrice" promiseClass:[BigNumberPromise class]];
}

- (DataPromise*)call: (Transaction*)transaction {
    return [self sendNotImplemented:@"call" promiseClass:[DataPromise class]];
}

- (BigNumberPromise*)estimateGas: (Transaction*)transaction {
    return [self sendNotImplemented:@"estimateGas" promiseClass:[BigNumberPromise class]];
}

- (HashPromise*)sendTransaction: (NSData*)signedTransaction {
    return [self sendNotImplemented:@"sendTransaction" promiseClass:[HashPromise class]];
}

- (BlockInfoPromise*)getBlockByBlockHash: (Hash*)blockHash {
    return [self sendNotImplemented:@"getBlockByBlockHash" promiseClass:[BlockInfoPromise class]];
}

- (BlockInfoPromise*)getBlockByBlockTag: (BlockTag)blockTag {
    return [self sendNotImplemented:@"getBlockByBlockTag" promiseClass:[BlockInfoPromise class]];
}

- (TransactionInfoPromise*)getTransaction: (Hash*)transactionHash {
    return [self sendNotImplemented:@"getTransaction" promiseClass:[TransactionInfoPromise class]];
}

- (ArrayPromise*)getTransactions: (Address*)address startBlockTag: (BlockTag)blockTag {
    return [self sendNotImplemented:@"getTransactions" promiseClass:[ArrayPromise class]];
}

- (FloatPromise*)getEtherPrice {
    return [self sendNotImplemented:@"getEtherPrice" promiseClass:[FloatPromise class]];
}

@end
