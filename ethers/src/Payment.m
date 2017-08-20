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

#import "Payment.h"

#import "RegEx.h"


@implementation Payment

static RegEx *RegexNumbersOnly = nil;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RegexNumbersOnly = [RegEx regExWithPattern:@"^[0-9]*$"];
    });
}

+ (instancetype)paymentWithURI:(NSString *)uri {
    return [[Payment alloc] initWithURI:uri];
}

- (instancetype)initWithURI: (NSString*)uri {
    self = [super init];
    
    // Map some common "non-standard" URIs into the standard one
    NSArray *Schemes = @[@"ether:", @"ethereum:", @"eth:"];
    for (NSString *scheme in Schemes) {
        if ([[uri lowercaseString] hasPrefix:scheme]) {
            uri = [@"iban:" stringByAppendingString:[uri substringFromIndex:scheme.length]];
            break;
        }
    }
    
    // Make sure it looks like a URL (instead of a URI)
    if ([[uri lowercaseString] hasPrefix:@"iban:"] && ![[uri lowercaseString] hasPrefix:@"iban://"]) {
        uri = [@"iban://" stringByAppendingString:[uri substringFromIndex:5]];
    }
    
    // If it has no scheme, give it one
    if ([uri rangeOfString:@"://"].location == NSNotFound) {
        uri = [@"iban://" stringByAppendingString:uri];
    }
    
    NSURL *url = [NSURL URLWithString:uri];
    if (!url || ![[url.scheme lowercaseString] isEqualToString:@"iban"]) { return nil; }
    
    if (url.path && ![url.path isEqualToString:@""]) { return nil; }
    if (url.password || url.port || url.user) {return nil; }
    
    _address = [Address addressWithString:url.host];
    if (_address == nil) { return nil; }
    
    NSArray *comps = [url.query componentsSeparatedByString:@"&"];
    if (comps) {
        for (NSString *pair in comps) {
            NSArray *pairComps = [pair componentsSeparatedByString:@"="];
            if (pairComps.count != 2) { continue; }
            NSString *key = [[[pairComps firstObject] stringByRemovingPercentEncoding] lowercaseString];
            if ([key isEqualToString:@"amount"] || [key isEqualToString:@"value"]) {
                
                NSString *valueString = [[pairComps lastObject] stringByRemovingPercentEncoding];
                
                // We allow hexidecimal wei or decimal ether amounts
                BigNumber *value = nil;
                if ([valueString hasPrefix:@"0x"] && valueString.length > 2) {
                    value = [BigNumber bigNumberWithHexString:valueString];
                } else {
                    value = [Payment parseEther:valueString];
                }
                
                // Invalid number
                if (!value) { return nil; }
                
                // If there is already an amount/value specified, make sure they agree
                if (_amount && ![_amount isEqual:value]) {
                    return nil;
                }
                
                _amount = value;
            }
        }
    }
    
    return self;
}

+ (NSString*)formatEther: (BigNumber*)wei {
    return [Payment formatEther:wei options:0];
}

+ (NSString*)formatEther: (BigNumber*)wei options: (NSUInteger)options {
    if (!wei) { return nil; }
    
    NSString *weiString = [wei decimalString];
    
    BOOL negative = NO;
    if ([weiString hasPrefix:@"-"]) {
        negative = YES;
        weiString = [weiString substringFromIndex:1];
    }
    
    while (weiString.length < 19) {
        weiString = [@"0" stringByAppendingString:weiString];
    }
    
    NSUInteger decimalIndex = weiString.length - 18;
    NSString *whole = [weiString substringToIndex:decimalIndex];
    NSString *decimal = [weiString substringFromIndex:decimalIndex];
    
    if (options & EtherFormatOptionCommify) {
        NSString *commified = @"";
        //NSMutableArray *parts = [NSMutableArray arrayWithCapacity:(whole.length + 2) / 3];
        while (whole.length) {
            //NSLog(@"FOO: %@", whole);
            NSInteger chunkStart = whole.length - 3;
            if (chunkStart < 0) { chunkStart = 0; }
            commified = [NSString stringWithFormat:@"%@,%@", [whole substringFromIndex:chunkStart], commified];
            whole = [whole substringToIndex:chunkStart];
        }
        
        whole = [commified substringToIndex:commified.length - 1];
    }
    
    if (options & EtherFormatOptionApproximate) {
        decimal = [decimal substringToIndex:5];
    }
    
    // Trim trailing 0's
    while (decimal.length > 1 && [decimal hasSuffix:@"0"]) {
        decimal = [decimal substringToIndex:decimal.length - 1];
    }
    
    if (negative) {
        whole = [@"-" stringByAppendingString:whole];
    }
    
    return [NSString stringWithFormat:@"%@.%@", whole, decimal];
}

+ (BigNumber*)parseEther: (NSString*)etherString {
    if ([etherString isEqualToString:@"."]) { return nil; }
    
    BOOL negative = NO;
    if ([etherString hasPrefix:@"-"]) {
        negative = YES;
        etherString = [etherString substringFromIndex:1];
    }
    
    if (etherString.length == 0) { return nil; }
    
    NSArray *parts = [etherString componentsSeparatedByString:@"."];
    if ([parts count] > 2) { return nil; }
    
    NSString *whole = [parts objectAtIndex:0];
    if (whole.length == 0) { whole = @"0"; }
    if (![RegexNumbersOnly matchesExactly:whole]) { return nil; }
    
    NSString *decimal = ([parts count] > 1) ? [parts objectAtIndex:1]: @"0";
    if (!decimal || decimal.length == 0) { decimal = @"0"; }
    if (![RegexNumbersOnly matchesExactly:decimal]) { return nil; }
    
    if (decimal.length > 18) { return nil; }
    while (decimal.length < 18) { decimal = [decimal stringByAppendingString:@"0"]; }
    
    NSString *wei = [whole stringByAppendingString:decimal];
    if (negative) { wei = [@"-" stringByAppendingString:wei]; }
        
    return [BigNumber bigNumberWithDecimalString:wei];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<Payment address=%@ amount=%@ firm=%@>",
            _address, [Payment formatEther:_amount], (_firm ? @"Yes": @"No")];
}

@end
