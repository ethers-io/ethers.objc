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

#import "RegEx.h"

@implementation RegEx {
    NSRegularExpression *_regex;
}

- (instancetype)initWithPattern: (NSString*)pattern {
    self = [super init];
    if (self) {
        NSError *error = nil;
        _regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        if (error) {
            NSLog(@"RegEx: Error creating pattern /%@/ - %@", pattern, error);
            return nil;
        }
    }
    return self;
}

+ (instancetype)regExWithPattern:(NSString *)pattern {
    return [[RegEx alloc] initWithPattern:pattern];
}

- (BOOL)matchesAny:(NSString *)string {
    NSRange range = [_regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    return (range.location != NSNotFound);
}

- (BOOL)matchesExactly: (NSString*)string {
    NSRange range = [_regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    return (range.location == 0 && range.length == string.length);
}

@end
