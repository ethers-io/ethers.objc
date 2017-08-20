//
//  Utilities.h
//  ethers
//
//  Created by Richard Moore on 2017-02-01.
//  Copyright © 2017 Ethers. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Hash.h"

extern NSData* convertIntegerToData(NSUInteger value);

extern Hash* namehash(NSString *name);

extern NSString *stripHexZeros(NSString *hexString);
