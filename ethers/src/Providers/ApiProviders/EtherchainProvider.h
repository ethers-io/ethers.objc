/**
 *  We pretty much cannot use Etherchain in its current state... We need a custom JSON
 *  parser that will allow us to leave numbers as strings. Etherchain returns numbers
 *  instead of strings which will greatly overflow NSNumber. I also wonder if the server
 *  side is actually doing the right thing in these cases anyways...
 *
 *  Do NOT use this class!
 */

#import "ApiProvider.h"

@interface EtherchainProvider : ApiProvider

+ (Provider*)jsonRpcProviderWithChainId: (ChainId)chainId;

@end
