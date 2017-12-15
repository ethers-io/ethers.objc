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

@interface BigNumber : NSObject


+ (BigNumber*)constantNegativeOne;
+ (BigNumber*)constantZero;
+ (BigNumber*)constantOne;
+ (BigNumber*)constantTwo;
+ (BigNumber*)constantWeiPerEther;


+ (instancetype)bigNumberWithDecimalString: (NSString*)decimalString;
+ (instancetype)bigNumberWithHexString: (NSString*)hexString;
+ (instancetype)bigNumberWithBase36String: (NSString*)base36String;

+ (instancetype)bigNumberWithData: (NSData*)data;
+ (instancetype)bigNumberWithNumber: (NSNumber*)number;
+ (instancetype)bigNumberWithInteger: (NSInteger)integer;


- (BigNumber*)add: (BigNumber*)other;

- (BigNumber*)sub: (BigNumber*)other;

- (BigNumber*)mul: (BigNumber*)other;

- (BigNumber*)div: (BigNumber*)other;

- (BigNumber*)mod: (BigNumber*)other;

- (NSUInteger)hash;
- (NSComparisonResult)compare: (id)other;
- (BOOL)isEqual:(id)object;

- (BOOL)lessThan: (BigNumber*)other;
- (BOOL)lessThanEqualTo: (BigNumber*)other;
- (BOOL)greaterThan: (BigNumber*)other;
- (BOOL)greaterThanEqualTo: (BigNumber*)other;

@property (nonatomic, readonly) NSString *decimalString;
@property (nonatomic, readonly) NSString *hexString;
@property (nonatomic, readonly) NSString *base36String;

@property (nonatomic, readonly) BOOL isSafeUnsignedIntegerValue;
@property (nonatomic, readonly) NSUInteger unsignedIntegerValue;

@property (nonatomic, readonly) BOOL isSafeIntegerValue;
@property (nonatomic, readonly) NSInteger integerValue;

@property (nonatomic, readonly) NSData *data;


@property (nonatomic, readonly) BOOL isZero;
@property (nonatomic, readonly) BOOL isNegative;

@end
