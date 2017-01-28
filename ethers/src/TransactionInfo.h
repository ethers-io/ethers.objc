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

#import <Foundation/Foundation.h>

#import "Address.h"
#import "BigNumber.h"
#import "Hash.h"
#import "Transaction.h"


@interface TransactionInfo : NSObject <NSCopying>

/**
 *   Dictionary representation
 *   - hash               (hex string; 32 bytes)               *
 *   - blockHash          (hex string; 32 bytes)
 *   - blockNumber        (decimal string)
 *   - timestamp          (decimal string)                     *
 *   - contractAddress    (or creates; hex string; 20 bytes)
 *   - from               (hex string; 20 bytes)               *
 *   - to                 (hex string; 20 bytes)               *
 *   - gasLimit           (decimal string)                     *
 *   - gasUsed            (decimal string)
 *   - gasPrice           (decimal string)                     *
 *   - cumulativeGasUsed  (decimal string)
 *   - nonce              (decimal string)                     *
 *   - data               (or input; hex string)               *
 *   - value              (decimal string)
 */
+ (instancetype)transactionInfoFromDictionary: (NSDictionary*)info;
- (NSDictionary*)dictionaryRepresentation;

+ (instancetype)transactionInfoWithPendingTransaction: (Transaction*)transaction hash: (Hash*)transactionHash;


/**
 *  JSON Representation
 */
+ (instancetype)transactionInfoFromJSON: (NSString*)json;
- (NSString*)jsonRepresentation;

@property (nonatomic, readonly) Hash *transactionHash;

@property (nonatomic, readonly) NSInteger blockNumber;
@property (nonatomic, readonly) Hash *blockHash;

@property (nonatomic, readonly) NSTimeInterval timestamp;

@property (nonatomic, readonly) Address *fromAddress;
@property (nonatomic, readonly) Address *toAddress;

@property (nonatomic, readonly) Address *contractAddress;

@property (nonatomic, readonly) NSInteger nonce;

@property (nonatomic, readonly) BigNumber *gasLimit;
@property (nonatomic, readonly) BigNumber *gasPrice;
@property (nonatomic, readonly) BigNumber *gasUsed;
@property (nonatomic, readonly) BigNumber *cumulativeGasUsed;

@property (nonatomic, readonly) BigNumber *value;

@property (nonatomic, readonly) NSData *data;

@end
