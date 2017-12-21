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

#import "EtherscanProvider.h"

#import "Account.h"
#import "SecureData.h"
#import "Utilities.h"


#pragma mark - Notifications


// @TODO: Fixup the error codes


#pragma mark -

NSString* queryifyTransaction(Transaction *transaction) {
    if (!transaction.toAddress) { return nil; }
    
    NSString *query = [NSString stringWithFormat:@"&to=%@", transaction.toAddress];
    if (![transaction.gasPrice isZero]) {
        query = [query stringByAppendingFormat:@"&gasPrice=%@", stripHexZeros([transaction.gasPrice hexString])];
    }
    if (![transaction.gasLimit isZero]) {
        query = [query stringByAppendingFormat:@"&gas=%@", stripHexZeros([transaction.gasLimit hexString])];
    }
    if (transaction.fromAddress) {
        query = [query stringByAppendingFormat:@"&from=%@", transaction.fromAddress];
    }
    if (transaction.data.length) {
        query = [query stringByAppendingFormat:@"&data=%@", [SecureData dataToHexString:transaction.data]];
    }
    if (![transaction.value isZero]) {
        query = [query stringByAppendingFormat:@"&value=%@", stripHexZeros([transaction.value hexString])];
    }
    
    return query;
}

@interface Provider (private)

- (void)setBlockNumber: (NSInteger)blockNumber;
- (void)setEtherPrice: (float)etherPrice;

@end

#pragma mark -
#pragma mark - EtherscanProvider

@implementation EtherscanProvider {
    NSTimer *_poller;
    NSString *_host;
}


#pragma mark - Life-Cycle

- (instancetype)initWithChainId:(ChainId)chainId {
    return [self initWithChainId:chainId apiKey:nil];
}

- (instancetype)initWithChainId:(ChainId)chainId apiKey:(NSString *)apiKey {
    switch (chainId) {
        case ChainIdHomestead:
            _host = @"api.etherscan.io";
            break;
        case ChainIdKovan:
            _host = @"kovan.etherscan.io";
            break;
        case ChainIdRinkeby:
            _host = @"rinkeby.etherscan.io";
            break;
        case ChainIdRopsten:
            _host = @"ropsten.etherscan.io";
            break;
        default:
            break;
    }
    
    // If we don't have a host, Etherscan doesn't support that network
    if (!_host) { return nil; }
    
    self = [super initWithChainId:chainId];
    if (self) {
        _apiKey = apiKey;
        [self doPoll];
    }
    return self;
}

- (void)dealloc {
    [_poller invalidate];
}

- (void)reset {
    [super reset];
    [self doPoll];
}


#pragma mark - Polling

- (void)doPoll {
    [[self getBlockNumber] onCompletion:^(IntegerPromise *promise) {
        if (promise.result) {
            [self setBlockNumber:promise.value];
        }        
    }];
    
    [[self getEtherPrice] onCompletion:^(FloatPromise *promise) {
        if (promise.result && promise.value != 0.0f) {
            [self setEtherPrice:promise.value];
        }
    }];
}

- (void)startPolling {
    if (self.polling) { return; }
    [super startPolling];
    _poller = [NSTimer scheduledTimerWithTimeInterval:4.0f target:self selector:@selector(doPoll) userInfo:nil repeats:YES];
}

- (void)stopPolling {
    if (!self.polling) { return; }
    [super stopPolling];
    [_poller invalidate];
    _poller = nil;
}


#pragma mark - Calling

- (NSURL*)urlForPath: (NSString*)path {
    NSString *apiKey = (_apiKey ? [NSString stringWithFormat:@"&apikey=%@", _apiKey]: @"");
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@%@", _host, path, apiKey]];
}

- (NSURL*)urlForProxyAction: (NSString*)action {
    return [self urlForPath:[NSString stringWithFormat:@"/api?module=proxy&%@", action]];
}

- (id)promiseFetch: (NSString*)path fetchType:(ApiProviderFetchType)fetchType {
    return [self promiseFetchJSON:[self urlForPath:path] body:nil fetchType:fetchType process:^NSObject*(NSDictionary *response) {
        if (![@"OK" isEqual:[response objectForKey:@"message"]]) {
            NSDictionary *userInfo = @{@"reason": @"response NOTOK"};
            return [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:userInfo];
        }
        
        return [response objectForKey:@"result"];;
    }];
}

- (id)promiseFetchProxyAction: (NSString*)action fetchType: (ApiProviderFetchType)fetchType {
    NSURL *url = [self urlForProxyAction:action];
    return [self promiseFetchJSON:url body:nil fetchType:fetchType process:^NSObject*(NSDictionary *response) {
        return [response objectForKey:@"result"];
    }];
}


#pragma mark - Methods

- (BigNumberPromise*)getBalance: (Address*)address blockTag: (BlockTag)blockTag {
    NSString *tag = getBlockTag(blockTag);

    if (!address || !tag ) {
        return [BigNumberPromise rejected:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorInvalidParameters userInfo:@{}]];
    }
    
    return [self promiseFetch:[NSString stringWithFormat:@"/api?module=account&action=balance&address=%@&tag=%@", address, tag]
                    fetchType:ApiProviderFetchTypeBigNumberDecimal];
}

- (IntegerPromise*)getTransactionCount: (Address*)address blockTag: (BlockTag)blockTag {
    NSString *tag = getBlockTag(blockTag);
    
    if (!address || !tag ) {
        return [IntegerPromise rejected:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorInvalidParameters userInfo:@{}]];
    }
    
    return [self promiseFetchProxyAction:[NSString stringWithFormat:@"action=eth_getTransactionCount&address=%@&tag=%@", address, tag]
                               fetchType:ApiProviderFetchTypeIntegerHexString];
}

- (DataPromise*)getCode:(Address *)address {
    if (!address) {
        return [DataPromise rejected:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorInvalidParameters userInfo:@{}]];
    }
    
    return [self promiseFetchProxyAction:[NSString stringWithFormat:@"action=eth_getCode&address=%@", address]
                               fetchType:ApiProviderFetchTypeData];
}

- (IntegerPromise*)getBlockNumber {
    return [self promiseFetchProxyAction:@"action=eth_blockNumber"
                               fetchType:ApiProviderFetchTypeIntegerHexString];
}

- (BigNumberPromise*)getGasPrice {
    return [self promiseFetchProxyAction:@"action=eth_gasPrice"
                               fetchType:ApiProviderFetchTypeBigNumberHexString];
}

- (DataPromise*)call: (Transaction*)transaction {
    NSString *query = queryifyTransaction(transaction);
    if (!query || !transaction.toAddress) {
        NSDictionary *userInfo = @{@"reason": @"invalid transaction"};
        return [DataPromise rejected:[NSError errorWithDomain:ProviderErrorDomain code:-100 userInfo:userInfo]];
    }
    
    return [self promiseFetchProxyAction:[NSString stringWithFormat:@"action=eth_call%@", query]
                               fetchType:ApiProviderFetchTypeData];
}

- (BigNumberPromise*)estimateGas: (Transaction*)transaction {
    NSString *query = queryifyTransaction(transaction);
    if (!query) {
        NSDictionary *userInfo = @{@"reason": @"invalid transaction"};
        return [BigNumberPromise rejected:[NSError errorWithDomain:ProviderErrorDomain code:-100 userInfo:userInfo]];
    }

    return [self promiseFetchProxyAction:[NSString stringWithFormat:@"action=eth_estimateGas%@", query]
                               fetchType:ApiProviderFetchTypeBigNumberHexString];
}

- (HashPromise*)sendTransaction: (NSData*)signedTransaction {
    if (!signedTransaction) {
        NSDictionary *userInfo = @{@"reason": @"invalid transaction"};
        return [HashPromise rejected:[NSError errorWithDomain:ProviderErrorDomain code:-100 userInfo:userInfo]];
    }
    
    NSString *action = [NSString stringWithFormat:@"action=eth_sendRawTransaction&hex=%@", [SecureData dataToHexString:signedTransaction]];
    return [self promiseFetchProxyAction:action fetchType:ApiProviderFetchTypeHash];
}

//- (BlockInfoPromise*)getBlockByBlockHash: (Hash*)blockHash {
//    NSString *action = [NSString stringWithFormat:@"action=eth_getTransactionByHash&txhash=%@", transactionHash.hexString];
//    return [self promiseFetchProxyAction:action fetchType:ApiProviderFetchTypeTransactionInfo];
//}

- (BlockInfoPromise*)getBlockByBlockTag: (BlockTag)blockTag {
    NSString *tag = getBlockTag(blockTag);
    if (!tag) {
        return [BlockInfoPromise rejected:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorInvalidParameters userInfo:@{}]];
    }

    NSString *action = [NSString stringWithFormat:@"action=eth_getBlockByNumber&tag=%@&boolean=false", tag];
    return [self promiseFetchProxyAction:action fetchType:ApiProviderFetchTypeBlockInfo];
}

- (TransactionInfoPromise*)getTransaction: (Hash*)transactionHash {
    NSString *action = [NSString stringWithFormat:@"action=eth_getTransactionByHash&txhash=%@", transactionHash.hexString];
    return [self promiseFetchProxyAction:action fetchType:ApiProviderFetchTypeTransactionInfo];
}

- (HashPromise*)getStorageAt:(Address *)address position:(BigNumber *)position {
    NSString *action = [NSString stringWithFormat:@"action=eth_getStorageAt&address=%@&position=%@",
                        address.checksumAddress, stripHexZeros([position hexString])];
    return [self promiseFetchProxyAction:action fetchType:ApiProviderFetchTypeHash];
}

- (ArrayPromise*)getTransactions: (Address*)address startBlockTag: (BlockTag)blockTag {
    
    NSObject* (^processTransactions)(NSDictionary*) = ^NSObject*(NSDictionary *response) {
        NSMutableArray *result = [NSMutableArray array];

        NSArray *infos = (NSArray*)[response objectForKey:@"result"];
        if (![infos isKindOfClass:[NSArray class]]) {
            return [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:@{}];
        }

        for (NSDictionary *info in infos) {
            if (![info isKindOfClass:[NSDictionary class]]) {
                return [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:@{}];
            }
            
            NSMutableDictionary *mutableInfo = [info mutableCopy];

            // Massage some values that have their key names differ from ours
            {
                NSObject *gasLimit = [info objectForKey:@"gas"];
                if (gasLimit) {
                    [mutableInfo setObject:gasLimit forKey:@"gasLimit"];
                }
                
                NSObject *timestamp = [info objectForKey:@"timeStamp"];
                if (timestamp) {
                    [mutableInfo setObject:timestamp forKey:@"timestamp"];
                }
                
                NSObject *data = [info objectForKey:@"input"];
                if (data) {
                    [mutableInfo setObject:data forKey:@"data"];
                }
            }
            
            TransactionInfo *transactionInfo = [TransactionInfo transactionInfoFromDictionary:mutableInfo];
            if (!transactionInfo) {
                return [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:@{}];
            }

            [result addObject:transactionInfo];
        }

        return result;
    };
    
    /*
    NSMutableArray<ArrayPromise*> *promises = [NSMutableArray arrayWithCapacity:2];
    
    {
        NSString *path = [NSString stringWithFormat:@"/api?module=account&action=txlist&address=%@&startblock=%@&endblock=99999999&sort=asc",
                          address, getBlockTag(blockTag)];
        
        ArrayPromise *promise = [self promiseFetchJSON:[self urlForPath:path]
                                                  body:nil
                                             fetchType:ApiProviderFetchTypeArray
                                               process:processTransactions];
        [promises addObject:promise];
    }

    {
        NSString *path = [NSString stringWithFormat:@"/api?module=account&action=txlistinternal&address=%@&startblock=%@&endblock=99999999&sort=asc",
                          address, getBlockTag(blockTag)];
        
        ArrayPromise *promise = [self promiseFetchJSON:[self urlForPath:path]
                                                  body:nil
                                             fetchType:ApiProviderFetchTypeArray
                                               process:processTransactions];
        [promises addObject:promise];
    }

    return [ArrayPromise promiseWithSetup:^(Promise *promise) {
        [[Promise all:promises] onCompletion:^(ArrayPromise *allPromise) {
            NSLog(@"FOO: %@ %@", allPromise.value, allPromise.error);
            if (allPromise.error) {
                [promise reject:allPromise.error];
                return;
            }
            
            NSMutableArray *result = [NSMutableArray array];
            for (NSArray *transactions in allPromise.value) {
                [result addObjectsFromArray:transactions];
            }
            
            [promise resolve:result];
        }];
    }];
     */
    
    NSString *path = [NSString stringWithFormat:@"/api?module=account&action=txlist&address=%@&startblock=%@&endblock=99999999&sort=asc",
                      address, getBlockTag(blockTag)];
    
    return [self promiseFetchJSON:[self urlForPath:path]
                             body:nil
                        fetchType:ApiProviderFetchTypeArray
                          process:processTransactions];
}

- (FloatPromise*)getEtherPrice {
    static NSTimeInterval lastEtherPriceTime = 0;
    static FloatPromise *etherPricePromise = nil;
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    // It's been a while since we updted the ether price, update it
    if (fabs(now - lastEtherPriceTime) > 60.0f) {
        lastEtherPriceTime = now;
        
        NSObject* (^processEtherPrice)(NSDictionary*) = ^NSObject*(NSDictionary *response) {
            NSObject *result = response;
            if (![result isKindOfClass:[NSDictionary class]]) { return nil; }
            
            result = [(NSDictionary*)result objectForKey:@"result"];
            if (![result isKindOfClass:[NSDictionary class]]) { return nil; }
            
            return [(NSDictionary*)result objectForKey:@"ethusd"];
        };
        
        etherPricePromise = [self promiseFetchJSON:[self urlForPath:@"/api?module=stats&action=ethprice"]
                                              body:nil
                                         fetchType:ApiProviderFetchTypeFloat
                                           process:processEtherPrice];
    }
    
    return etherPricePromise;
}


#pragma mark - NSObject

- (NSString*)description {
    return [NSString stringWithFormat:@"<EtherscanProvider chainId=%d apiKey=%@>", self.chainId, _apiKey];
}

@end
