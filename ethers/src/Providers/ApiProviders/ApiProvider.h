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
 *  ApiProvider
 *
 *  The ApiProvider class providers an interface to simplify implementing
 *  providers that make HTTP connections to a backend server and parse the
 *  response.
 */

#import "Provider.h"

// @TODO: Refactor all thise to be more internal and use queryPath instead. Add (? option all allow nil)

NSMutableDictionary *transactionObject(Transaction *transaction);

typedef NS_OPTIONS(NSUInteger, ApiProviderFetchType) {
    ApiProviderFetchTypeNil,
    
    ApiProviderFetchTypeObject,
    ApiProviderFetchTypeString,
    ApiProviderFetchTypeArray,
    ApiProviderFetchTypeDictionary,
    
    ApiProviderFetchTypeJSONDictionary,

    ApiProviderFetchTypeBlockInfo,
    ApiProviderFetchTypeTransactionInfo,

    ApiProviderFetchTypeBigNumber,
    ApiProviderFetchTypeBigNumberDecimal,
    ApiProviderFetchTypeBigNumberHexString,

    ApiProviderFetchTypeInteger,
    ApiProviderFetchTypeIntegerDecimal,
    ApiProviderFetchTypeIntegerHexString,
    
    ApiProviderFetchTypeFloat,

    ApiProviderFetchTypeAddress,
    ApiProviderFetchTypeData,
    ApiProviderFetchTypeHash,
};


Class getPromiseClass(ApiProviderFetchType fetchType);
id coerceValue(NSObject *value, ApiProviderFetchType fetchType);

// queryPath(object, @"dictionary:someKey/array:0/integerHex")
// Supported types: dictionary:, array:, string, integerHex, integerDecimal, float
//                  bigNumberHex, bigNumberDecimal, data, hash, object
id queryPath(NSObject *object, NSString *path);

@interface ApiProvider : Provider

@property (nonatomic, readonly) NSUInteger requestCount;

- (id)promiseFetch: (NSURL*)url
              body: (NSData*)body
         fetchType: (ApiProviderFetchType)fetchType
           process: (NSObject* (^)(NSData*))process;

- (id)promiseFetchJSON: (NSURL*)url
                  body: (NSData*)body
             fetchType: (ApiProviderFetchType)fetchType
               process: (NSObject* (^)(NSDictionary*))process;

@end
