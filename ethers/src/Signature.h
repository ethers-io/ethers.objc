//
//  Signature.h
//  ethers
//
//  Created by Richard Moore on 2017-01-31.
//  Copyright © 2017 Ethers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Signature: NSObject <NSCoding, NSCopying>

@property (nonatomic, readonly) NSData* r;
@property (nonatomic, readonly) NSData* s;
@property (nonatomic, readonly) char v;

@end
