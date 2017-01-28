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

#import "Account.h"

#include "crypto_scrypt.h"

#include "aes.h"
#include "bip32.h"
#include "bip39.h"
#include "curves.h"
#include "ecdsa.h"
#include "secp256k1.h"

#import "BigNumber.h"
#import "NSData+Secure.h"
#import "NSMutableData+Secure.h"
#import "NSString+Secure.h"
#import "RegEx.h"

static NSErrorDomain ErrorDomain = @"io.ethers.AccountError";

NSObject *getPath(NSObject *object, NSString *path, Class expectedClass) {
    
    for (NSString *component in [[path lowercaseString] componentsSeparatedByString:@"/"]) {
        if (![object isKindOfClass:[NSDictionary class]]) { return nil; }
        
        BOOL found = NO;
        for (NSString *childKey in [(NSDictionary*)object allKeys]) {
            if ([component isEqualToString:[childKey lowercaseString]]) {
                found = YES;
                object = [(NSDictionary*)object objectForKey:childKey];
                break;
            }
        }
        if (!found) { return nil; }
    }
    
    if (![object isKindOfClass:expectedClass]) {
        return nil;
    }
    
    return object;
}

NSData *getHexData(NSString *unprefixedHexString) {
    if (![unprefixedHexString hasPrefix:@"0x"]) {
        unprefixedHexString = [@"0x" stringByAppendingString:unprefixedHexString];
    }
    return [unprefixedHexString dataUsingHexEncoding];
}

NSData *ensureDataLength(NSString *hexString, NSUInteger length) {
    if (![hexString isKindOfClass:[NSString class]]) { return nil; }
    NSData *data = [[@"0x" stringByAppendingString:hexString] dataUsingHexEncoding];
    if ([data length] != length) { return nil; }
    return data;
}


#pragma mark -
#pragma mark - Cancellable

@interface Cancellable ()

@end


@implementation Cancellable {
    BOOL _cancelled;
    void (^_cancelCallback)();
}

- (instancetype)initWithCancelCallback: (void (^)())cancelCallback {
    self = [super init];
    if (self) {
        _cancelCallback = cancelCallback;
    }
    return self;
}

- (void)cancel {
    if (!_cancelled && _cancelCallback) {
        _cancelled = YES;
        _cancelCallback();
    }
}

@end



#pragma mark -
#pragma mark - Signature

@implementation Signature

- (instancetype)initWithData: (NSData*)data recoveryParam: (char)recoveryParam {
    self = [super init];
    if (self) {
        _r = [data subdataWithRange:NSMakeRange(0, 32)];
        _s = [data subdataWithRange:NSMakeRange(32, 32)];
        _v = recoveryParam;
    }
    return self;
}

@end



#pragma mark -
#pragma mark - Account

static NSMutableSet *Wordlist = nil;


@implementation Account {
    NSData *_privateKey;
}

#pragma mark - Life-Cycle

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Wordlist = [NSMutableSet setWithCapacity:2048];
        const char* const *wordlist = mnemonic_wordlist();
        int i = 0;
        while (YES) {
            const char *word = wordlist[i++];
            if (!word) { break; }
            [Wordlist addObject:[NSString stringWithUTF8String:word]];
        }
        
        NSLog(@"BIP39 World List: %d words", (int)Wordlist.count);
    });
}

- (instancetype)initWithPrivateKey:(NSData *)privateKey {
    if (privateKey.length != 32) { return nil; }

    self = [super init];
    if (self) {
        _privateKey = [NSMutableData secureDataWithData:privateKey];;
        
        NSMutableData *publicKey = [NSMutableData secureDataWithLength:65];
        ecdsa_get_public_key65(&secp256k1, [_privateKey bytes], [publicKey mutableBytes]);
        NSData *addressData = [[[publicKey subdataWithRange:NSMakeRange(1, 64)] KECCAK256] subdataWithRange:NSMakeRange(12, 20)];
        _address = [Address addressWithData:addressData];
    }
    return self;
}

- (instancetype)initWithMnemonicPhrase: (NSString*)mnemonicPhrase {
    const char* phraseStr = [mnemonicPhrase cStringUsingEncoding:NSUTF8StringEncoding];
    if (!mnemonic_check(phraseStr)) { return nil; }
    
    NSMutableData *seed = [NSMutableData secureDataWithLength:(512 / 8)];
    mnemonic_to_seed(phraseStr, "", [seed mutableBytes], NULL);
    
    HDNode node;
    hdnode_from_seed([seed bytes], (int)[seed length], SECP256K1_NAME, &node);
    
    hdnode_private_ckd(&node, (0x80000000 | (44)));   // 44' - BIP 44 (purpose field)
    hdnode_private_ckd(&node, (0x80000000 | (60)));   // 60' - Ethereum (see SLIP 44)
    hdnode_private_ckd(&node, (0x80000000 | (0)));    // 0'  - Account 0
    hdnode_private_ckd(&node, 0);                     // 0   - External
    hdnode_private_ckd(&node, 0);                     // 0   - Slot #0
    
    NSMutableData *privateKey = [NSMutableData secureDataWithLength:32];
    memcpy([privateKey mutableBytes], node.private_key, 32);

    self = [self initWithPrivateKey:privateKey];
    if (self) {
        _mnemonicPhrase = mnemonicPhrase;
        
        NSMutableData *fullData = [NSMutableData secureDataWithLength:MAXIMUM_BIP39_DATA_LENGTH];
        int length = data_from_mnemonic([_mnemonicPhrase cStringUsingEncoding:NSUTF8StringEncoding], [fullData mutableBytes]);
        
        _mnemonicData = [NSMutableData secureDataWithCapacity:length];
        [(NSMutableData*)_mnemonicData appendBytes:[fullData bytes] length:length];
    }

    // Wipe the node
    memset(&node, 0, sizeof(node));

    return self;
}

+ (instancetype)accountWithPrivateKey:(NSData *)privateKey {
    return [[Account alloc] initWithPrivateKey:privateKey];
}

+ (instancetype)accountWithMnemonicPhrase: (NSString*)phrase {
    return [[Account alloc] initWithMnemonicPhrase:phrase];
}

+ (instancetype)accountWithMnemonicData: (NSData*)data {
    const char* phrase = mnemonic_from_data([data bytes], (int)[data length]);
    return [[Account alloc] initWithMnemonicPhrase:[NSString stringWithCString:phrase encoding:NSUTF8StringEncoding]];
}

+ (instancetype)randomMnemonicAccount {
    const char* phrase = mnemonic_generate(128);
    return [[Account alloc] initWithMnemonicPhrase:[NSString stringWithCString:phrase encoding:NSUTF8StringEncoding]];
}

- (NSString*)_privateKeyHash {
    return [[_privateKey KECCAK256] hexEncodedString];
}


#pragma mark - Crowdsale

// See: https://github.com/ethereum/pyethsaletool

+ (BOOL)isCrowdsaleJSON: (NSString*)json {
    return NO;
}

+ (instancetype)decryptCrowdsaleJSON: (NSString*)json password: (NSString*)password {
    return nil;
}


#pragma mark - Secret Storage

// See: https://github.com/ethereum/wiki/wiki/Web3-Secret-Storage-Definition
+ (Cancellable*)decryptSecretStorageJSON:(NSString *)json password:(NSString *)password callback:(void (^)(Account *, NSError *))callback {
    
    void (^sendError)(NSInteger, NSString*) = ^(NSInteger errorCode, NSString *reason) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            callback(nil, [NSError errorWithDomain:ErrorDomain code:errorCode userInfo:@{@"reason": reason}]);
        });
    };
    
    NSError *error = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    
    if (error) {
        sendError(kAccountErrorJSONInvalid, [error description]);
        return nil;
    }
    
    int version = [(NSNumber*)getPath(data, @"version", [NSNumber class]) intValue];
    if (version != 3) {
        sendError(kAccountErrorJSONUnsupportedVersion, [NSString stringWithFormat:@"version(%d) != 3", version]);
        return nil;
    }
    
    Address *expectedAddress = [Address addressWithString:(NSString*)getPath(data, @"address", [NSString class])];
    if (!expectedAddress) {
        sendError(kAccountErrorJSONInvalidParameter, [NSString stringWithFormat:@"invalidAddress(%@)", expectedAddress]);
        return nil;
    }
    
    NSString *kdf = (NSString*)getPath(data, @"crypto/kdf", [NSString class]);
    NSData *salt = getHexData((NSString*)getPath(data, @"crypto/kdfparams/salt", [NSString class]));
    int n = [(NSNumber*)getPath(data, @"crypto/kdfparams/n", [NSNumber class]) intValue];
    int p = [(NSNumber*)getPath(data, @"crypto/kdfparams/p", [NSNumber class]) intValue];
    int r = [(NSNumber*)getPath(data, @"crypto/kdfparams/r", [NSNumber class]) intValue];
    int dkLen = [(NSNumber*)getPath(data, @"crypto/kdfparams/dklen", [NSNumber class]) intValue];
    if (![kdf isEqualToString:@"scrypt"] || salt.length == 0 || !n || !p || !r || dkLen != 32) {
        sendError(kAccountErrorJSONUnsupportedKeyDerivationFunction, @"Invalid KDF parameters");
        return nil;
    }

    NSString *cipher = (NSString*)getPath(data, @"crypto/cipher", [NSString class]);
    NSData *iv = getHexData((NSString*)getPath(data, @"crypto/cipherparams/iv", [NSString class]));
    NSData *cipherText = getHexData((NSString*)getPath(data, @"crypto/ciphertext", [NSString class]));
    if (![cipher isEqualToString:@"aes-128-ctr"] || iv.length != 16 || cipherText.length != 32) {
        sendError(kAccountErrorJSONUnsupportedCipher, @"Invalid cipher parameters");
        return nil;
    }
    
    NSData *mac = getHexData((NSString*)getPath(data, @"crypto/mac", [NSString class]));
    if (mac.length != 32) {
        sendError(kAccountErrorJSONInvalidParameter, [NSString stringWithFormat:@"Bad MAC length (%d)", (int)(mac.length)]);
        return nil;
    }

    // Convert password to NFKC form
    NSData *passwordData = [[password precomposedStringWithCompatibilityMapping] dataUsingEncoding:NSUTF8StringEncoding];
    const uint8_t *passwordBytes = [passwordData bytes];

    __block char stop = 0;
    
    Cancellable *cancellable = [[Cancellable alloc] initWithCancelCallback:^() {
        stop = 1;
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^() {
        // Get the key to encrypt with from the password and salt
        NSMutableData *derivedKey = [NSMutableData secureDataWithLength:64];
        int status = crypto_scrypt(passwordBytes, (int)passwordData.length, salt.bytes, salt.length, n, r, p, derivedKey.mutableBytes, derivedKey.length, &stop);
        
        // Bad scrypt parameters
        if (status) {
            if (status == -2) {
                sendError(kAccountErrorCancelled, @"Cancelled");
                return;
            }
            NSString *reason = [NSString stringWithFormat:@"Invalid scrypt parameter (salt=%@, N=%d, r=%d, p=%d, dekLen=%d)",
                                salt, n, r, p, (int)derivedKey.length];
            sendError(kAccountErrorJSONInvalidParameter, reason);
            return;
        }
        
        // Check the MAC
        {
            NSMutableData *macCheck = [NSMutableData secureDataWithCapacity:(16 + 32)];
            [macCheck appendData:[derivedKey subdataWithRange:NSMakeRange(16, 16)]];
            [macCheck appendData:cipherText];
            
            if (![[macCheck KECCAK256] isEqualToData:mac]) {
                sendError(kAccountErrorWrongPassword, @"Wrong Password");
                return;
            }
        }

        NSMutableData *privateKey = [NSMutableData secureDataWithLength:32];

        {
            NSData *encryptionKey = [derivedKey subdataWithRange:NSMakeRange(0, 16)];
            unsigned char counter[16];
            [iv getBytes:counter length:iv.length];
            
            // CTR uses encrypt to decrypt
            aes_encrypt_ctx context;
            aes_encrypt_key128(encryptionKey.bytes, &context);
            
            AES_RETURN aesStatus = aes_ctr_decrypt(cipherText.bytes,
                                                   privateKey.mutableBytes,
                                                   (int)privateKey.length,
                                                   counter,
                                                   &aes_ctr_cbuf_inc,
                                                   &context);
            
            if (aesStatus != EXIT_SUCCESS) {
                sendError(kAccountErrorUnknownError, @"AES Error");
                return;
            }
        }
        
        Account *account = [[Account alloc] initWithPrivateKey:privateKey];
        
        if (![account.address isEqualToAddress:expectedAddress]) {
            sendError(kAccountErrorJSONInvalidParameter, @"Address mismatch");
            return;
        }
        
        // Check for an mnemonic phrase
        NSDictionary *ethersData = [data objectForKey:@"ethers"];
        if ([ethersData isKindOfClass:[NSDictionary class]] && [[ethersData objectForKey:@"version"] isEqual:@"0.1"]) {
            
            NSData *mnemonicCounter = ensureDataLength([ethersData objectForKey:@"mnemonicCounter"], 16);
            NSData *mnemonicCiphertext = ensureDataLength([ethersData objectForKey:@"mnemonicCiphertext"], 16);
            if (mnemonicCounter && mnemonicCiphertext) {

                NSMutableData *mnemonicData = [NSMutableData secureDataWithLength:[mnemonicCiphertext length]];
                
                unsigned char counter[16];
                [mnemonicCounter getBytes:counter length:mnemonicCounter.length];
                
                aes_encrypt_ctx context;
                aes_encrypt_key256([derivedKey subdataWithRange:NSMakeRange(32, 32)].bytes, &context);
                
                AES_RETURN aesStatus = aes_ctr_decrypt([mnemonicCiphertext bytes],
                                                       [mnemonicData mutableBytes],
                                                       (int)mnemonicData.length,
                                                       counter,
                                                       &aes_ctr_cbuf_inc,
                                                       &context);
                
                if (aesStatus != EXIT_SUCCESS) {
                    sendError(kAccountErrorUnknownError, @"AES Error");
                    return;
                }
                
                Account *mnemonicAccount = [Account accountWithMnemonicData:mnemonicData];
                if (![mnemonicAccount.address isEqualToAddress:account.address]) {
                    sendError(kAccountErrorMnemonicMismatch, @"Mnemonic Mismatch");
                    return;
                }
                
                account = mnemonicAccount;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            callback(account, nil);
        });
    });
    
    return cancellable;
}

- (Cancellable*)encryptSecretStorageJSON:(NSString *)password callback:(void (^)(NSString *))callback {
    
    void (^sendResult)(NSString*) = ^(NSString *result) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            callback(result);
        });
    };

    
    // Convert password to NFKC form
    NSData *passwordData = [[password precomposedStringWithCompatibilityMapping] dataUsingEncoding:NSUTF8StringEncoding];
    const uint8_t *passwordBytes = [passwordData bytes];

    NSUUID *uuid = [NSUUID UUID];
    
    NSMutableData *iv = [NSMutableData secureDataWithLength:16];;
    {
        int failure = SecRandomCopyBytes(kSecRandomDefault, (int)iv.length, [iv mutableBytes]);
        if (failure) {
            sendResult(nil);
            return nil;
        }
    }

    NSMutableData *salt = [NSMutableData secureDataWithLength:32];;
    {
        int failure = SecRandomCopyBytes(kSecRandomDefault, (int)salt.length, [salt mutableBytes]);
        if (failure) {
            sendResult(nil);
            return nil;
        }
    }

    int r = 8, p = 1, n = 262144;
    
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    
    [json setObject:[[self.address.checksumAddress substringFromIndex:2] lowercaseString] forKey:@"address"];
    [json setObject:[uuid UUIDString] forKey:@"id"];
    [json setObject:@(3) forKey:@"version"];
    
    NSMutableDictionary *ethers = [NSMutableDictionary dictionary];
    [json setObject:ethers forKey:@"ethers"];
    
    NSMutableDictionary *crypto = [NSMutableDictionary dictionary];
    [json setObject:crypto forKey:@"Crypto"];

    [crypto setObject:@{
                        @"p": @(p),
                        @"r": @(r),
                        @"n": @(n),
                        @"dklen": @([salt length]),
                        @"salt": [[salt hexEncodedString] substringFromIndex:2],
                        }
               forKey:@"kdfparams"];
    [crypto setObject:@"scrypt" forKey:@"kdf"];
    
    [crypto setObject:@{
                        @"iv": [[iv hexEncodedString] substringFromIndex:2],
                        }
               forKey:@"cipherparams"];
    [crypto setObject:@"aes-128-ctr" forKey:@"cipher"];
    
    // Set ethers parameters
    [ethers setObject:@"UTC--YYYY-mm-ddTHH-MM-SS.0Z--address" forKey:@"gethFilename"];
    [ethers setObject:@"ethers/iOS" forKey:@"client"];
    [ethers setObject:@"0.1" forKey:@"version"];

    __block char stop = 0;
    
    Cancellable *cancellable = [[Cancellable alloc] initWithCancelCallback:^() {
        stop = 1;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^() {
        
        // Get the key to encrypt with from the password and salt
        NSMutableData *derivedKey = [NSMutableData secureDataWithLength:64];
        int status = crypto_scrypt(passwordBytes, (int)passwordData.length, salt.bytes, salt.length, n, r, p, derivedKey.mutableBytes, derivedKey.length, &stop);
        
        // Bad scrypt parameters
        if (status) {
            sendResult(nil);
            return;
        }
        
        NSMutableData *cipherText = [NSMutableData secureDataWithLength:32];
        {
            unsigned char counter[16];
            [iv getBytes:counter length:iv.length];

            NSData *encryptionKey = [derivedKey subdataWithRange:NSMakeRange(0, 16)];
            
            aes_encrypt_ctx context;
            aes_encrypt_key128(encryptionKey.bytes, &context);
            
            AES_RETURN aesStatus = aes_ctr_encrypt([_privateKey bytes],
                                                   [cipherText mutableBytes],
                                                   (int)_privateKey.length,
                                                   counter,
                                                   &aes_ctr_cbuf_inc,
                                                   &context);
            
            if (aesStatus != EXIT_SUCCESS) {
                sendResult(nil);
                return;
            }
        }
        
        [crypto setObject:[[cipherText hexEncodedString] substringFromIndex:2] forKey:@"ciphertext"];

        if (_mnemonicData) {
            NSMutableData *mnemonicCounter = [NSMutableData secureDataWithLength:16];;
            {
                int failure = SecRandomCopyBytes(kSecRandomDefault, (int)mnemonicCounter.length, [mnemonicCounter mutableBytes]);
                if (failure) {
                    sendResult(nil);
                    return;
                }
            }

            NSMutableData *mnemonicCiphertext = [NSMutableData secureDataWithLength:[_mnemonicData length]];
            
            // We are using a different key, so it is safe to use the same IV
            unsigned char counter[16];
            [mnemonicCounter getBytes:counter length:mnemonicCounter.length];
            
            aes_encrypt_ctx context;
            aes_encrypt_key256([derivedKey subdataWithRange:NSMakeRange(32, 32)].bytes, &context);
            
            AES_RETURN aesStatus = aes_ctr_encrypt([_mnemonicData bytes],
                                                   [mnemonicCiphertext mutableBytes],
                                                   (int)_mnemonicData.length,
                                                   counter,
                                                   &aes_ctr_cbuf_inc,
                                                   &context);
            
            if (aesStatus != EXIT_SUCCESS) {
                sendResult(nil);
                return;
            }
            
            [ethers setObject:[[mnemonicCounter hexEncodedString] substringFromIndex:2] forKey:@"mnemonicCounter"];
            [ethers setObject:[[mnemonicCiphertext hexEncodedString] substringFromIndex:2] forKey:@"mnemonicCiphertext"];
        }

        
        // Compute the MAC
        {
            NSMutableData *macCheck = [NSMutableData secureDataWithCapacity:(16 + 32)];
            [macCheck appendData:[derivedKey subdataWithRange:NSMakeRange(16, 16)]];
            [macCheck appendData:cipherText];
            [crypto setObject:[[[macCheck KECCAK256] hexEncodedString] substringFromIndex:2] forKey:@"mac"];
        }
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
        if (error) {
            NSLog(@"Error: %@", error);
            sendResult(nil);
            return;
        }
        
        
        sendResult([[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    });

    return cancellable;
}

#pragma mark - Signing

- (Signature*)signDigest:(NSData *)digestData {
    if (digestData.length != 32) { return nil; }
    
    NSMutableData *signatureData = [NSMutableData secureDataWithLength:64];;
    uint8_t pby;
    ecdsa_sign_digest(&secp256k1, [_privateKey bytes], [digestData bytes], [signatureData mutableBytes], &pby, NULL);
    return [[Signature alloc] initWithData:signatureData recoveryParam:pby];
}

#pragma mark - Mnemonic Helpers

+ (BOOL)isValidMnemonicPhrase:(NSString *)phrase {
    return (mnemonic_check([phrase cStringUsingEncoding:NSUTF8StringEncoding]));
}

+ (BOOL)isValidMnemonicWord:(NSString *)word {
    word = [word lowercaseString];
    return ([Wordlist containsObject:word]);
}


#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[Account class]]) { return NO; }
    return [[self _privateKeyHash] isEqualToString:[((Account*)object) _privateKeyHash]];
}

- (NSUInteger)hash {
    return [_address hash];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<Account address=%@>", self.address];
}
@end
