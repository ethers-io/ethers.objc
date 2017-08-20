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

@interface test_ether_format : XCTestCase {
    int _assertionCount;
}

@end

@implementation test_ether_format

- (void)setUp {
    [super setUp];
    _assertionCount = 0;
}

- (void)tearDown {
    [super tearDown];
    NSLog(@"test-ether-format: Finished %d assertions.", _assertionCount);
}

- (void)testParse {
    NSArray *tests = @[
                       @{@"test": @"123.012345678901234567", @"result": @"123012345678901234567"},
                       @{@"test": @"1.0", @"result": @"1000000000000000000"},
                       @{@"test": @"1", @"result": @"1000000000000000000"},
                       @{@"test": @"1.00", @"result": @"1000000000000000000"},
                       @{@"test": @"01.0", @"result": @"1000000000000000000"},

                       @{@"test": @"0", @"result": @"0"},
                       @{@"test": @"-0", @"result": @"0"},
                       @{@"test": @"00", @"result": @"0"},
                       @{@"test": @"0.0", @"result": @"0"},
                       @{@"test": @".00", @"result": @"0"},
                       @{@"test": @"00.00", @"result": @"0"},

                       @{@"test": @"-1.0", @"result": @"-1000000000000000000"},
                       
                       @{@"test": @"0.1", @"result": @"100000000000000000"},
                       @{@"test": @".1", @"result": @"100000000000000000"},
                       @{@"test": @"0.10", @"result": @"100000000000000000"},
                       @{@"test": @".100", @"result": @"100000000000000000"},
                       @{@"test": @"00.100", @"result": @"100000000000000000"},
                       
                       @{@"test": @"-0.1", @"result": @"-100000000000000000"},
                       ];
    
    for (NSDictionary *testcase in tests) {
        BigNumber *expected = [BigNumber bigNumberWithDecimalString:[testcase objectForKey:@"result"]];
        BigNumber *result = [Payment parseEther:[testcase objectForKey:@"test"]];
        XCTAssertEqualObjects(result, expected, @"Failed to parse ether: %@", [testcase objectForKey:@"test"]);
        _assertionCount++;
    }
}

- (void)testFormat {
    NSArray *tests = @[
                       @{@"test": @"10000000000000000", @"result": @"0.01", @"options": @(0)},
                       @{@"test": @"1000000000000000000", @"result": @"1.0", @"options": @(0)},
                       @{@"test": @"1230000000000000000", @"result": @"1.23", @"options": @(0)},
                       @{@"test": @"-1230000000000000000", @"result": @"-1.23", @"options": @(0)},

                       @{@"test": @"1000000000000000000", @"result": @"1.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"1234567890000000000000000", @"result": @"1,234,567.89", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"-1234567890000000000000000", @"result": @"-1,234,567.89", @"options": @(EtherFormatOptionCommify)},

                       @{@"test": @"100000000000000000", @"result": @"0.1", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"1000000000000000000", @"result": @"1.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"10000000000000000000", @"result": @"10.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"100000000000000000000", @"result": @"100.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"1000000000000000000000", @"result": @"1,000.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"10000000000000000000000", @"result": @"10,000.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"100000000000000000000000", @"result": @"100,000.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"1000000000000000000000000", @"result": @"1,000,000.0", @"options": @(EtherFormatOptionCommify)},

                       @{@"test": @"-100000000000000000", @"result": @"-0.1", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"-1000000000000000000", @"result": @"-1.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"-10000000000000000000", @"result": @"-10.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"-100000000000000000000", @"result": @"-100.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"-1000000000000000000000", @"result": @"-1,000.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"-10000000000000000000000", @"result": @"-10,000.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"-100000000000000000000000", @"result": @"-100,000.0", @"options": @(EtherFormatOptionCommify)},
                       @{@"test": @"-1000000000000000000000000", @"result": @"-1,000,000.0", @"options": @(EtherFormatOptionCommify)},
                       ];

    // TODO: Add tests for approximate
    
    for (NSDictionary *testcase in tests) {
        NSString *expected = [testcase objectForKey:@"result"];
        NSString *result = [Payment formatEther:[BigNumber bigNumberWithDecimalString:[testcase objectForKey:@"test"]]
                                        options:[[testcase objectForKey:@"options"] unsignedIntegerValue]];
        XCTAssertEqualObjects(result, expected, @"Failed to format ether: %@", [testcase objectForKey:@"test"]);
        _assertionCount++;
    }
}

- (void)testParseFailures {
    NSArray *tests = @[
                       @"",
                       @".",
                       @"-",
                       @"0.0.0",
                       @"a",
                       @"0.1\nfoobar",
                       @"0.a",
                       @"a.0",
                       @"123.a",
                       @"a.1234",
                       @"0x56",
                       @"1.0123456789012345678",  // Too many decimals
                       @"-1.0123456789012345678", // Too many decimals (negative)
                       @"--1.3",
                       ];
    
    for (NSString *testcase in tests) {
        BigNumber *result = [Payment parseEther:testcase];
        XCTAssertNil(result, @"Failed to fail on parse ether: %@", testcase);
        _assertionCount++;
    }
}

- (void)testParseURI {
    NSArray *tests = @[
                       @{
                           @"uri": @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban:XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban:XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                          @"uri": @"iban://0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6?amount=1.234",
                          @"amount": @"1.234",
                          @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                          },
                       @{
                           @"uri": @"iban:0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban://0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban:0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234&extraAfter=foo",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?extraBefore=bar&amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?extraBefore=bar&amount=1.234&extraAfter=foo",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?AmoUnT=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?AmoUnT=1.234&foobar",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?%61%6d%6f%75%6e%74=%31%2e%32%33%34",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"IBAN://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"eth:0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"ether:0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                       @{
                           @"uri": @"ethereum:0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6?amount=1.234",
                           @"amount": @"1.234",
                           @"address": @"0x06B5955A67D827CDF91823E3bB8F069e6c89c1D6"
                           },
                      ];
    
    for (NSDictionary *testcase in tests) {
        NSString *uri = [testcase objectForKey:@"uri"];
        Payment *payment = [Payment paymentWithURI:uri];
        
        NSString *address = [[testcase objectForKey:@"address"] lowercaseString];
        XCTAssertEqualObjects([payment.address.checksumAddress lowercaseString], address, @"Failed to parse URI address: %@", uri);
        _assertionCount++;
        
        BigNumber *expectedAmount = [Payment parseEther:[testcase objectForKey:@"amount"]];
        XCTAssertEqualObjects(payment.amount, expectedAmount, @"Failed to parse URI amount: %@", uri);
        _assertionCount++;
    }

}

- (void)testParseURIFailures {
    NSArray *tests = @[
                       @"",
                       @"foobar",
                       @"iban",
                       @"iban:",
                       @"iban://",
                       @"iban://foobar",
                       @"iban://foobar?amount=1.234",
                       @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.23Q",
                       @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLO",
                       @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234&foo=bar&amount=1.2345",
                       @"http://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234",
                       @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI/foobar?amount=1.234",
                       @"iban://XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI:8000?amount=1.234",
                       @"iban://ricmoo@XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234",
                       @"iban://:password@XE68S7PCGWBX6SF95M9C1KVXUWCWTPLPLI?amount=1.234",
                       ];
    
    for (NSString *testcase in tests) {
        Payment *result = [Payment paymentWithURI:testcase];
        XCTAssertNil(result, @"Failed to fail on parseURI: %@", testcase);
        _assertionCount++;
    }
}

@end
