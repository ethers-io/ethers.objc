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

#import "Account.h"

#import "NSString+Secure.h"

@interface test_mnemonic_wallet : XCTestCase {
    int _assertionCount;
}
@end


@implementation test_mnemonic_wallet

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"test-mnemonic-wallet: Finished %d assertions.", _assertionCount);
}

- (void)testTestVectors {
    // Load the test cases generated from BIP test vectors
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"tests-trezor-bip39" ofType:@"json"];
    NSData *testCaseJson = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(testCaseJson, @"Error loading test cases");
    
    NSError *error = nil;
    NSArray *testCases = [[NSJSONSerialization JSONObjectWithData:testCaseJson options:0 error:&error] objectForKey:@"english"];
    XCTAssertNil(error, @"Error parsing test cases: %@", error);
    
    for (NSArray *testCase in testCases) {
        NSData *expectedData = [[@"0x" stringByAppendingString:[testCase objectAtIndex:0]] dataUsingHexEncoding];
        NSString *expectedMnemonic = [testCase objectAtIndex:1];
        
        {
            Account *account = [Account accountWithMnemonicPhrase:expectedMnemonic];
            
            XCTAssertEqualObjects(account.mnemonicPhrase, expectedMnemonic, @"Failed to store phrase: %@", expectedMnemonic);
            _assertionCount++;

            XCTAssertEqualObjects(account.mnemonicData, expectedData, @"Failed to generate correct data: %@", expectedMnemonic);
            _assertionCount++;
        }
        
        {
            Account *account = [Account accountWithMnemonicData:expectedData];
            
            XCTAssertEqualObjects(account.mnemonicData, expectedData, @"Failed to store data: %@", expectedMnemonic);
            _assertionCount++;

            XCTAssertEqualObjects(account.mnemonicPhrase, expectedMnemonic, @"Failed to generate correct phrase: %@", expectedMnemonic);
            _assertionCount++;
        }

    }
    
    // https://medium.com/@alexberegszaszi/why-do-my-bip32-wallets-disagree-6f3254cc5846#.smcbpaw47
    {
        NSString *mnemonicPhrase = @"radar blur cabbage chef fix engine embark joy scheme fiction master release";
        Address *address = [Address addressWithString:@"0xac39b311dceb2a4b2f5d8461c1cdaf756f4f7ae9"];
        
        Account *account = [Account accountWithMnemonicPhrase:mnemonicPhrase];

        XCTAssertEqualObjects(account.address, address, @"Failed AXIC test case; broken BIP32 implementation");
        _assertionCount++;

        XCTAssertEqualObjects(account.mnemonicPhrase, mnemonicPhrase, @"Failed AXIC test case; broken BIP32 implementation");
        _assertionCount++;
    }
    
}

@end
