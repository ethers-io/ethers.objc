//
//  NSString+Bitcoin.m
//  BreadWallet
//
//  Created by Aaron Voisine on 5/13/13.
//  Copyright (c) 2013 Aaron Voisine <voisine@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NSString+Secure.h"

#import "ccMemory.h"
#import "NSMutableData+Secure.h"


@implementation NSString (Secure)


/*
+ (NSString *)hexWithData:(NSData *)d
{
    if (!d) { return nil; }
    
    const uint8_t *bytes = d.bytes;
    
    NSMutableString *hex = CFBridgingRelease(CFStringCreateMutable(SecureAllocator(), d.length * 2 + 2));
    [hex appendString:@"0x"];
    
    for (NSUInteger i = 0; i < d.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    
    return hex;
}
*/


- (NSData *)dataUsingHexEncoding
{
    static NSRegularExpression *hexStringRegex = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        hexStringRegex = [[NSRegularExpression alloc] initWithPattern:@"^0x([0-9A-Fa-f][0-9A-Fa-f])*$" options:0 error:&error];
        if (error) {
            NSLog(@"Error Compiling Regular Expression");
        }
    });

    // Make sure we are a valid hex string
    if ([hexStringRegex matchesInString:self options:0 range:NSMakeRange(0, self.length)].count != 1) {
        return nil;
    }
    
    NSMutableData *d = [NSMutableData secureDataWithCapacity:self.length / 2];
    uint8_t b = 0;
    
    for (NSUInteger i = 2; i < self.length; i++) {
        unichar c = [self characterAtIndex:i];
        
        switch (c) {
            case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
                b += c - '0';
                break;

            case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
                b += c + 10 - 'A';
                break;

            case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
                b += c + 10 - 'a';
                break;

            default:
                // Cannot happen as we passed the above regular expression
                NSLog(@"This should not happen!");
                return d;
        }
        
        CC_XZEROMEM(&c, sizeof(c));
        
        if (i % 2) {
            [d appendBytes:&b length:1];
            CC_XZEROMEM(&b, sizeof(b));
        } else {
            b <<= 4;
        }
    }
    
    return d;
}

@end
