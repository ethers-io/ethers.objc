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

- (void)testSigningMessages {
    NSArray *tests = @[
                      // See: https://etherscan.io/verifySig/57
                      @{
                          @"address": @"0x14791697260E4c9A71f18484C9f997B308e59325",
                          @"name": @"string('hello world')",
                          @"message": @"0x68656c6c6f20776f726c64",
                          @"privateKey": @"0x0123456789012345678901234567890123456789012345678901234567890123",
                          @"signature": @"0xddd0a7290af9526056b4e35a077b9a11b513aa0028ec6c9880948544508f3c63265e99e47ad31bb2cab9646c504576b3abc6939a1710afc08cbf3034d73214b81c"
                          },
                      
                      // See: https://github.com/ethers-io/ethers.js/issues/80
                      @{
                          @"address": @"0xD351c7c627ad5531Edb9587f4150CaF393c33E87",
                          @"name": @"bytes(0x47173285...4cb01fad)",
                          @"message": @"0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad",
                          @"privateKey": @"0x51d1d6047622bca92272d36b297799ecc152dc2ef91b229debf84fc41e8c73ee",
                          @"signature": @"0x546f0c996fa4cfbf2b68fd413bfb477f05e44e66545d7782d87d52305831cd055fc9943e513297d0f6755ad1590a5476bf7d1761d4f9dc07dfe473824bbdec751b"
                          },
                      
                      // See: https://github.com/ethers-io/ethers.js/issues/85
                      @{
                          @"address": @"0xe7deA7e64B62d1Ca52f1716f29cd27d4FE28e3e1",
                          @"name": @"zero-prefixed signature",
                          @"message": @"0x69aff0e8e6bad68d84a1edb4175a4396d5a78d4d8b9d17e08034e2785bc8d2d7",
                          @"privateKey": @"0x09a11afa58d6014843fd2c5fd4e21e7fadf96ca2d8ce9934af6b8e204314f25c",
                          @"signature": @"0x7222038446034a0425b6e3f0cc3594f0d979c656206408f937c37a8180bb1bea047d061e4ded4aeac77fa86eb02d42ba7250964ac3eb9da1337090258ce798491c"
                          }
                      ];

    for (NSDictionary *test in tests) {
        NSData *privateKey = [SecureData hexStringToData:[test objectForKey:@"privateKey"]];
        NSData *message = [SecureData hexStringToData:[test objectForKey:@"message"]];
        Address *addressExpected = [Address addressWithString:[test objectForKey:@"address"]];
        Signature *signatureExpected = [Signature signatureWithData:[SecureData hexStringToData:[test objectForKey:@"signature"]]];
        
        Account *account = [Account accountWithPrivateKey:privateKey];
        Signature *signature = [account signMessage:message];
        XCTAssertEqualObjects(signatureExpected, signature, @"Copmputed signature matches");
        
        Address *verified = [Account verifyMessage:message signature:signature];
        XCTAssertEqualObjects(addressExpected, verified, @"Comnputed address matches");
        NSLog(@"Account: %@ %@ %@", account, addressExpected, verified);
    }
}

@end
