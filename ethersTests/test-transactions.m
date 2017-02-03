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
        
        NSData *expectedUnsignedData = [SecureData hexStringToData:[testCase objectForKey:@"unsignedTransaction"]];
        NSData *expectedSignedData = [SecureData hexStringToData:[testCase objectForKey:@"signedTransaction"]];

        NSData *expectedUnsignedDataChainId5 = [SecureData hexStringToData:[testCase objectForKey:@"unsignedTransactionChainId5"]];
        NSData *expectedSignedDataChainId5 = [SecureData hexStringToData:[testCase objectForKey:@"signedTransactionChainId5"]];

        // Test parsing transacions below (as will fill in the format transactions)
        Transaction *parsedUnsignedData = [Transaction transactionWithData:expectedUnsignedData];
        Transaction *parsedUnsignedDataChainId5 = [Transaction transactionWithData:expectedUnsignedDataChainId5];
        Transaction *parsedSignedData = [Transaction transactionWithData:expectedSignedData];
        Transaction *parsedSignedDataChainId5 = [Transaction transactionWithData:expectedSignedDataChainId5];
        
        Account *account = [Account accountWithPrivateKey:[SecureData hexStringToData: [testCase objectForKey:@"privateKey"]]];
        XCTAssertEqualObjects([account.address.checksumAddress lowercaseString], [[testCase objectForKey:@"accountAddress"] lowercaseString],
                              @"Failed account info: %@", name);
        _assertionCount++;

        XCTAssertEqualObjects(parsedSignedData.fromAddress, account.address, @"Failed signed deserialization: fromAddress");
        XCTAssertEqualObjects(parsedSignedDataChainId5.fromAddress, account.address, @"Failed unsigned5 deserialization: fromAddress");
        _assertionCount += 2;

        XCTAssertEqual(parsedUnsignedData.chainId, 0, @"Failed unsigned deserialization: chainId");
        XCTAssertEqual(parsedSignedData.chainId, 0, @"Failed signed deserialization: chainId");
        XCTAssertEqual(parsedUnsignedDataChainId5.chainId, 0, @"Failed unsigned5 deserialization: chainId");
        XCTAssertEqual(parsedSignedDataChainId5.chainId, 5, @"Failed signed5 deserialization: chainId");
        _assertionCount += 4;

        Transaction *transaction = [[Transaction alloc] init];
        Transaction *transactionChainId5 = [[Transaction alloc] init];
        if ([testCase objectForKey:@"nonce"]) {
            transaction.nonce = (NSUInteger)strtoll([[testCase objectForKey:@"nonce"] cStringUsingEncoding:NSASCIIStringEncoding], NULL, 16);
            transactionChainId5.nonce = transaction.nonce;

            XCTAssertEqual(parsedUnsignedData.nonce, transaction.nonce, @"Failed unsigned deserialization: nonce");
            XCTAssertEqual(parsedSignedData.nonce, transaction.nonce, @"Failed signed deserialization: nonce");
            XCTAssertEqual(parsedUnsignedDataChainId5.nonce, transaction.nonce, @"Failed unsigned5 deserialization: nonce");
            XCTAssertEqual(parsedSignedDataChainId5.nonce, transaction.nonce, @"Failed signed5 deserialization: nonce");
            _assertionCount += 4;
        
        } else {
            XCTAssertEqual(parsedUnsignedData.nonce, 0, @"Failed unsigned deserialization: !nonce");
            XCTAssertEqual(parsedSignedData.nonce, 0, @"Failed signed deserialization: !nonce");
            XCTAssertEqual(parsedUnsignedDataChainId5.nonce, 0, @"Failed unsigned5 deserialization: !nonce");
            XCTAssertEqual(parsedSignedDataChainId5.nonce, 0, @"Failed signed5 deserialization: !nonce");
            _assertionCount += 4;
        }
        
        if ([testCase objectForKey:@"gasPrice"]) {
            transaction.gasPrice = [BigNumber bigNumberWithHexString:[testCase objectForKey:@"gasPrice"]];
            transactionChainId5.gasPrice = transaction.gasPrice;
            
            XCTAssertEqualObjects(parsedUnsignedData.gasPrice, transaction.gasPrice, @"Failed unsigned deserialization: gasPrice");
            XCTAssertEqualObjects(parsedSignedData.gasPrice, transaction.gasPrice, @"Failed signed deserialization: gasPrice");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.gasPrice, transaction.gasPrice, @"Failed unsigned5 deserialization: gasPrice");
            XCTAssertEqualObjects(parsedSignedDataChainId5.gasPrice, transaction.gasPrice, @"Failed signed5 deserialization: gasPrice");
            _assertionCount += 4;
        
        } else {
            XCTAssertEqualObjects(parsedUnsignedData.gasPrice, [BigNumber constantZero], @"Failed unsigned deserialization: !gasPrice");
            XCTAssertEqualObjects(parsedSignedData.gasPrice, [BigNumber constantZero], @"Failed signed deserialization: !gasPrice");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.gasPrice, [BigNumber constantZero], @"Failed unsigned5 deserialization: !gasPrice");
            XCTAssertEqualObjects(parsedSignedDataChainId5.gasPrice, [BigNumber constantZero], @"Failed signed5 deserialization: !gasPrice");
            _assertionCount += 4;
        }

        if ([testCase objectForKey:@"gasLimit"]) {
            transaction.gasLimit = [BigNumber bigNumberWithHexString:[testCase objectForKey:@"gasLimit"]];
            transactionChainId5.gasLimit = transaction.gasLimit;

            XCTAssertEqualObjects(parsedUnsignedData.gasLimit, transaction.gasLimit, @"Failed unsigned deserialization: gasLimit");
            XCTAssertEqualObjects(parsedSignedData.gasLimit, transaction.gasLimit, @"Failed signed deserialization: gasLimit");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.gasLimit, transaction.gasLimit, @"Failed unsigned5 deserialization: gasLimit");
            XCTAssertEqualObjects(parsedSignedDataChainId5.gasLimit, transaction.gasLimit, @"Failed signed5 deserialization: gasLimit");
            _assertionCount += 4;
        
        } else {
            XCTAssertEqualObjects(parsedUnsignedData.gasLimit, [BigNumber constantZero], @"Failed unsigned deserialization: !gasLimit");
            XCTAssertEqualObjects(parsedSignedData.gasLimit, [BigNumber constantZero], @"Failed signed deserialization: !gasLimit");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.gasLimit, [BigNumber constantZero], @"Failed unsigned5 deserialization: !gasLimit");
            XCTAssertEqualObjects(parsedSignedDataChainId5.gasLimit, [BigNumber constantZero], @"Failed signed5 deserialization: !gasLimit");
            _assertionCount += 4;
        }

        if ([testCase objectForKey:@"to"]) {
            transaction.toAddress = [Address addressWithString:[testCase objectForKey:@"to"]];
            transactionChainId5.toAddress = transaction.toAddress;

            XCTAssertEqualObjects(parsedUnsignedData.toAddress, transaction.toAddress, @"Failed unsigned deserialization: toAddress");
            XCTAssertEqualObjects(parsedSignedData.toAddress, transaction.toAddress, @"Failed signed deserialization: toAddress");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.toAddress, transaction.toAddress, @"Failed unsigned5 deserialization: toAddress");
            XCTAssertEqualObjects(parsedSignedDataChainId5.toAddress, transaction.toAddress, @"Failed signed5 deserialization: toAddress");
            _assertionCount += 4;
        
        } else {
            XCTAssertEqualObjects(parsedUnsignedData.toAddress, nil, @"Failed unsigned deserialization: !toAddress");
            XCTAssertEqualObjects(parsedSignedData.toAddress, nil, @"Failed signed deserialization: !toAddress");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.toAddress, nil, @"Failed unsigned5 deserialization: !toAddress");
            XCTAssertEqualObjects(parsedSignedDataChainId5.toAddress, nil, @"Failed signed5 deserialization: !toAddress");
            _assertionCount += 4;
        }

        if ([testCase objectForKey:@"value"]) {
            transaction.value = [BigNumber bigNumberWithHexString:[testCase objectForKey:@"value"]];
            transactionChainId5.value = transaction.value;
            
            XCTAssertEqualObjects(parsedUnsignedData.value, transaction.value, @"Failed unsigned deserialization: value");
            XCTAssertEqualObjects(parsedSignedData.value, transaction.value, @"Failed signed deserialization: value");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.value, transaction.value, @"Failed unsigned5 deserialization: value");
            XCTAssertEqualObjects(parsedSignedDataChainId5.value, transaction.value, @"Failed signed5 deserialization: value");
            _assertionCount += 4;
        
        } else {
            XCTAssertEqualObjects(parsedUnsignedData.value, [BigNumber constantZero], @"Failed unsigned deserialization: !value");
            XCTAssertEqualObjects(parsedSignedData.value, [BigNumber constantZero], @"Failed signed deserialization: !value");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.value, [BigNumber constantZero], @"Failed unsigned5 deserialization: !value");
            XCTAssertEqualObjects(parsedSignedDataChainId5.value, [BigNumber constantZero], @"Failed signed5 deserialization: !value");
            _assertionCount += 4;
        }

        if ([testCase objectForKey:@"data"]) {
            transaction.data = [SecureData hexStringToData:[testCase objectForKey:@"data"]];
            transactionChainId5.data = transaction.data;
            
            XCTAssertEqualObjects(parsedUnsignedData.data, transaction.data, @"Failed unsigned deserialization: data");
            XCTAssertEqualObjects(parsedSignedData.data, transaction.data, @"Failed signed deserialization: data");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.data, transaction.data, @"Failed unsigned5 deserialization: data");
            XCTAssertEqualObjects(parsedSignedDataChainId5.data, transaction.data, @"Failed signed5 deserialization: data");
            _assertionCount += 4;
        
        } else {
            XCTAssertEqualObjects(parsedUnsignedData.data, transaction.data, @"Failed unsigned deserialization: data");
            XCTAssertEqualObjects(parsedSignedData.data, transaction.data, @"Failed signed deserialization: data");
            XCTAssertEqualObjects(parsedUnsignedDataChainId5.data, transaction.data, @"Failed unsigned deserialization: data");
            XCTAssertEqualObjects(parsedSignedDataChainId5.data, transaction.data, @"Failed signed (id: 5) deserialization: data");
            _assertionCount += 4;
        }
        

        // Check the unsigned transaction
        XCTAssertEqualObjects(expectedUnsignedData, [transaction serialize], @"Failed transaction serialization: %@", name);
        _assertionCount++;

        // Sign the transaction and check the signed transaction
        [account sign:transaction];
        XCTAssertEqualObjects(expectedSignedData, [transaction serialize], @"Failed transaction signature: %@", name);
        _assertionCount++;

        // Check the unsigned transaction (EIP 155)
        XCTAssertEqualObjects(expectedUnsignedDataChainId5, [transactionChainId5 serialize], @"Failed transaction serialization: %@", name);
        _assertionCount++;

        // Sign the transaction and check the signed transaction (EIP 155)
        transactionChainId5.chainId = 5;
        [account sign:transactionChainId5];
        XCTAssertEqualObjects(expectedSignedDataChainId5, [transactionChainId5 serialize], @"Failed EIP155 transaction signature: %@", name);
        _assertionCount++;
    }
}

@end
