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

#import <XCTest/XCTest.h>

#import "ethers.h"

NSObject *recursiveExpandData(NSObject *object) {
    if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *result = [NSMutableArray array];
        for (NSObject *child in (NSArray*)object) {
            [result addObject:recursiveExpandData(child)];
        }
        return result;
        
    } else if ([object isKindOfClass:[NSString class]]) {
        return [SecureData hexStringToData:(NSString*)object];
    }
    
    return nil;
}

BOOL recursiveEqual(NSObject *a, NSObject *b) {
//    NSLog(@"CMP: %@ %@", a, b);
    if ([a isKindOfClass:[NSData class]] && [b isKindOfClass:[NSData class]]) {
        return [(NSData*)a isEqualToData:(NSData*)b];
    }
    
    if ([a isKindOfClass:[NSArray class]] && [b isKindOfClass:[NSArray class]]) {
        NSArray *arrayA = (NSArray*)a, *arrayB = (NSArray*)b;
        if (arrayA.count != arrayB.count) { return NO; }
        for (NSInteger i = 0; i < arrayA.count; i++) {
            if (!recursiveEqual([arrayA objectAtIndex:i], [arrayB objectAtIndex:i])) {
                return NO;
            }
        }
        
        return YES;
    }
    
    return NO;
}

@interface test_rlpcoder : XCTestCase {
    int _assertionCount;
}

@end

@implementation test_rlpcoder

- (void)setUp {
    [super setUp];
    _assertionCount = 0;
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"test-rlpcoder: Finished %d assertions.", _assertionCount);
}

// @TODO: Test bad RLP

- (void)testJavascriptGeneratedTestCases {
    
    // Load the test cases generated from tests/make-rlp.js
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"tests-rlpcoder" ofType:@"json"];
    NSData *testCaseJson = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(testCaseJson, @"Error loading test cases");
    
    NSError *error = nil;
    NSArray *testCases = [NSJSONSerialization JSONObjectWithData:testCaseJson options:0 error:&error];
    XCTAssertNil(error, @"Error parsing test cases: %@", error);

    // Run each test case
    for (NSDictionary *testCase in testCases) {
        NSString *name = [testCase objectForKey:@"name"];

        // The correct encoding/decoing
        NSData *encoded = [SecureData hexStringToData:[testCase objectForKey:@"encoded"]];
        NSObject *decoded = recursiveExpandData([testCase objectForKey:@"decoded"]);
        
        // Check decoding works...
        NSObject *testDecoded = [RLPSerialization objectWithData:encoded error:nil];
        BOOL correctDecoding = recursiveEqual(testDecoded, decoded);
        if (!correctDecoding) {
            NSLog(@"Failed Decoding: %@", name);
            NSLog(@"Correct: %@", decoded);
            NSLog(@"Output: %@", testDecoded);
        }
        XCTAssert(correctDecoding, @"Failed Decoding: %@", name);
        _assertionCount++;
        
        // Check encoding works...
        NSData *testEncoded = [RLPSerialization dataWithObject:decoded error:nil];
        BOOL correctEncoding = [testEncoded isEqualToData:encoded];
        if (!correctEncoding) {
            NSLog(@"Failed Encoding: %@", name);
            NSLog(@"Correct: %@", encoded);
            NSLog(@"Output: %@", testEncoded);
        }
        XCTAssert(correctEncoding, @"Failed Encoding: %@", name);
        _assertionCount++;
    }
}


@end
