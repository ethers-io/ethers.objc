//
//  Signature.m
//  ethers
//
//  Created by Richard Moore on 2017-01-31.
//  Copyright © 2017 Ethers. All rights reserved.
//

#import "NSData+Secure.h"
#import "Signature.h"

@implementation Signature

- (instancetype)initWithR: (NSData*)r s: (NSData*)s v: (char)v {
    if (r.length != 32 || s.length != 32) { return nil; }
    self = [super init];
    if (self) {
        _r = r;
        _s = s;
        _v = v;
    }
    return self;
}

- (instancetype)initWithData: (NSData*)data v: (char)v {
    if (data.length != 64) { return nil; }
    
    return [self initWithR:[data subdataWithRange:NSMakeRange(0, 32)]
                         s:[data subdataWithRange:NSMakeRange(32, 32)]
                         v:v];
}

+ (instancetype)signatureWithData: (NSData*)data v:(char)v {
    return [[Signature alloc] initWithData:data v:v];
}


#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithR:[aDecoder decodeObjectForKey:@"r"]
                         s:[aDecoder decodeObjectForKey:@"s"]
                         v:[aDecoder decodeIntForKey:@"v"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_r forKey:@"r"];
    [aCoder encodeObject:_s forKey:@"s"];
    [aCoder encodeInt:_v forKey:@"v"];
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}


#pragma mark - NSObject

- (NSUInteger)hash {
    return [_r hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Signature class]]) { return NO; }
    return [_r isEqual:((Signature*)object).r] && [_s isEqual:((Signature*)object).s] && _v == ((Signature*)object).v;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<Signature r=%@ s=%@ v=%c>", [_r hexEncodedString], [_s hexEncodedString], _v];
}

@end
