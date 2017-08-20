//
//  Utilities.m
//  ethers
//
//  Created by Richard Moore on 2017-02-01.
//  Copyright © 2017 Ethers. All rights reserved.
//

#import "Utilities.h"

#import "RegEx.h"
#import "SecureData.h"

NSData *convertIntegerToData(NSUInteger value) {
    unsigned char bytes[sizeof(NSUInteger)];
    int offset = sizeof(bytes);
    
    while (value) {
        bytes[--offset] = (value & 0xff);
        value >>= 8;
    }
    
    return [NSData dataWithBytes:&bytes[offset] length:(sizeof(bytes) - offset)];
}

Hash* namehash(NSString *name) {
    name = [name lowercaseString];
    
    // @TODO: Support full IDNA
    // For now though, we accept this subset
    static RegEx *ascii7 = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ascii7 = [RegEx regExWithPattern:@"[a-z0-9.-]*"];
    });
    
    if (!ascii7 || ![ascii7 matchesExactly:name]) {
        return nil;
    }
    
    NSMutableData *result = [[Hash zeroHash].data mutableCopy];
    
    NSArray *parts = [name componentsSeparatedByString:@"."];
    for (NSInteger i = parts.count - 1; i >= 0; i--) {
        NSData *label = [[parts objectAtIndex:i] dataUsingEncoding:NSUTF8StringEncoding];
        
        [result appendData:[SecureData KECCAK256:label]];
        
        result = [[SecureData KECCAK256:result] mutableCopy];
    }
    
    return [Hash hashWithData:result];
}

NSString *stripHexZeros(NSString *hexString) {
    while ([hexString hasPrefix:@"0x0"] && hexString.length > 3) {
        hexString = [@"0x" stringByAppendingString:[hexString substringFromIndex:3]];
    }
    return hexString;
}

