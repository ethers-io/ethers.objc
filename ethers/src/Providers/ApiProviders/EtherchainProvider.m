#import "EtherchainProvider.h"

#import "JsonRpcProvider.h"


@implementation EtherchainProvider {
    NSUInteger _requestCount;
}


+ (Provider*)jsonRpcProviderWithChainId:(ChainId)chainId {
    // This provider is not supported... Maybe in the future?
    return nil;
    //return [[JsonRpcProvider alloc] initWithTestnet:testnet url:[NSURL URLWithString:@"https://rpc.ethapi.org"]];
}

/*
- (id)promiseFetch:(NSURL *)url body:(NSData *)body fetchType:(ApiProviderFetchType)fetchType process:(NSObject *(^)(NSData *))process {
    
    // Prevent testnet
    if (self.testnet) {
        Class promiseClass = getPromiseClass(fetchType);
        NSDictionary *userInfo = @{@"reason": @"etherchain.org does not support testnet"};
        return [promiseClass rejected:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorUnsupportedNetwork userInfo:userInfo]];
    }
    
    return [self promiseFetch:url body:body fetchType:fetchType process:process];
}
*/
// Etherscan returns balance as a number, which means we cannot use it (as underflow may have occurred)
//- (void)getBalance: (Address*)address callback: (void (^)(BigNumber *balance, NSError *NSError))callback {
//}
/*
- (void)getTransactionCount:(Address *)address callback:(void (^)(NSInteger, NSError *))callback {
    if (self.testnet) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            callback(-1, [NSError errorWithDomain:ProviderErrorDomain code:kProviderErrorUnsupportedNetwork userInfo:@{}]);
        });
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"https://etherchain.org/api/account/%@/nonce", address];
    [self fetch:[NSURL URLWithString:url] callback:^(NSDictionary *data, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                callback(-1, error);
            });
            return;
        }
        
    }];
}
*/
/*
- (id)promiseFetch: (NSURL*)url fetchType: (ApiProviderFetchType)fetchType process: (NSObject* (^)(NSObject*))process {
    return [self promiseFetchJSON:url body:nil fetchType:fetchType process:^NSObject*(NSDictionary *response) {
        if (![[response objectForKey:@"status"] isEqual:@(1)]) {
            NSDictionary *userInfo = @{@"reason": @"status not 1"};
            return [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:userInfo];
        }
        
        return [response objectForKey:@"data"];
    }];
}

- (IntegerPromise*)getTransactionCount:(Address *)address {
    NSObject* (^processResponse)(NSObject*) = ^NSObject*(NSObject *response) {
        return queryPath(response, @"array:0/dictionary:accountNonce/integerDecimal");
    };
    
    NSString *url = [NSString stringWithFormat:@"https://etherchain.org/api/account/%@/nonce", address];
    return [self promiseFetch:[NSURL URLWithString:url]
                    fetchType:ApiProviderFetchTypeIntegerDecimal
                      process:processResponse];
}
*/
/*
 Thins like "value" will be NSNumber, but well outside the range of a uint64
- (ArrayPromise*)getTransactions:(Address *)address startBlockTag:(BlockTag)blockTag {
    NSObject* (^processResponse)(NSObject*) = ^NSObject*(NSObject *response) {
        NSArray *infos = coerceValue(response, ApiProviderFetchTypeArray);
        if (!infos) {
            NSDictionary *userInfo = @{@"reason": @"data is not an array"};
            return [NSError errorWithDomain:ProviderErrorDomain code:kProviderErrorBadResponse userInfo:userInfo];
        }
        
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:infos.count];
        for (NSDictionary *info in infos) {
            if (![info isKindOfClass:[NSDictionary class]]) {
                NSDictionary *userInfo = @{@"reason": @"transaction not a dictionary"};
                return [NSError errorWithDomain:ProviderErrorDomain code:kProviderErrorBadResponse userInfo:userInfo];
            }
            
            NSMutableDictionary *mutableInfo = [info mutableCopy];
            {
                // block_id => blockNumber
                NSNumber *blockNumber = coerceValue([info objectForKey:@"block_id"], ApiProviderFetchTypeIntegerDecimal);
                if (blockNumber) {
                    [mutableInfo setObject:[blockNumber stringValue] forKey:@"blockNumber"];
                }
                
                NSString *timestamp = nil;
                
                NSString *contractAddress = nil;
                
                // sender => from
                Address *from = [Address addressWithString:coerceValue([info objectForKey:@"sender"], ApiProviderFetchTypeString)];
                if (from) {
                    [mutableInfo setObject:from.checksumAddress forKey:@"from"];
                }

                // recipient => to
                Address *to = [Address addressWithString:coerceValue([info objectForKey:@"recipient"], ApiProviderFetchTypeString)];
                if (to) {
                    [mutableInfo setObject:to.checksumAddress forKey:@"to"];
                }

                // price => gasPrice
                BigNumber *gasPrice = coerceValue([info objectForKey:@"price"], ApiProviderFetchTypeBigNumberDecimal);
                if (gasPrice) {
                    [mutableInfo setObject:[gasPrice decimalString] forKey:@"gasPrice"];
                }
                
                BigNumber *cumulativeGasUsed = coerceValue([info objectForKey:@"gasUsed"], ApiProviderFetchTypeBigNumberDecimal);
                if (cumulativeGasUsed) {
                    [mutableInfo setObject:[cumulativeGasUsed decimalString] forKey:@"cumulativeGasUsed"];
                }

                // accountNonce => nonce
                NSNumber *nonce = coerceValue([info objectForKey:@"accountNonce"], ApiProviderFetchTypeIntegerDecimal);
                if (nonce) {
                    [mutableInfo setObject:[nonce stringValue] forKey:@"nonce"];
                }

                BigNumber *cumulativeGasUsed = coerceValue([info objectForKey:@"gasUsed"], ApiProviderFetchTypeBigNumberDecimal);
                if (cumulativeGasUsed) {
                    [mutableInfo setObject:[cumulativeGasUsed decimalString] forKey:@"cumulativeGasUsed"];
                }
            }
            
            TransactionInfo *transactionInfo = [TransactionInfo transactionInfoFromDictionary:mutableInfo];
            if  (!transactionInfo) {
                NSDictionary *userInfo = @{@"reason": @"malformed transaction"};
                return [NSError errorWithDomain:ProviderErrorDomain code:kProviderErrorBadResponse userInfo:userInfo];
            }
            
            [result addObject:transactionInfo];
        }
        
        return result;
    };

    NSString *url = [NSString stringWithFormat:@"https://etherchain.org/api/account/%@/tx/0", address];
    return [self promiseFetch:[NSURL URLWithString:url]
                    fetchType:ApiProviderFetchTypeArray
                      process:processResponse];
}
*/
@end
