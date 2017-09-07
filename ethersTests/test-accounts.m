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

@interface test_accounts : XCTestCase {
    int _assertionCount;
}

@end

@implementation test_accounts

- (void)setUp {
    [super setUp];
    _assertionCount = 0;
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"test-accounts: Finished %d assertions.", _assertionCount);
}

// @TODO: Test bad addresses
/*
- (void)testOnetime {
    NSString *address = @"0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE";
    NSString *icap = @"XE25TWJ4YIDKW7A8PN4G709KZMFOAOL3X8E";

    NSLog(@"FOO: %@ ", [Account normalizeAddress:icap icap:NO], address);
}
*/
- (void)testJavascriptGeneratedTestCases {
    // Load the test cases generated from tests/make-rlp.js
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"tests-accounts" ofType:@"json"];
    NSData *testCaseJson = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(testCaseJson, @"Error loading test cases");
    
    NSError *error = nil;
    NSArray *testCases = [NSJSONSerialization JSONObjectWithData:testCaseJson options:0 error:&error];
    XCTAssertNil(error, @"Error parsing test cases: %@", error);
    
    //int k = 0;
    // Run each test case
    for (NSDictionary *testCase in testCases) {
        //k++;
        //if (k > 10) { break; }
        NSString *address = [testCase objectForKey:@"address"];
        NSString *checksumAddress = [testCase objectForKey:@"checksumAddress"];
        NSString *icapAddress = [testCase objectForKey:@"icap"];
        
        // Lowercase to Checksum
        XCTAssertEqualObjects(checksumAddress,[Address addressWithString:[address lowercaseString]].checksumAddress,
                  @"Failed normalizeAddress: lowercaseToChecksum(%@)", address);
        _assertionCount++;

        // Uppercase to Checksum
        NSString *uppercaseAddress = [@"0x" stringByAppendingString:[[address substringFromIndex:2] uppercaseString]];
        XCTAssertEqualObjects(checksumAddress, [Address addressWithString:uppercaseAddress].checksumAddress,
                  @"Failed normalizeAddress: uppercaseToChecksum(%@)", address);
        _assertionCount++;
        
        // Checksum to Checksum
        XCTAssertEqualObjects(checksumAddress, [Address addressWithString:checksumAddress].checksumAddress,
                  @"Failed normalizeAddress: checksumToChecksum(%@)", address);
        _assertionCount++;

        // ICAP to Checksum
        XCTAssertEqualObjects(checksumAddress, [Address addressWithString:icapAddress].checksumAddress,
                              @"Failed normalizeAddress: icapToChecksum(%@)", icapAddress);
        _assertionCount++;

        // ICAP to ICAP
        XCTAssertEqualObjects(icapAddress, [Address addressWithString:icapAddress].icapAddress,
                              @"Failed normalizeAddress: icapToIcap(%@)", icapAddress);
        _assertionCount++;

        // Checksum to ICAP
        XCTAssertEqualObjects(icapAddress, [Address addressWithString:address].icapAddress,
                              @"Failed normalizeAddress: checksumToIcap(%@)", address);
        _assertionCount++;

        NSString *privateKey = [testCase objectForKey:@"privateKey"];
        if (!privateKey) { continue; }
        
        Account *account = [Account accountWithPrivateKey:[[SecureData secureDataWithHexString:privateKey] data]];
        XCTAssertEqualObjects(account.address.checksumAddress, checksumAddress, @"Failed privateKey to Address: %@", privateKey);
        _assertionCount++;
    }
}

- (void)testReportedBugs {
    // https://github.com/ethers-io/ethers.objc/pull/8
    // Reported by: https://github.com/zweigraf
    {
        NSString *privateKey = @"0x0123456789012345678901234567890123456789012345678901234567890123";
        Account *account = [Account accountWithPrivateKey:[SecureData hexStringToData:privateKey]];
        XCTAssertFalse([account isEqual:[NSNumber numberWithInteger:42]], @"Failed account equals non-Account object");
    }
}

@end
