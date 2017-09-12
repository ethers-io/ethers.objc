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

#import "InfuraProvider.h"

@implementation InfuraProvider

- (instancetype)initWithChainId:(ChainId)chainId {
    return [self initWithChainId:chainId accessToken:nil];
}

- (instancetype)initWithChainId:(ChainId)chainId accessToken:(NSString *)accessToken {
    
    NSString *host = nil;
    switch (chainId) {
        case ChainIdHomestead:
            host = @"mainnet.infura.io";
            break;
        case ChainIdKovan:
            host = @"kovan.infura.io";
            break;
        case ChainIdRinkeby:
            host = @"rinkeby.infura.io";
            break;
        case ChainIdRopsten:
            host = @"ropsten.infura.io";
            break;
        default:
            break;
    }
    
    // Any other host is not supported
    if (!host) { return nil; }
    
    NSString *accessTokenValue = accessToken;
    if (!accessToken) { accessTokenValue = @""; }
    
    NSString *url = [NSString stringWithFormat:@"https://%@/%@", host, accessTokenValue];
    
    self = [super initWithChainId:chainId url:[NSURL URLWithString:url]];
    if (self) {
        _accessToken = accessToken;
    }
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<InfuraProvider chainId=%d accessToken=%@>", self.chainId, _accessToken];
}

@end
