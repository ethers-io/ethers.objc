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

#import "LightClientProvider.h"

@import Geth;


GoGethAddress *getAddress(Address *address) {
    NSError *error = nil;
    GoGethAddress *result = GoGethNewAddressFromHex([[address checksumAddress] substringFromIndex:0], &error);
    if (error) {
        NSLog(@"Failed Address: %@", error);
        return nil;
    }
    
    return result;
}

void sigPipe(int input) {
    NSLog(@"Handled: %d", input);
}

@interface Provider (private)

@property (nonatomic, assign) int blockNumber;
@property (nonatomic, strong) BigNumber *gasPrice;

@end


@interface LightClientProvider () {
    GoGethNode *_node;
}

//@property (nonatomic, readonly) GoGethEthereumClient *client;

@end


@implementation LightClientProvider

- (instancetype)initWithTestnet:(BOOL)testnet {
    testnet = YES;
    
    self = [super initWithTestnet:testnet];
    if (self) {

        signal(SIGPIPE, sigPipe);
        
        NSString *dataDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        if (testnet) {
            dataDir = [dataDir stringByAppendingPathComponent:@"geth-testnet"];
        } else {
            dataDir = [dataDir stringByAppendingPathComponent:@"geth-mainnet"];
        }
        NSLog(@"datadir: %@", dataDir);

        GoGethNodeConfig *config = GoGethNewNodeConfig();
        if (testnet) {
            GoGethEnodes *bootstrapNodes = GoGethNewEnodesEmpty();
            
            NSArray *enodes = @[
                              @"enode://e4533109cc9bd7604e4ff6c095f7a1d807e15b38e9bfeb05d3b7c423ba86af0a9e89abbf40bd9dde4250fef114cd09270fa4e224cbeef8b7bf05a51e8260d6b8@94.242.229.4:40404",
                              @"enode://8c336ee6f03e99613ad21274f269479bf4413fb294d697ef15ab897598afb931f56beb8e97af530aee20ce2bcba5776f4a312bc168545de4d43736992c814592@94.242.229.203:30303",
                              ];
            
            for (NSString *enode in enodes) {
                NSError *error = nil;
                GoGethEnode *node = GoGethNewEnode(enode, &error);
            
                if (error) {
                    NSLog(@"E: %@", error);
                } else {
                    [bootstrapNodes append:node];
                }
            }
            
            [config setEthereumEnabled:YES];
//            [config setMaxPeers:25];
            [config setBootstrapNodes:GoGethFoundationBootnodes()];
            [config setEthereumChainConfig:GoGethTestnetChainConfig()];
            [config setEthereumGenesis:GoGethTestnetGenesis()];
        }

        {
            NSError *error = nil;
            _node = GoGethNewNode(dataDir, config, &error);
            NSLog(@"Node: %@ %@", _node, error);
        }
        
        {
            NSError *error = nil;
            [_node start:&error];
            
            if (error) {
                NSLog(@"Error1: %@", error);
            
            } else {
                NSLog(@"SSS");
            }
        }
        
        {
            NSError *error = nil;
//            _client = [_node getEthereumClient:&error];
            
            if (error) {
                NSLog(@"Error2: %@", error);
            }
        }
        
        
        [NSTimer scheduledTimerWithTimeInterval:4.0f repeats:YES block:^(NSTimer *timer) {
            NSLog(@"Getting Balance...");
            GoGethAddress *address = getAddress([Address addressWithString:@"0x0b7FC9DDF70576F6330669EaAA71B6a831e99528"]);
            NSLog(@"Address: %@", [address getHex]);
                if (address) {
                    NSError *error = nil;
                    GoGethEthereumClient *_client = GoGethNewEthereumClient(@"https://mainnet.infura.io/COXgE55j1G38qJX36eyV ", &error);
                    //[_node getEthereumClient:&error];
                    
                    NSLog(@"Client: %@ %@", _client, error);
                    
                    error = nil;
                    GoGethSyncProgress *syncProgress = [_client syncProgress:[GoGethNewContext() withTimeout:10000000000]
                                                                       error:&error];
                    NSLog(@"SyncProgress: %d %d %d %d %d %@", (int)[syncProgress getCurrentBlock],
                          (int)[syncProgress getHighestBlock], (int)[syncProgress getKnownStates], (int)[syncProgress getPulledStates], (int)[syncProgress getStartingBlock], error);
                    
                    GoGethPeerInfos *peers = [_node getPeersInfo];
                    for (int i = 0; i < [peers size]; i++) {
                        error = nil;
                        GoGethPeerInfo *peer = [peers get:i error:&error];
                        NSLog(@"Peer: %@ %@", [peer getRemoteAddress], error);
                    }
                    
                    error = nil;
                    GoGethBigInt *balance = [_client getBalanceAt:[GoGethNewContext() withTimeout:10000000000]
                                                          account:address
                                                           number:-1
                                                            error:&error];
                    NSLog(@"Balance: %@ %@", balance, error);
                    if (balance) {
                        BigNumber *value = [BigNumber bigNumberWithDecimalString:[balance getString:10]];
                        NSLog(@"BB: %@", value);
                    }
                    
                } else {
                    NSLog(@"Bad address");
                }
        }];
    }
    return self;
}

//- (GoGethEthereumClient*)client {
//    NSError *error = nil;
//    GoGethEthereumClient *_client = [_node getEthereumClient:&error];
//    if (error) {
//        NSLog(@"EE: %@", error);
//        return nil;
//    }
//    return client;
//}

@end
