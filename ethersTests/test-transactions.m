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
#import "Transaction.h"

#import "NSString+Secure.h"

@interface test_transactions : XCTestCase {
    int _assertionCount;
}

@end

@implementation test_transactions

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"test-transactions: Finished %d assertions.", _assertionCount);
}

- (void)testJavascriptGeneratedTestCases {
    // Load the test cases generated from tests/make-rlp.js
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"tests-transactions" ofType:@"json"];
    NSData *testCaseJson = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(testCaseJson, @"Error loading test cases");
    
    NSError *error = nil;
    NSArray *testCases = [NSJSONSerialization JSONObjectWithData:testCaseJson options:0 error:&error];
    XCTAssertNil(error, @"Error parsing test cases: %@", error);
    
    
    // Run each test case
    for (NSDictionary *testCase in testCases) {
        NSString *name = [testCase objectForKey:@"name"];
        
        NSData *expectedUnsignedData = [(NSString*)[testCase objectForKey:@"unsignedTransaction"] dataUsingHexEncoding];
        NSData *expectedSignedData = [(NSString*)[testCase objectForKey:@"signedTransaction"] dataUsingHexEncoding];

        NSData *expectedSignedDataChainId5 = [(NSString*)[testCase objectForKey:@"signedTransactionChainId5"] dataUsingHexEncoding];

        Account *account = [Account accountWithPrivateKey:[(NSString*)[testCase objectForKey:@"privateKey"] dataUsingHexEncoding]];
        XCTAssertEqualObjects([account.address.checksumAddress lowercaseString], [[testCase objectForKey:@"accountAddress"] lowercaseString],
                              @"Failed account info: %@", name);
        _assertionCount++;
        
        Transaction *transaction = [[Transaction alloc] init];
        Transaction *transactionChainId5 = [[Transaction alloc] init];
        if ([testCase objectForKey:@"nonce"]) {
            transaction.nonce = (NSUInteger)strtoll([[testCase objectForKey:@"nonce"] cStringUsingEncoding:NSASCIIStringEncoding], NULL, 16);
            transactionChainId5.nonce = transaction.nonce;
        }
        
        if ([testCase objectForKey:@"gasPrice"]) {
            transaction.gasPrice = [BigNumber bigNumberWithHexString:[testCase objectForKey:@"gasPrice"]];
            transactionChainId5.gasPrice = transaction.gasPrice;
        }

        if ([testCase objectForKey:@"gasLimit"]) {
            transaction.gasLimit = [BigNumber bigNumberWithHexString:[testCase objectForKey:@"gasLimit"]];
            transactionChainId5.gasLimit = transaction.gasLimit;
        }

        if ([testCase objectForKey:@"to"]) {
            transaction.toAddress = [Address addressWithString:[testCase objectForKey:@"to"]];
            transactionChainId5.toAddress = transaction.toAddress;
        }

        if ([testCase objectForKey:@"value"]) {
            transaction.value = [BigNumber bigNumberWithHexString:[testCase objectForKey:@"value"]];
            transactionChainId5.value = transaction.value;
        }

        if ([testCase objectForKey:@"data"]) {
            transaction.data = [(NSString*)[testCase objectForKey:@"data"] dataUsingHexEncoding];
            transactionChainId5.data = transaction.data;
        }

        // Check the unsigned transaction
        XCTAssertEqualObjects(expectedUnsignedData, [transaction serialize], @"Failed transaction serialization: %@", name);
        _assertionCount++;

        // Sign the transaction and check the signed transaction
        [account sign:transaction];
        XCTAssertEqualObjects(expectedSignedData, [transaction serialize], @"Failed transaction signature: %@", name);
        _assertionCount++;
        
        // Sign the transaction and check the signed transaction (EIP 155)
        transactionChainId5.chainId = 5;
        [account sign:transactionChainId5];
        XCTAssertEqualObjects(expectedSignedDataChainId5, [transactionChainId5 serialize], @"Failed EIP155 transaction signature: %@", name);
        _assertionCount++;

    }
}

@end
