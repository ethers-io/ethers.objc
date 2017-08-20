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

#import "Address.h"

#import "BigNumber.h"
#import "RegEx.h"
#import "SecureData.h"


int ibanChecksum(NSString *address) {
    static BigNumber *constantNintySeven = nil;
    
    static NSString *ibanLookup[256];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        constantNintySeven = [BigNumber bigNumberWithInteger:97];
        
        for (int i = 0; i < 256; i++) {
            ibanLookup[i] = @"-";
        }
        
        for (int i = 0; i < 10; i++) {
            ibanLookup['0' + i] = [NSString stringWithFormat:@"%d", i];
        }
        for (int i = 0; i < 26; i++) {
            ibanLookup['A' + i] = [NSString stringWithFormat:@"%d", 10 + i];
        }
    });
    
    // See: https://en.wikipedia.org/wiki/International_Bank_Account_Number
    
    // Prepare the address
    address = [[[address uppercaseString] substringFromIndex:4] stringByAppendingString:@"XE00"];
    
    NSUInteger length = [address lengthOfBytesUsingEncoding:NSASCIIStringEncoding];
    const unsigned char* addressBytes = (const unsigned char*)[address cStringUsingEncoding:NSASCIIStringEncoding];
    
    // Expand the address
    NSMutableString *expandedString = [NSMutableString stringWithCapacity:length * 2 + 1];
    for (int i = 0; i < length; i++) {
        [expandedString appendString:ibanLookup[addressBytes[i]]];
    }
    
    // Compute the checksum
    NSUInteger checksum = [[[BigNumber bigNumberWithDecimalString:expandedString] mod:constantNintySeven] unsignedIntegerValue];
    return 98 - (int)checksum;
}


@implementation Address

static Address *ZeroAddress = nil;

static RegEx *HexAddressRegex = nil;
static RegEx *IcapAddressRegex = nil;
static RegEx *MixedCaseAddressRegex = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HexAddressRegex = [RegEx regExWithPattern:@"^(0x)?[0-9A-Fa-f]{40}$"];
        IcapAddressRegex = [RegEx regExWithPattern:@"^XE[0-9]{2}[0-9A-Za-z]{30,31}$"];
        MixedCaseAddressRegex = [RegEx regExWithPattern:@"^.*(([A-F].*[a-f])|([a-f].*[A-F])).*$"];

        unsigned char nullBytes[20];
        memset(nullBytes, 0, sizeof(nullBytes));
        ZeroAddress = [Address addressWithData:[NSData dataWithBytes:nullBytes length:sizeof(nullBytes)]];
    });
}

+ (NSString*)_checksumAddressData: (NSData*)addressData {
    if (addressData.length != 20) { return nil; }
    
    NSString *bareAddress = [[[SecureData dataToHexString:addressData] lowercaseString] substringFromIndex:2];
    const unsigned char *addressBytes = (const unsigned char*)[bareAddress cStringUsingEncoding:NSASCIIStringEncoding];
    
    // With the new SecureData, refactor this
    NSData *hashed = [SecureData KECCAK256:[[[SecureData dataToHexString:addressData] substringFromIndex:2] dataUsingEncoding:NSASCIIStringEncoding]];
    const unsigned char *hashedBytes = hashed.bytes;
    
    unsigned char bytes[43];
    bytes[0] = '0';
    bytes[1] = 'x';
    bytes[42] = 0;
    
    for (int i = 0; i < 40; i += 2) {
        bytes[i + 2] = addressBytes[i];
        bytes[i + 3] = addressBytes[i + 1];
        
        // Uppercase any bytes that have its corresponding byte >= 8 in the hash of the address
        if ((hashedBytes[i >> 1] >> 4) >= 8 && bytes[i + 2] >= 'a') {
            bytes[i + 2] -= 0x20;
        }
        if ((hashedBytes[i >> 1] & 0x0f) >= 8 && bytes[i + 3] >= 'a') {
            bytes[i + 3] -= 0x20;
        }
    }
    
    return [NSString stringWithCString:(const char*)bytes encoding:NSASCIIStringEncoding];
}


+ (NSString*)normalizeAddress:(NSString *)address {
    return [self normalizeAddress:address icap:NO];
}

+ (NSString*)normalizeAddress:(NSString *)address icap:(BOOL)icapFormat {
    if (!address) { return nil; }

    NSString *result = nil;
    
    if ([HexAddressRegex matchesExactly:address]) {
        
        // Add the 0x prefix if not present
        if (![address hasPrefix:@"0x"]) {
            address = [@"0x" stringByAppendingString:address];
        }
        
        // Compute the checksum address
        NSString *checksumAddress = [Address _checksumAddressData:[SecureData hexStringToData:address]];
        
        // If this address is checksummed, fail if the checksum if wrong
        if ([MixedCaseAddressRegex matchesExactly:address]) {
            if (![checksumAddress isEqualToString:address]) {
                return nil;
            }
        }
        
        result = checksumAddress;
        
    } else if ([IcapAddressRegex matchesExactly:address]) {
        
        int checksum = ibanChecksum(address);
        if ([[address substringWithRange:NSMakeRange(2, 2)] integerValue] != checksum) {
            return nil;
        }
        
        result = [[[BigNumber bigNumberWithBase36String:[address substringFromIndex:4]] hexString] substringFromIndex:2];
        while (result.length < 40) { result = [@"0" stringByAppendingString:result]; }
        result = [@"0x" stringByAppendingString:result];
        
        // Compute the checksummed address
        result = [Address _checksumAddressData:[SecureData hexStringToData:result]];
    }
    
    if (result && icapFormat) {
        NSString *icap = [[[BigNumber bigNumberWithHexString:result] base36String] uppercaseString];
        while (icap.length < 30) { icap = [@"0" stringByAppendingString:icap]; }
        result = [NSString stringWithFormat:@"XE%02d%@", ibanChecksum([@"XE00" stringByAppendingString:icap]), icap];
    }
    
    return result;;
}


#pragma mark - Life-Cycle

- (instancetype)initWithString: (NSString*)addressString {
    self = [super init];
    if (self) {
        _checksumAddress = [Address normalizeAddress:addressString icap:NO];
        if (!_checksumAddress) { return nil; }
    }
    return self;
}

+ (instancetype)addressWithString:(NSString *)addressString {
    return [[Address alloc] initWithString:addressString];
}

+ (instancetype)addressWithData:(NSData *)addressData {
    if (addressData.length != 20) { return nil; }
    return [[Address alloc] initWithString:[SecureData dataToHexString:addressData]];
}

+ (Address*)zeroAddress {
    return ZeroAddress;
}

- (NSString*)icapAddress {
    return [Address normalizeAddress:_checksumAddress icap:YES];
}

- (BOOL)isZeroAddress {
    return [self isEqualToAddress:ZeroAddress];
}

- (NSData*)data {
    return [SecureData hexStringToData:_checksumAddress];
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}


#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSString *address = [aDecoder decodeObjectForKey:@"address"];
    return [self initWithString:address];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_checksumAddress forKey:@"address"];
}


#pragma mark - NSObject

- (NSUInteger)hash {
    return [_checksumAddress hash];
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Address class]]) { return NO; }
    return [_checksumAddress isEqualToString:((Address*)object).checksumAddress];
}

- (BOOL)isEqualToAddress:(Address*)address {
    return [self isEqual:address];
}

- (NSString*)description {
    return _checksumAddress;
}

@end
