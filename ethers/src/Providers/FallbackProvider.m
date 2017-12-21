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

#import "FallbackProvider.h"


@interface Provider (private)

- (void)setBlockNumber: (NSInteger)blockNumber;
- (void)setEtherPrice: (float)etherPrice;

@end

#pragma mark -
#pragma mark - FallbackProvider

@implementation FallbackProvider {
    NSArray<Provider*> *_orderedProviders;
}

- (instancetype)initWithChainId:(ChainId)chainId {
    self = [super initWithChainId:chainId];
    if (self) {
        _orderedProviders = [NSArray array];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)noticeNewBlock: (NSNotification*)note {
    [self setBlockNumber:[[note.userInfo objectForKey:@"blockNumber"] integerValue]];
}

- (void)noticeEtherPrice: (NSNotification*)note {
    [self setEtherPrice:[[note.userInfo objectForKey:@"price"] floatValue]];
}

- (BOOL)addProvider: (Provider*)provider {
    if (provider.chainId != self.chainId) { return NO; }
    
    @synchronized (self) {
        NSMutableArray *mutableArray = [_orderedProviders mutableCopy];
        [mutableArray addObject:provider];
        _orderedProviders = [mutableArray copy];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(noticeNewBlock:)
                                                     name:ProviderDidReceiveNewBlockNotification
                                                   object:provider];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(noticeEtherPrice:)
                                                     name:ProviderEtherPriceChangedNotification
                                                   object:provider];
    }
    
    return YES;
}

- (Provider*)providerAtIndex: (NSUInteger)index {
    @synchronized (self) {
        return [_orderedProviders objectAtIndex:index];
    }
}

- (void)removeProviderAtIndex: (NSUInteger)index {
    @synchronized (self) {
        Provider *provider = [_orderedProviders objectAtIndex:index];
        
        NSMutableArray *mutableArray = [_orderedProviders mutableCopy];
        [mutableArray removeObjectAtIndex:index];
        _orderedProviders = [mutableArray copy];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ProviderDidReceiveNewBlockNotification
                                                      object:provider];

        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ProviderEtherPriceChangedNotification
                                                      object:provider];
    }
}

- (NSArray<Provider*>*)orderedProviders {
    @synchronized (self) {
        return [_orderedProviders copy];
    }
}

- (void)reset {
    NSArray<Provider*> *providers = [self orderedProviders];

    for (Provider *provider in providers) {
        [provider reset];
    }
}

- (void)startPolling {
    [super startPolling];

    NSArray<Provider*> *providers = [self orderedProviders];

    for (Provider *provider in providers) {
        [provider startPolling];
    }
}

- (void)stopPolling {
    [super stopPolling];

    NSArray<Provider*> *providers = [self orderedProviders];

    for (Provider *provider in providers) {
        [provider stopPolling];
    }
}


#pragma mark - Calling

- (id)executeOperation: (Promise* (^)(Provider*))startCallback promiseClass: (Class)promiseClass {
    NSArray<Provider*> *providers = [self orderedProviders];
    
    return [(Promise*)[promiseClass alloc] initWithSetup:^(Promise *promise) {
        if (providers.count == 0) {
            NSDictionary *userInfo = @{@"reason": @"no providers"};
            [promise reject:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorInvalidParameters userInfo:userInfo]];
            return;
        }
        
        void (^nextProvider)(NSUInteger, void (^)()) = ^(NSUInteger index, void (^nextProvider)()) {
            Provider *provider = [providers objectAtIndex:index];
            [startCallback(provider) onCompletion:^(Promise *childPromise) {
                if (childPromise.error) {
                    if (childPromise.error.code != ProviderErrorNotImplemented) {
                        NSLog(@"FallbackProvider: error=%@ provider=%@", childPromise.error, provider);
                    }
                    if (index + 1 < providers.count) {
                        nextProvider(index + 1, nextProvider);
                    } else {
                        [promise reject:childPromise.error];
                    }
                    return;
                }
                
                [promise resolve:childPromise.result];
            }];
        };
        nextProvider(0, nextProvider);
    }];

}


#pragma mark - Methods

- (BigNumberPromise*)getBalance: (Address*)address blockTag: (BlockTag)blockTag {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getBalance:address blockTag:blockTag];
    };
    return [self executeOperation:startCallback promiseClass:[BigNumberPromise class]];
}

- (IntegerPromise*)getTransactionCount: (Address*)address blockTag: (BlockTag)blockTag {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getTransactionCount:address blockTag:blockTag];
    };
    return [self executeOperation:startCallback promiseClass:[IntegerPromise class]];
}

- (DataPromise*)getCode: (Address*)address {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getCode:address];
    };
    return [self executeOperation:startCallback promiseClass:[DataPromise class]];
}

- (IntegerPromise*)getBlockNumber {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getBlockNumber];
    };
    return [self executeOperation:startCallback promiseClass:[IntegerPromise class]];
}

- (BigNumberPromise*)getGasPrice {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getGasPrice];
    };
    return [self executeOperation:startCallback promiseClass:[BigNumberPromise class]];
}

- (DataPromise*)call: (Transaction*)transaction {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider call:transaction];
    };
    return [self executeOperation:startCallback promiseClass:[DataPromise class]];
}

- (BigNumberPromise*)estimateGas: (Transaction*)transaction {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider estimateGas:transaction];
    };
    return [self executeOperation:startCallback promiseClass:[BigNumberPromise class]];
}

- (HashPromise*)sendTransaction: (NSData*)signedTransaction {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider sendTransaction:signedTransaction];
    };
    return [self executeOperation:startCallback promiseClass:[HashPromise class]];
}

- (BlockInfoPromise*)getBlockByBlockHash: (Hash*)blockHash {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getBlockByBlockHash:blockHash];
    };
    return [self executeOperation:startCallback promiseClass:[BlockInfoPromise class]];
}

- (BlockInfoPromise*)getBlockByBlockTag: (BlockTag)blockTag {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getBlockByBlockTag:blockTag];
    };
    return [self executeOperation:startCallback promiseClass:[BlockInfoPromise class]];
}

- (TransactionInfoPromise*)getTransaction: (Hash*)transactionHash {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getTransaction:transactionHash];
    };
    return [self executeOperation:startCallback promiseClass:[TransactionInfoPromise class]];
}

- (ArrayPromise*)getTransactions: (Address*)address startBlockTag: (BlockTag)blockTag {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getTransactions:address startBlockTag:blockTag];
    };
    return [self executeOperation:startCallback promiseClass:[ArrayPromise class]];
}

- (FloatPromise*)getEtherPrice {
    Promise* (^startCallback)(Provider*) = ^Promise*(Provider *provider) {
        return [provider getEtherPrice];
    };
    return [self executeOperation:startCallback promiseClass:[FloatPromise class]];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@ providers=%@>", NSStringFromClass([self class]), _orderedProviders];
}

@end
