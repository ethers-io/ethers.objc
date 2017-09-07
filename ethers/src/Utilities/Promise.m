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

#import "Promise.h"


NSErrorDomain PromiseErrorDomain = @"PromiseErrorDomain";


@implementation Promise {
    NSMutableArray<void (^)(Promise*)> *_completionCallbacks;
    Promise *_keepAlive;
}

+ (instancetype)promiseWithSetup:(void (^)(Promise *))setupCallback {
    return [[self alloc] initWithSetup:setupCallback];
}

- (instancetype)initWithSetup: (void (^)(Promise*))setupCallback {
    if (!setupCallback) { return nil; }
    
    self = [super init];
    if (self) {
        _completionCallbacks = [NSMutableArray array];
        setupCallback(self);
        
        _keepAlive = self;
    }
    
    return self;
}

- (void)executeCompleteion {

    // This must be called from a synchronized block
    for (void (^callback)(Promise*) in _completionCallbacks) {
        dispatch_async(dispatch_get_main_queue(), ^() {
                callback(self);
        });
    }
    
    _completionCallbacks = nil;

    _keepAlive = nil;
}

- (void)resolve: (NSObject*)result {
    if (!result) { result = [NSNull null]; }
    
    @synchronized (self) {
        if (_complete) { return; }
        _complete = YES;
        _result = result;
        [self executeCompleteion];
    }
}

- (void)reject: (NSError*)error {
    if (!error) { error = [NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{}]; }

    //NSLog(@"Rej: %@", error);
    
    @synchronized (self) {
        if (_complete) { return; }
        _complete = YES;
        _error = error;
        [self executeCompleteion];
    }
}

- (void)onCompletion: (void (^)(Promise*))completionCallback {
    @synchronized (self) {
        if (_complete) {
            dispatch_async(dispatch_get_main_queue(), ^() {
                completionCallback(self);
            });
        } else {
            [_completionCallbacks addObject:[completionCallback copy]];
        }
    }
}

+ (ArrayPromise*)all: (NSArray<Promise*>*)promises {
    promises = [promises copy];
    
    return [ArrayPromise promiseWithSetup:^(Promise *promise) {
        
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:promises.count];
        for (NSInteger i = 0; i < promises.count; i++) {
            [result addObject:[NSNull null]];
        }

        __block NSUInteger remainingPromises = promises.count;
        
        for (NSInteger i = 0; i < promises.count; i++) {
            [[promises objectAtIndex:i] onCompletion:^(Promise *childPromise) {
                
                // Already handled
                if (promise.complete) { return; }
                
                remainingPromises--;
                
                if (childPromise.error) {
                    [promise reject:childPromise.error];
                    
                } else {
                    [result replaceObjectAtIndex:i withObject:childPromise.result];
                    if (remainingPromises == 0) {
                        [promise resolve:result];
                    }
                }
            }];
        }
    }];
}

+ (Promise*)resolved: (NSObject*)result {
    return [[self alloc] initWithSetup:^(Promise *promise) {
        [promise resolve:result];
    }];
}

+ (Promise*)rejected: (NSError*)error {
    return [[self alloc] initWithSetup:^(Promise *promise) {
        [promise reject:error];
    }];
}

+ (Promise*)timer: (NSTimeInterval)timeout {
    return [Promise promiseWithSetup:^(Promise *promise) {
        [NSTimer scheduledTimerWithTimeInterval:5.0f repeats:NO block:^(NSTimer *timer) {
            [promise resolve:nil];
        }];
    }];
}

- (NSString*)description {
    NSString *state = @"PENDING";
    NSObject *result = nil;
    NSError *error = nil;
    
    @synchronized (self) {
        if (_complete) {
            state = (self.result ? @"RESOLVED": @"REJECTED");
        }
        result = _result;
        error = _error;
    }
    
    return [NSString stringWithFormat:@"<%@ state=%@ result=%@ error=%@>", NSStringFromClass([self class]), state, result, error];
}

@end


@implementation ArrayPromise

- (NSArray*)value {
    NSArray *value = (NSArray*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = @[]; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[NSArray class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(ArrayPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((ArrayPromise*)self);
    }];
}

@end


@implementation BigNumberPromise

- (BigNumber*)value {
    BigNumber *value = (BigNumber*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = [BigNumber constantZero]; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[BigNumber class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(BigNumberPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((BigNumberPromise*)self);
    }];
}

@end


@implementation BlockInfoPromise

- (BlockInfo*)value {
    BlockInfo *value = (BlockInfo*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = nil; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[BlockInfo class]] && ![[NSNull null] isEqual:result]) {
        NSLog(@"Invalid Value: %@", result);
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(BlockInfoPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((BlockInfoPromise*)self);
    }];
}

@end


@implementation DataPromise

- (NSData*)value {
    NSData *value = (NSData*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = [NSData data]; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[NSData class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(DataPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((DataPromise*)self);
    }];
}

@end


@implementation DictionaryPromise

- (NSDictionary*)value {
    NSDictionary *value = (NSDictionary*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = @{}; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[NSDictionary class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(DictionaryPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((DictionaryPromise*)self);
    }];
}

@end


@implementation FloatPromise

- (float)value {
    NSNumber *value = (NSNumber*)(super.result);
    if ([[NSNull null] isEqual:value]) { return 0.0f; }
    return [value floatValue];
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[NSNumber class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(FloatPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((FloatPromise*)self);
    }];
}

@end


@implementation HashPromise

- (Hash*)value {
    Hash *value = (Hash*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = [Hash zeroHash]; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[Hash class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(HashPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((HashPromise*)self);
    }];
}

@end


@implementation IntegerPromise

- (NSInteger)value {
    NSNumber *value = (NSNumber*)(super.result);
    if ([[NSNull null] isEqual:value]) { return 0; }
    return [value integerValue];
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[NSNumber class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(IntegerPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((IntegerPromise*)self);
    }];
}

@end


@implementation NumberPromise

- (NSNumber*)value {
    NSNumber *value = (NSNumber*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = [NSNumber numberWithInteger:0]; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[NSNumber class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(NumberPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((NumberPromise*)self);
    }];
}

@end


@implementation StringPromise

- (NSString*)value {
    NSString *value = (NSString*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = @""; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[NSString class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(StringPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((StringPromise*)self);
    }];
}

@end


@implementation TransactionInfoPromise

- (TransactionInfo*)value {
    TransactionInfo *value = (TransactionInfo*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = nil; }
    return value;
}

- (void)resolve:(NSObject *)result {
    if (result && ![result isKindOfClass:[TransactionInfo class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(TransactionInfoPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((TransactionInfoPromise*)self);
    }];
}

@end


@implementation AddressPromise

- (Address*)value {
    Address *value = (Address*)(super.result);
    if ([[NSNull null] isEqual:value]) { value = nil; }
    return value;
}

- (void)resolve: (NSObject *)result {
    if (result && ![result isKindOfClass:[Address class]]) {
        [super reject:[NSError errorWithDomain:PromiseErrorDomain code:0 userInfo:@{@"reason": @"invalid value", @"value": result}]];
        return;
    }
    [super resolve:result];
}

- (void)onCompletion: (void (^)(AddressPromise*))completionCallback {
    return [super onCompletion:^(Promise *promise) {
        completionCallback((AddressPromise*)self);
    }];
}

@end
