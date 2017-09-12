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
    int _assertionCount;
}

@end


@implementation test_providers

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"test-providers: Finished %d assertions.", _assertionCount);
}

- (void)doTestGetBlock: (Hash*)blockHash blockNumber: (NSInteger)blockNumber checkBlock: (void (^)(BlockInfo*))checkBlock {

    NSArray<Provider*> *providers = @[
                                      [[EtherscanProvider alloc] initWithChainId:ChainIdRopsten apiKey:nil],
                                      [[InfuraProvider alloc] initWithChainId:ChainIdRopsten accessToken:@"VOSzw3GAef7pxbSbpYeL"],
                                      ];

    for (Provider *provider in providers) {
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

    for (Provider *provider in providers) {
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

- (void)testRopstenGetBlock {
    
    // @TODO: Move this into a JSON file and provider test cases for all networks
    
    // Block: https://ropsten.etherscan.io/block/1
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


- (void)testEthereumNameService {
    NSArray<Provider*> *providers = @[
                                      [[EtherscanProvider alloc] initWithChainId:ChainIdRopsten apiKey:nil],
                                      [[InfuraProvider alloc] initWithChainId:ChainIdRopsten accessToken:@"VOSzw3GAef7pxbSbpYeL"],
                                      ];

    // @TODO: Add test cases for livenet
    
    NSString *name = @"ricmoo.firefly.eth";
    Address *address = [Address addressWithString:@"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"];
    for (Provider *provider in providers) {
        {
            NSString *title = [NSString stringWithFormat:@"Test/%@/testEthereumNameServiceNameValid", NSStringFromClass([provider class])];
            XCTestExpectation *expect = [self expectationWithDescription:title];
            [[provider lookupName:name] onCompletion:^(AddressPromise *promise) {
                XCTAssertNil(promise.error, @"Error occurred");
                _assertionCount++;

                XCTAssertEqualObjects(promise.value, address,
                                      @"Address mismatch");
                _assertionCount++;

                [expect fulfill];
            }];
            [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
                XCTAssertNil(error, @"Timeout: %@", title);
                _assertionCount++;
            }];
        }
        
        {
            NSString *title = [NSString stringWithFormat:@"Test/%@/testEthereumNameServiceAddressValid", NSStringFromClass([provider class])];
            XCTestExpectation *expect = [self expectationWithDescription:title];
            [[provider lookupAddress:address] onCompletion:^(StringPromise *promise) {
                XCTAssertNil(promise.error, @"Error occurred");
                _assertionCount++;

                XCTAssertEqualObjects(promise.value, name,
                                      @"Name mismatch");
                _assertionCount++;

                [expect fulfill];
            }];
            [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
                XCTAssertNil(error, @"Timeout: %@", title);
                _assertionCount++;
            }];
        }
        
        {
            NSString *title = [NSString stringWithFormat:@"Test/%@/testEthereumNameServiceNameInvalid", NSStringFromClass([provider class])];
            XCTestExpectation *expect = [self expectationWithDescription:title];
            [[provider lookupName:@"short.eth"] onCompletion:^(AddressPromise *promise) {
                XCTAssertTrue(promise.error.code == ProviderErrorNotFound,
                              @"Name not missing");
                _assertionCount++;

                [expect fulfill];
            }];
            [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
                XCTAssertNil(error, @"Timeout: %@", title);
                _assertionCount++;
            }];
        }
        {
            NSString *title = [NSString stringWithFormat:@"Test/%@/testEthereumNameServiceAddressInvalid", NSStringFromClass([provider class])];
            XCTestExpectation *expect = [self expectationWithDescription:title];
            Address *address = [Address addressWithString:@"0x0123456789012345678901234567890123456789"];
            [[provider lookupAddress:address] onCompletion:^(StringPromise *promise) {
                XCTAssertTrue(promise.error.code == ProviderErrorNotFound,
                              @"Address not missing");
                _assertionCount++;

                [expect fulfill];
            }];
            [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
                XCTAssertNil(error, @"Timeout: %@", title);
                _assertionCount++;
            }];
        }
        
        // @TODO: Add testcase for Address => Name, but Name !=> Address

    }
}


/**
 *  This tests
 *    - getBalance
 *    - getStorageAt
 */
- (void)doTestContract: (Provider*)provider {
    Address *address = [Address addressWithString:@"0xffc3f1d12ac2da06193711404dd9ff4fc0e405d0"];
    
    {
        NSString *title = [NSString stringWithFormat:@"Test/%@/testContractGetStorageAt", NSStringFromClass([provider class])];
        XCTestExpectation *expect = [self expectationWithDescription:title];
        [[provider getStorageAt:address position:[BigNumber bigNumberWithInteger:2]] onCompletion:^(HashPromise *promise) {
            XCTAssertNil(promise.error, @"Test Contact chainId had an error");
            _assertionCount++;
            
            BigNumber *value = [BigNumber bigNumberWithHexString:[promise.value hexString]];
            XCTAssertTrue(value.isSafeIntegerValue,
                          @"Test Contract chainId is not safe integer");
            _assertionCount++;
            
            XCTAssertEqual([value integerValue], provider.chainId,
                           @"Test Contract chainId did not match");
            _assertionCount++;
            
            [expect fulfill];
        }];

        [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
            XCTAssertNil(error, @"Timeout: %@", title);
            _assertionCount++;
        }];
    }

    {
        NSString *title = [NSString stringWithFormat:@"Test/%@/testContractBalance", NSStringFromClass([provider class])];
        XCTestExpectation *expect = [self expectationWithDescription:title];
        [[provider getBalance:address] onCompletion:^(BigNumberPromise *promise) {
            XCTAssertNil(promise.error, @"Test Contact balance had an error");
            _assertionCount++;

            XCTAssertEqualObjects(promise.value, [BigNumber bigNumberWithHexString:@"0x11db9e76a2483"],
                                  @"Test Contract balance did not match");
            _assertionCount++;
            
            [expect fulfill];
        }];
        
        [self waitForExpectationsWithTimeout:10.0f handler:^(NSError *error) {
            XCTAssertNil(error, @"Timeout: %@", title);
            _assertionCount++;
        }];
    }
}

- (void)testContract {
    NSArray *providers = @[
                           [[InfuraProvider alloc] initWithChainId:ChainIdRopsten],
                           [[InfuraProvider alloc] initWithChainId:ChainIdRinkeby],
                           [[InfuraProvider alloc] initWithChainId:ChainIdKovan],
                           [[EtherscanProvider alloc] initWithChainId:ChainIdRopsten],
                           [[EtherscanProvider alloc] initWithChainId:ChainIdRinkeby],
                           [[EtherscanProvider alloc] initWithChainId:ChainIdKovan]
                           ];

    for (Provider *provider in providers) {
        [self doTestContract:provider];
    }
}

@end
