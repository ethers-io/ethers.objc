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

#import <Foundation/Foundation.h>

#import "Address.h"
#import "BigNumber.h"

typedef NS_OPTIONS(NSUInteger, EtherFormatOption) {
    EtherFormatOptionNone         = 0,
    EtherFormatOptionCommify      = (1 << 0),
    EtherFormatOptionApproximate  = (1 << 1)
};



@interface Payment : NSObject

+ (instancetype)paymentWithURI: (NSString*)uri;

@property (nonatomic, strong) Address *address;
@property (nonatomic, strong) BigNumber *amount;
@property (nonatomic, assign) BOOL firm;


+ (NSString*)formatEther: (BigNumber*)wei;
+ (NSString*)formatEther: (BigNumber*)wei options: (NSUInteger)options;

+ (BigNumber*)parseEther: (NSString*)etherString;

@end
