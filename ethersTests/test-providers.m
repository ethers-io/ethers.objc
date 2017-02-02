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


@interface test_providers : XCTestCase {
    NSArray<Provider*> *_providers;
    int _assertionCount;
}

@end


@implementation test_providers

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _providers = @[
                   [[EtherscanProvider alloc] initWithTestnet:YES apiKey:nil],
                   [[InfuraProvider alloc] initWithTestnet:YES accessToken:@"VOSzw3GAef7pxbSbpYeL"],
                   ];
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"test-providers: Finished %d assertions.", _assertionCount);
}
/*
- (void)prepareGetBalance: (Address*)address expectedBalance: (NSString*)expectedBalance testnet: (BOOL)testnet {
    EtherscanProvider *etherscanProvider = [[EtherscanProvider alloc] initWithTestnet:testnet apiKey:nil];
    
    XCTestExpectation *expectGetBalance = [self expectationWithDescription:@"getBalance"];
    [etherscanProvider getBalance:address callback:^(BigNumber *balance, NSError *error) {
        XCTAssertNil(error, @"Error calling Etherscan");
        XCTAssertTrue([[balance decimalString] isEqualToString:expectedBalance], @"Wrong balance");
        [expectGetBalance fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
        XCTAssertNil(error, @"Timeout calling Etherscan");
    }];
}

- (void)testDebug {
    Address *address = [Address addressWithString:@"0x88a5C2d9919e46F883EB62F7b8Dd9d0CC45bc290"];
    EtherscanProvider *etherscanProvider = [[EtherscanProvider alloc] initWithTestnet:YES apiKey:nil];

    XCTestExpectation *expect = [self expectationWithDescription:@"getTransactions"];

    [etherscanProvider getTransactions:address startBlock:0 callback:^(NSArray<TransactionInfo*> *transactions, NSError *error) {
        NSLog(@"Result: %@ %@", transactions, error);
        [expect fulfill];
    }];


    [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
        XCTAssertNil(error, @"Timeout calling Etherscan");
    }];
}
- (void)testGetBalance {
    [self prepareGetBalance:[Address addressWithString:@"0xb2682160c482eb985ec9f3e364eec0a904c44c23"]
            expectedBalance:@"964821158108923821" testnet:NO];
    [self prepareGetBalance:[Address addressWithString:@"0x03a6F7a5ce5866d9A0CCC1D4C980b8d523f80480"]
            expectedBalance:@"26674736281316788488" testnet:YES];
}
 */

- (void)doTestGetBlock: (Hash*)blockHash blockNumber: (NSInteger)blockNumber checkBlock: (void (^)(BlockInfo*))checkBlock {
    for (Provider *provider in _providers) {
        NSString *title = [NSString stringWithFormat:@"Test/%@/getBlockByBlockHash", NSStringFromClass([provider class])];
        NSLog(@"Test Case: %@", title);
        
        XCTestExpectation *expect = [self expectationWithDescription:title];
        [[provider getBlockByBlockHash:blockHash] onCompletion:^(BlockInfoPromise *promise) {
            if (promise.error.code == ProviderErrorNotImplemented) {
                NSLog(@"Not Implemented: %@", title);
            } else {
                BlockInfo *blockInfo = promise.value;
                XCTAssertEqualObjects(blockInfo.blockHash, blockHash, @"BlockHash mismatch");
                XCTAssertEqual(blockInfo.blockNumber, blockNumber, @"BlockNumber mismatch");
                checkBlock(blockInfo);
            }
            [expect fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
            XCTAssertNil(error, @"Timeout: %@", title);
            _assertionCount++;
        }];
    }

    for (Provider *provider in _providers) {
        NSString *title = [NSString stringWithFormat:@"Test/%@/getBlockByBlockTag", NSStringFromClass([provider class])];
        NSLog(@"Test Case: %@", title);
        
        XCTestExpectation *expect = [self expectationWithDescription:title];
        [[provider getBlockByBlockTag:blockNumber] onCompletion:^(BlockInfoPromise *promise) {
            if (promise.error.code == ProviderErrorNotImplemented) {
                NSLog(@"Not Implemented: %@", title);
            } else {
                BlockInfo *blockInfo = promise.value;
                XCTAssertEqualObjects(blockInfo.blockHash, blockHash, @"BlockHash mismatch");
                XCTAssertEqual(blockInfo.blockNumber, blockNumber, @"BlockNumber mismatch");
                _assertionCount += 2;
                checkBlock(blockInfo);
            }
            [expect fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
            XCTAssertNil(error, @"Timeout: %@", title);
            _assertionCount++;
        }];
    }
}

- (void)testGetBlock {
    
    // Block: https://testnet.etherscan.io/block/1
    {
        Hash *parentHash = [Hash hashWithHexString:@"0x41941023680923e0fe4d74a34bdac8141f2540e3ae90623718e47d66d1ca4a2d"];
        NSData *extraData = [SecureData hexStringToData:@"0xd883010503846765746887676f312e372e318664617277696e"];
        BigNumber *gasLimit = [BigNumber bigNumberWithDecimalString:@"16760833"];
        BigNumber *gasUsed = [BigNumber bigNumberWithDecimalString:@"0"];
        
        void (^checkBlockInfo)(BlockInfo*) = ^(BlockInfo *blockInfo) {
            XCTAssertEqualObjects(blockInfo.parentHash, parentHash, @"ParentHash mismatch");
            XCTAssertEqualObjects(blockInfo.extraData, extraData, @"ExtraData mismatch");
            XCTAssertEqualObjects(blockInfo.gasLimit, gasLimit, @"GasLimit mismatch");
            XCTAssertEqualObjects(blockInfo.gasUsed, gasUsed, @"GasUsed mismatch");
            _assertionCount += 4;
        };

        Hash *blockHash = [Hash hashWithHexString:@"0x41800b5c3f1717687d85fc9018faac0a6e90b39deaa0b99e7fe4fe796ddeb26a"];
        NSInteger blockNumber = 1;
        [self doTestGetBlock:blockHash blockNumber:blockNumber checkBlock:checkBlockInfo];
    }
    
    // Block: https://testnet.etherscan.io/block/55555
    {
        Hash *parentHash = [Hash hashWithHexString:@"0x748e50927fd75445efe2ff20ff5d492c1ce11f89517ea06e3a0e685e99889b4f"];
        NSData *extraData = [SecureData hexStringToData:@"0xd783010502846765746887676f312e372e33856c696e7578"];
        BigNumber *gasLimit = [BigNumber bigNumberWithDecimalString:@"4712388"];
        BigNumber *gasUsed = [BigNumber bigNumberWithDecimalString:@"344142"];
        
        void (^checkBlockInfo)(BlockInfo*) = ^(BlockInfo *blockInfo) {
            XCTAssertEqualObjects(blockInfo.parentHash, parentHash, @"ParentHash mismatch");
            XCTAssertEqualObjects(blockInfo.extraData, extraData, @"ExtraData mismatch");
            XCTAssertEqualObjects(blockInfo.gasLimit, gasLimit, @"GasLimit mismatch");
            XCTAssertEqualObjects(blockInfo.gasUsed, gasUsed, @"GasUsed mismatch");
            
            _assertionCount += 4;
        };
        
        Hash *blockHash = [Hash hashWithHexString:@"0xbf28f3c3f0caa79a74c7930ad649d13bf27224fa1e638a94128e316ef42932e5"];
        NSInteger blockNumber = 55555;
        [self doTestGetBlock:blockHash blockNumber:blockNumber checkBlock:checkBlockInfo];
    }
}

@end
