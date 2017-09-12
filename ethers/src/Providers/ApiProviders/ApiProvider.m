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

#import "ApiProvider.h"

#import "SecureData.h"
#import "Utilities.h"


NSObject *ensureFloat(NSObject *object) {
    if ([object isKindOfClass:[NSNumber class]]) {
        return (NSNumber*)object;
        
    } else if ([object isKindOfClass:[NSString class]]) {
        return @([(NSString*)object floatValue]);
    }
    
    return nil;
}

NSNumber *ensureNumber(NSObject *object, int base) {
    if ([object isKindOfClass:[NSNumber class]]) {
        return (NSNumber*)object;

    } else if ([object isKindOfClass:[NSString class]]) {
        if (base == 0) {
            base = ([(NSString*)object hasPrefix:@"0x"] ? 16: 10);
        }

        BigNumber *value = nil;
        if (base == 16) {
            value = [BigNumber bigNumberWithHexString:(NSString*)object];
        
        } else if (base == 10) {
            value = [BigNumber bigNumberWithDecimalString:(NSString*)object];
        }
        
        if (value && value.isSafeIntegerValue) {
            return [NSNumber numberWithInteger:value.integerValue];
        }
    }
    
    return nil;
}

BigNumber *ensureBigNumber(NSObject *object, int base) {
    if ([object isKindOfClass:[BigNumber class]]) {
        return (BigNumber*)object;
        
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return [BigNumber bigNumberWithNumber:(NSNumber*)object];
        
    } else if ([object isKindOfClass:[NSString class]]) {
        if (base == 0) {
            base = ([(NSString*)object hasPrefix:@"0x"] ? 16: 10);
        }

        BigNumber *value = nil;
        if (base == 16) {
            value = [BigNumber bigNumberWithHexString:(NSString*)object];
        } else if (base == 10) {
            value = [BigNumber bigNumberWithDecimalString:(NSString*)object];
        }
        if (value) { return value; }
    }
    
    return nil;
}

NSData *ensureData(NSObject *object) {
    if ([object isKindOfClass:[NSString class]]) {
        return [SecureData hexStringToData:(NSString*)object];
        
    } else if ([object isKindOfClass:[NSData class]]) {
        return (NSData*)object;
    }
    
    return nil;
}

Hash *ensureHash(NSObject *object) {
    if ([object isKindOfClass:[Hash class]]) {
        return (Hash*)object;
    }
    
    return [Hash hashWithData:ensureData(object)];
}

Address *ensureAddress(NSObject *object) {
    if ([object isKindOfClass:[Address class]]) {
        return (Address*)object;
    }
    
    return [Address addressWithData:ensureData(object)];
}

Class getPromiseClass(ApiProviderFetchType fetchType) {
    switch (fetchType) {
        case ApiProviderFetchTypeArray:
            return [ArrayPromise class];
        case ApiProviderFetchTypeBigNumber:
        case ApiProviderFetchTypeBigNumberDecimal:
        case ApiProviderFetchTypeBigNumberHexString:
            return [BigNumberPromise class];
        case ApiProviderFetchTypeBlockInfo:
            return [BlockInfoPromise class];
        case ApiProviderFetchTypeData:
            return [DataPromise class];
        case ApiProviderFetchTypeFloat:
            return [FloatPromise class];
        case ApiProviderFetchTypeHash:
            return [HashPromise class];
        case ApiProviderFetchTypeString:
            return [StringPromise class];
        case ApiProviderFetchTypeInteger:
        case ApiProviderFetchTypeIntegerDecimal:
        case ApiProviderFetchTypeIntegerHexString:
            return [IntegerPromise class];
        case ApiProviderFetchTypeObject:
            return [Promise class];
        case ApiProviderFetchTypeTransactionInfo:
            return [TransactionInfoPromise class];
        default:
            break;
    }
    
    return nil;
}

id coerceValue(NSObject *value, ApiProviderFetchType fetchType) {
    switch (fetchType) {
        case ApiProviderFetchTypeAddress:
            return ensureAddress(value);
        case ApiProviderFetchTypeArray:
            if ([value isKindOfClass:[NSArray class]]) {
                return value;
            }
            break;
        case ApiProviderFetchTypeBigNumber:
            return ensureBigNumber(value, 0);
        case ApiProviderFetchTypeBigNumberDecimal:
            return ensureBigNumber(value, 10);
        case ApiProviderFetchTypeBigNumberHexString:
            return ensureBigNumber(value, 16);
        case ApiProviderFetchTypeBlockInfo:
            if ([value isKindOfClass:[BlockInfo class]]) {
                return value;
            }
            return [BlockInfo blockInfoFromDictionary:coerceValue(value, ApiProviderFetchTypeDictionary)];

        case ApiProviderFetchTypeData:
            return ensureData(value);
        case ApiProviderFetchTypeDictionary:
            if ([value isKindOfClass:[NSDictionary class]]) {
                return value;
            }
            // @TODO: Maybe? If a string, try parsing as JSON?
            break;

        case ApiProviderFetchTypeJSONDictionary:
            {
                if ([value isKindOfClass:[NSString class]]) {
                    value = [(NSString*)value dataUsingEncoding:NSUTF8StringEncoding];
                }

                if ([value isKindOfClass:[NSData class]]) {
                    NSError *error = nil;
                    NSArray *object = [NSJSONSerialization JSONObjectWithData:(NSData*)value options:0 error:&error];
                    if (error || !object) {
                        NSLog(@"Error Parsing JSON: %@", error);
                    
                    } else {
                        return coerceValue(object, ApiProviderFetchTypeDictionary);
                    }
                }
            }
            break;
            
        case ApiProviderFetchTypeHash:
            return ensureHash(value);
        case ApiProviderFetchTypeFloat:
            return ensureFloat(value);
        case ApiProviderFetchTypeObject:
            return value;
        case ApiProviderFetchTypeInteger:
            return ensureNumber(value, 0);
        case ApiProviderFetchTypeIntegerDecimal:
            return ensureNumber(value, 10);
        case ApiProviderFetchTypeIntegerHexString:
            return ensureNumber(value, 16);
        case ApiProviderFetchTypeString:
            return [NSString stringWithFormat:@"%@", value];

        case ApiProviderFetchTypeTransactionInfo:
            if ([value isKindOfClass:[TransactionInfo class]]) {
                return value;
            }
            return [TransactionInfo transactionInfoFromDictionary:coerceValue(value, ApiProviderFetchTypeDictionary)];
            
        case ApiProviderFetchTypeNil:
            break;
    }

    return nil;
}

static ApiProviderFetchType fetchTypeForPathString(NSString *pathComponent) {
    if ([pathComponent isEqualToString:@"address"]) {
        return ApiProviderFetchTypeAddress;
    } else if ([pathComponent hasPrefix:@"array"]) {
        return ApiProviderFetchTypeArray;
    } else if ([pathComponent isEqualToString:@"bigNumber"]) {
        return ApiProviderFetchTypeBigNumber;
    } else if ([pathComponent isEqualToString:@"bigNumberDecimal"]) {
        return ApiProviderFetchTypeBigNumberDecimal;
    } else if ([pathComponent isEqualToString:@"bigNumberHex"]) {
        return ApiProviderFetchTypeBigNumberHexString;
    } else if ([pathComponent isEqualToString:@"blockInfo"]) {
        return ApiProviderFetchTypeBlockInfo;
    } else if ([pathComponent isEqualToString:@"data"]) {
        return ApiProviderFetchTypeData;
    } else if ([pathComponent hasPrefix:@"dictionary"]) {
        return ApiProviderFetchTypeDictionary;
    } else if ([pathComponent isEqualToString:@"float"]) {
        return ApiProviderFetchTypeFloat;
    } else if ([pathComponent isEqualToString:@"hash"]) {
        return ApiProviderFetchTypeHash;
    } else if ([pathComponent isEqualToString:@"integer"]) {
        return ApiProviderFetchTypeInteger;
    } else if ([pathComponent isEqualToString:@"integerDecimal"]) {
        return ApiProviderFetchTypeIntegerDecimal;
    } else if ([pathComponent isEqualToString:@"integerHex"]) {
        return ApiProviderFetchTypeIntegerHexString;
    } else if ([pathComponent hasPrefix:@"json"]) {
        return ApiProviderFetchTypeJSONDictionary;
//    } else if ([pathComponent isEqualToString:@"number"]) {
//        return ApiProviderFetchTypeNumber;
    } else if ([pathComponent isEqualToString:@"object"]) {
        return ApiProviderFetchTypeObject;
    } else if ([pathComponent isEqualToString:@"string"]) {
        return ApiProviderFetchTypeString;
    } else if ([pathComponent isEqualToString:@"transactionInfo"]) {
        return ApiProviderFetchTypeTransactionInfo;
    }
    
    NSLog(@"WARNING: Unhandled path type - %@", pathComponent);
    
    return ApiProviderFetchTypeNil;
}
                                                   
id queryPath(NSObject* object, NSString *path) {
    
    for (NSString *pathComponent in [path componentsSeparatedByString:@"/"]) {
        NSArray *components = [pathComponent componentsSeparatedByString:@":"];
        if (components.count > 2) { return nil; }

        object = coerceValue(object, fetchTypeForPathString([components firstObject]));

        if ([object isKindOfClass:[NSDictionary class]]) {
            if (components.count == 1) { return object; }
            object = [(NSDictionary*)object objectForKey:[components lastObject]];
            if (!object) { return nil; }
        
        } else if ([object isKindOfClass:[NSArray class]]) {
            if (components.count == 1) { return object; }
            NSInteger index = [[components lastObject] integerValue];
            if (index >= [(NSArray*)object count]) { return nil; }
            object = [(NSArray*)object objectAtIndex:index];
        
        } else {
            return object;
        }
    }
    
    return object;

}

NSMutableDictionary *transactionObject(Transaction *transaction) {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    if (transaction.toAddress) { [info setObject:transaction.toAddress.checksumAddress forKey:@"to"]; }
    if (transaction.fromAddress) { [info setObject:transaction.fromAddress.checksumAddress forKey:@"from"]; }
    if (![transaction.gasLimit isZero]) { [info setObject:stripHexZeros([transaction.gasLimit hexString]) forKey:@"gas"]; }
    if (![transaction.gasPrice isZero]) { [info setObject:stripHexZeros([transaction.gasPrice hexString]) forKey:@"gasPrice"]; }
    if (![transaction.value isZero]) { [info setObject:stripHexZeros([transaction.value hexString]) forKey:@"value"]; }
    if (transaction.data.length) { [info setObject:[SecureData dataToHexString:transaction.data] forKey:@"data"]; }
    
    return info;
}


#pragma mark -
#pragma mark - ApiProvider

@implementation ApiProvider {
    NSTimer *_statsTimer;
    NSTimeInterval _startTime;
    
    NSUInteger _requestCount, _errorCount;
}

- (instancetype)initWithChainId:(ChainId)chainId {
    self = [super initWithChainId:chainId];
    if (self) {
        _startTime = [NSDate timeIntervalSinceReferenceDate];
        
        _statsTimer = [NSTimer scheduledTimerWithTimeInterval:(5 * 60.0f) repeats:YES block:^(NSTimer *timer) {
            float dt = ([NSDate timeIntervalSinceReferenceDate] - _startTime) / 60.0f;
            NSLog(@"%@: %d calls/min (total: %d; errors: %d)", self, (int)(((float) _requestCount) / dt), (int)_requestCount, (int)_errorCount);
        }];
    }
    return self;
}

- (void)dealloc {
    [_statsTimer invalidate];
    _statsTimer = nil;
}

- (void)fetch: (NSURL*)url body: (NSData*)body callback: (void (^)(NSData*, NSError*))callback {
    void (^handleResponse)(NSData*, NSURLResponse*, NSError*) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            _errorCount++;
            NSDictionary *userInfo = @{@"error": error, @"url": url};
            callback(nil, [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorServerUnknownError userInfo:userInfo]);
            return;
        }
        
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            _errorCount++;
            NSDictionary *userInfo = @{@"reason": @"response not NSHTTPURLResponse", @"url": url};
            callback(nil, [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:userInfo]);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        if (httpResponse.statusCode != 200) {
            _errorCount++;
            NSDictionary *userInfo = @{@"statusCode": @(httpResponse.statusCode), @"url": url};
            callback(nil, [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:userInfo]);
            return;
        }
        
        callback(data, nil);
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        _requestCount++;
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        [request setValue:[Provider userAgent] forHTTPHeaderField:@"User-Agent"];
        
        if (body) {
            [request setHTTPMethod:@"POST"];
            [request setValue:[NSString stringWithFormat:@"%d", (int)body.length] forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:body];
        }
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:handleResponse];
        [task resume];
    });
    
}

- (id)promiseFetch:(NSURL *)url body:(NSData *)body fetchType:(ApiProviderFetchType)fetchType process:(NSObject *(^)(NSData*))process {
    Class promiseClass = getPromiseClass(fetchType);
    
    return [(Promise*)[promiseClass alloc] initWithSetup:^(Promise *promise) {
        [self fetch:url body:body callback:^(NSData *response, NSError *error) {
            if (error) {
                [promise reject:error];
                return;
            }
            
            NSObject *processed = process(response);

            if (!processed) {
                _errorCount++;
                NSMutableDictionary *userInfo = [@{@"reason": @"processed value is nil", @"url": url} mutableCopy];
                if (body) { [userInfo setObject:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] forKey:@"body"]; }
                if (response) { [userInfo setObject:[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] forKey:@"response"]; }
                [promise reject:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:userInfo]];
                return;
            
            } else if ([processed isKindOfClass:[NSError class]]) {
                _errorCount++;
                NSError *error = (NSError*)processed;
                NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
                [userInfo setObject:url forKey:@"url"];
                if (body) { [userInfo setObject:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] forKey:@"body"]; }
                if (response) { [userInfo setObject:[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] forKey:@"response"]; }
                [promise reject:[NSError errorWithDomain:error.domain code:error.code userInfo:userInfo]];
                return;
            }
            
            //NSLog(@"RESULT: %@", NSStringFromClass([processed class]));
            
            NSObject *result = nil;
            if (![processed isEqual:[NSNull null]]) {
                result = coerceValue(processed, fetchType);

                if (!result) {
                    _errorCount++;
                    NSMutableDictionary *userInfo = [@{@"reason": @"coerced value is nil", @"url": url} mutableCopy];
                    if (body) { [userInfo setObject:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] forKey:@"body"]; }
                    if (response) { [userInfo setObject:[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] forKey:@"response"]; }
                    [promise reject:[NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:userInfo]];
                    return;
                }
            }
            
            [promise resolve:result];
        }];
    }];
}

- (id)promiseFetchJSON: (NSURL*)url
                  body: (NSData*)body
             fetchType: (ApiProviderFetchType)fetchType
               process: (NSObject* (^)(NSDictionary*))process {
    
    return [self promiseFetch:url body:body fetchType:fetchType process:^NSObject*(NSData *response) {
        
        NSError *jsonError = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:response options:0 error:&jsonError];
        if (jsonError) {
            NSDictionary *userInfo = @{@"error": jsonError, @"reason": @"invalid JSON"};
            return [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:userInfo];

        } else if (!result) {
            NSDictionary *userInfo = @{@"reason": @"missing result"};
            return [NSError errorWithDomain:ProviderErrorDomain code:ProviderErrorBadResponse userInfo:userInfo];
        }
        
        return process(result);
    }];
}


@end
