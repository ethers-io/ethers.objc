//
//  Utilities.m
//  ethers
//
//  Created by Richard Moore on 2017-02-01.
//  Copyright © 2017 Ethers. All rights reserved.
//

#import "Utilities.h"

NSData *convertIntegerToData(NSUInteger value) {
    unsigned char bytes[sizeof(NSUInteger)];
    int offset = sizeof(bytes);
    
    while (value) {
        bytes[--offset] = (value & 0xff);
        value >>= 8;
    }
    
    return [NSData dataWithBytes:&bytes[offset] length:(sizeof(bytes) - offset)];
}
