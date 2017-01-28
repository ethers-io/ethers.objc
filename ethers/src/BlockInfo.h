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


@interface BlockInfo : NSObject <NSCopying>

/**
 *   Dictionary representation
 *   - hash               (hex string; 32 bytes)               *
 *   - blockNumber        (decimal string)                     *
 *   - parentHash         (hex string; 32 bytes)               *
 *   - timestamp          (decimal string)                     *
 *   - nonce              (decimal string)                     *
 *   - extraData          (string)                             *
 *   - gasLimit           (decimal string)                     *
 *   - gasUsed            (decimal string)                     *
 */
+ (instancetype)blockInfoFromDictionary: (NSDictionary*)info;
- (NSDictionary*)dictionaryRepresentation;


/**
 *  JSON Representation
 */
+ (instancetype)blockInfoFromJSON: (NSString*)json;
- (NSString*)jsonRepresentation;


@property (nonatomic, readonly) Hash *blockHash;
@property (nonatomic, readonly) NSInteger blockNumber;

@property (nonatomic, readonly) Hash *parentHash;

@property (nonatomic, readonly) NSTimeInterval timestamp;

@property (nonatomic, readonly) NSInteger nonce;

@property (nonatomic, readonly) NSData *extraData;

@property (nonatomic, readonly) BigNumber *gasLimit;
@property (nonatomic, readonly) BigNumber *gasUsed;

/*
@property (nonatomic, readonly) Hash *sha3Uncles;
@property (nonatomic, readonly) Hash *logsBloom;
@property (nonatomic, readonly) Hash *transactionsRoot;
@property (nonatomic, readonly) Hash *stateRoot;

@property (nonatomic, readonly) Address *miner;
@property (nonatomic, readonly) NSUInteger size;

@property (nonatomic, readonly) NSArray<Hash*> *transactionHashes;
@property (nonatomic, readonly) NSArray<Hash*> *uncles;
*/

@end
