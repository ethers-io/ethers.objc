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

#include "bip39.h"

#import "ethers.h"

@interface test_thirdparty : XCTestCase  {
    int _assertionCount;
}

@end


@implementation test_thirdparty

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"test-thirdparty: Finished %d assertions.", _assertionCount);
}

- (void)testBip39Changes {
    // Load the test cases generated from tests/make-rlp.js
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"tests-trezor-bip39" ofType:@"json"];
    NSData *testCaseJson = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(testCaseJson, @"Error loading test cases");
    
    NSError *error = nil;
    NSArray *testCases = [[NSJSONSerialization JSONObjectWithData:testCaseJson options:0 error:&error] objectForKey:@"english"];
    XCTAssertNil(error, @"Error parsing test cases: %@", error);

    for (NSArray *testCase in testCases) {
        NSData *expectedData = [SecureData hexStringToData:[@"0x" stringByAppendingString:[testCase objectAtIndex:0]]];
        NSString *expectedMnemonic = [testCase objectAtIndex:1];
        
        const char *mnemonicStr = mnemonic_from_data([expectedData bytes], (int)[expectedData length]);
        NSString *mnemonic = [NSString stringWithCString:mnemonicStr encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(mnemonic, expectedMnemonic, @"Failed to generate correct mnemonic: %@", expectedMnemonic);
        _assertionCount++;
    
        NSMutableData *dataFull = [NSMutableData dataWithLength:MAXIMUM_BIP39_DATA_LENGTH];
        int length = data_from_mnemonic([expectedMnemonic cStringUsingEncoding:NSUTF8StringEncoding], [dataFull mutableBytes]);
        
        NSData *data = [dataFull subdataWithRange:NSMakeRange(0, length)];
        XCTAssertEqualObjects(data, expectedData, @"Failed to match data: %@", expectedMnemonic);
        _assertionCount++;
    }
    
    NSArray *testCaseFail = @[
                              @"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon",
                              @"ricmoo ricmoo ricmoo ricmoo ricmoo ricmoo ricmoo ricmoo ricmoo ricmoo ricmoo ricmoo",
                              @"",
                              @"legal winner thank year wave sausage worth useful legal winner thank thank",
                              @"letter advice cage absurd amount doctor acoustic avoid letter advice cage zoo",
                           ];
    
    for (NSString *testCase in testCaseFail) {
        BOOL valid = mnemonic_check([testCase cStringUsingEncoding:NSUTF8StringEncoding]);
        XCTAssertFalse(valid, @"Failed to fail mnemonic: %@", testCase);
        _assertionCount++;
    }
}


@end
