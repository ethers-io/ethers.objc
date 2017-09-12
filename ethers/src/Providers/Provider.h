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

/**
 *  Provider
 *
 *  A provider is the connection to the Ethereum network, querying the blockchain for
 *  its current state as well as sending transactions to update its state.
 *
 *  All operations return a Promise, which is similar to an asynchronous, non-blocking
 *  future. A Promise always calls its onCompletion handlers on the main thread.
 */


#import <Foundation/Foundation.h>

#import "Address.h"
#import "Promise.h"
#import "Transaction.h"
#import "TransactionInfo.h"


#pragma mark - Notifictions

extern const NSNotificationName ProviderDidReceiveNewBlockNotification;
extern const NSNotificationName ProviderEtherPriceChangedNotification;


#pragma mark - Errors

extern NSErrorDomain ProviderErrorDomain;

typedef enum ProviderError {
    ProviderErrorNotImplemented                 = -1,
    ProviderErrorUnknownError                   = -3,
    
    ProviderErrorInvalidParameters              = -5,
    ProviderErrorUnsupportedNetwork             = -6,
    
    ProviderErrorBadRequest                     = -10,
    ProviderErrorBadResponse                    = -11,
    ProviderErrorNotAuthorized                  = -13,
    ProviderErrorThrottled                      = -14,
    
    ProviderErrorTimeout                        = -15,
    
    ProviderErrorConnectionFailed               = -20,

    ProviderErrorNotFound                       = -40,

    ProviderErrorServerUnknownError             = -50,
    
} ProviderError;


#pragma mark - Block Tag Constants

typedef NSInteger BlockTag;

#define BLOCK_TAG_EARLIEST                                      0
#define BLOCK_TAG_LATEST                                       -1
#define BLOCK_TAG_PENDING                                      -2

NSString *getBlockTag(BlockTag blockTag);


#pragma mark - Provider

@interface Provider: NSObject

+ (NSString*)userAgent;


- (instancetype)initWithChainId: (ChainId)chainId;

@property (nonatomic, readonly) ChainId chainId;


#pragma mark - Polling

@property (nonatomic, readonly) BOOL polling;

- (void)startPolling;
- (void)stopPolling;


- (void)reset;


#pragma mark - Methods

- (BigNumberPromise*)getBalance: (Address*)address;
- (BigNumberPromise*)getBalance: (Address*)address blockTag: (BlockTag)blockTag;

- (IntegerPromise*)getTransactionCount: (Address*)address;
- (IntegerPromise*)getTransactionCount: (Address*)address blockTag: (BlockTag)blockTag;

- (DataPromise*)getCode: (Address*)address;

- (IntegerPromise*)getBlockNumber;
- (BigNumberPromise*)getGasPrice;

- (DataPromise*)call: (Transaction*)transaction;
- (BigNumberPromise*)estimateGas: (Transaction*)transaction;
- (HashPromise*)sendTransaction: (NSData*)signedTransaction;

- (BlockInfoPromise*)getBlockByBlockHash: (Hash*)blockHash;
- (BlockInfoPromise*)getBlockByBlockTag: (BlockTag)blockTag;

- (HashPromise*)getStorageAt: (Address*)address position: (BigNumber*)position;

- (TransactionInfoPromise*)getTransaction: (Hash*)transactionHash;

- (ArrayPromise*)getTransactions: (Address*)address startBlockTag: (BlockTag)blockTag;

- (FloatPromise*)getEtherPrice;

- (AddressPromise*)lookupName: (NSString*)name;
- (StringPromise*)lookupAddress: (Address*)address;

//- (void)registerFilter: (Filter*)filter;
//- (void)unregisterFilter: (Filter*)filter;

@end
