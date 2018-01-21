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
#import "SecureData.h"

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
    return [SecureData hexStringToData:unprefixedHexString];
}

NSData *ensureDataLength(NSString *hexString, NSUInteger length) {
    if (![hexString isKindOfClass:[NSString class]]) { return nil; }
    NSData *data = [SecureData hexStringToData:[@"0x" stringByAppendingString:hexString]];
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

@interface Signature (private)

+ (instancetype)signatureWithData: (NSData*)data v: (char)v;

@end

@interface Transaction (private_sign)

- (void)sign:(Account *)account;

@end


#pragma mark -
#pragma mark - Account

static NSMutableSet *Wordlist = nil;
static NSDateFormatter *DateFormatter = nil;
static NSDateFormatter *TimeFormatter = nil;

@implementation Account {
    SecureData *_privateKey;
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
        
        DateFormatter = [[NSDateFormatter alloc] init];
        [DateFormatter setDateFormat:@"yyyy-MM-dd"];

        TimeFormatter = [[NSDateFormatter alloc] init];
        [TimeFormatter setDateFormat:@"HH-mm-ss"];
        
        NSLog(@"BIP39 World List: %d words", (int)Wordlist.count);
    });
}

- (instancetype)initWithPrivateKey:(NSData *)privateKey {
    if (privateKey.length != 32) { return nil; }

    self = [super init];
    if (self) {
        _privateKey = [SecureData secureDataWithData:privateKey];
        
        SecureData *publicKey = [SecureData secureDataWithLength:65];
        ecdsa_get_public_key65(&secp256k1, _privateKey.bytes, publicKey.mutableBytes);
        NSData *addressData = [[[publicKey subdataFromIndex:1] KECCAK256] subdataFromIndex:12].data;
        _address = [Address addressWithData:addressData];
    }
    return self;
}

- (instancetype)initWithMnemonicPhrase: (NSString*)mnemonicPhrase {
    const char* phraseStr = [mnemonicPhrase cStringUsingEncoding:NSUTF8StringEncoding];
    if (!mnemonic_check(phraseStr)) { return nil; }
    
    SecureData *seed = [SecureData secureDataWithLength:(512 / 8)];
    mnemonic_to_seed(phraseStr, "", seed.mutableBytes, NULL);
    
    HDNode node;
    hdnode_from_seed([seed bytes], (int)[seed length], SECP256K1_NAME, &node);
    
    hdnode_private_ckd(&node, (0x80000000 | (44)));   // 44' - BIP 44 (purpose field)
    hdnode_private_ckd(&node, (0x80000000 | (60)));   // 60' - Ethereum (see SLIP 44)
    hdnode_private_ckd(&node, (0x80000000 | (0)));    // 0'  - Account 0
    hdnode_private_ckd(&node, 0);                     // 0   - External
    hdnode_private_ckd(&node, 0);                     // 0   - Slot #0
    
    SecureData *privateKey = [SecureData secureDataWithLength:32];
    memcpy(privateKey.mutableBytes, node.private_key, 32);

    self = [self initWithPrivateKey:privateKey.data];
    if (self) {
        _mnemonicPhrase = mnemonicPhrase;
        
        SecureData *fullData = [SecureData secureDataWithLength:MAXIMUM_BIP39_DATA_LENGTH];
        int length = data_from_mnemonic([_mnemonicPhrase cStringUsingEncoding:NSUTF8StringEncoding], fullData.mutableBytes);
        
        _mnemonicData = [fullData subdataToIndex:length].data;
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

#define MNEMONIC_STRENGTH    (128 / 8)

+ (instancetype)randomMnemonicAccount {
    SecureData* data = [SecureData secureDataWithLength:MNEMONIC_STRENGTH];
    int result = SecRandomCopyBytes(kSecRandomDefault, data.length, data.mutableBytes);
    if (result != noErr) { return nil; }

    NSString *mnemonicPhrase = [NSString stringWithCString:mnemonic_from_data(data.bytes, (int)data.length) encoding:NSUTF8StringEncoding];
    return [[Account alloc] initWithMnemonicPhrase:mnemonicPhrase];
}

- (NSString*)_privateKeyHash {
    return [[_privateKey KECCAK256] hexString];
}

- (NSData*)privateKey {
    return _privateKey.data;
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
        SecureData *derivedKey = [SecureData secureDataWithLength:64];
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
            SecureData *macCheck = [SecureData secureDataWithCapacity:(16 + 32)];
            [macCheck append:[derivedKey subdataWithRange:NSMakeRange(16, 16)]];
            [macCheck appendData:cipherText];
            
            if (![[macCheck KECCAK256] isEqual:mac]) {
                sendError(kAccountErrorWrongPassword, @"Wrong Password");
                return;
            }
        }

        SecureData *privateKey = [SecureData secureDataWithLength:32];

        {
            SecureData *encryptionKey = [derivedKey subdataWithRange:NSMakeRange(0, 16)];
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
        
        Account *account = [[Account alloc] initWithPrivateKey:privateKey.data];
        
        if (![account.address isEqualToAddress:expectedAddress]) {
            sendError(kAccountErrorJSONInvalidParameter, @"Address mismatch");
            return;
        }
        
        // Check for an mnemonic phrase
        NSDictionary *ethersData = [data objectForKey:@"x-ethers"];
        if ([ethersData isKindOfClass:[NSDictionary class]] && [[ethersData objectForKey:@"version"] isEqual:@"0.1"]) {
            
            NSData *mnemonicCounter = ensureDataLength([ethersData objectForKey:@"mnemonicCounter"], 16);
            NSData *mnemonicCiphertext = ensureDataLength([ethersData objectForKey:@"mnemonicCiphertext"], 16);
            if (mnemonicCounter && mnemonicCiphertext) {

                SecureData *mnemonicData = [SecureData secureDataWithLength:[mnemonicCiphertext length]];
                
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
                
                Account *mnemonicAccount = [Account accountWithMnemonicData:mnemonicData.data];
                if (![mnemonicAccount.address isEqualToAddress:account.address]) {
                    sendError(kAccountErrorMnemonicMismatch, @"Mnemonic Mismatch");
                    return;
                }
                
                account = mnemonicAccount;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            // Cancelled after derfivation completed but before we responded (on the main thread)
            if (stop) {
                sendError(kAccountErrorCancelled, @"Cancelled");
            } else {
                callback(account, nil);
            }
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
    
    SecureData *iv = [SecureData secureDataWithLength:16];;
    {
        int failure = SecRandomCopyBytes(kSecRandomDefault, (int)iv.length, iv.mutableBytes);
        if (failure) {
            sendResult(nil);
            return nil;
        }
    }

    SecureData *salt = [SecureData secureDataWithLength:32];;
    {
        int failure = SecRandomCopyBytes(kSecRandomDefault, (int)salt.length, salt.mutableBytes);
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
    [json setObject:ethers forKey:@"x-ethers"];
    
    NSMutableDictionary *crypto = [NSMutableDictionary dictionary];
    [json setObject:crypto forKey:@"Crypto"];

    [crypto setObject:@{
                        @"p": @(p),
                        @"r": @(r),
                        @"n": @(n),
                        @"dklen": @([salt length]),
                        @"salt": [[salt hexString] substringFromIndex:2],
                        }
               forKey:@"kdfparams"];
    [crypto setObject:@"scrypt" forKey:@"kdf"];
    
    [crypto setObject:@{
                        @"iv": [[iv hexString] substringFromIndex:2],
                        }
               forKey:@"cipherparams"];
    [crypto setObject:@"aes-128-ctr" forKey:@"cipher"];
    
    // Set ethers parameters
    NSDate *now = [NSDate date];
    NSString *gethFilename = [NSString stringWithFormat:@"UTC--%@T%@.0Z--%@",
                              [DateFormatter stringFromDate:now],
                              [TimeFormatter stringFromDate:now],
                              [[self.address.checksumAddress substringFromIndex:2] lowercaseString]];
    [ethers setObject:gethFilename forKey:@"gethFilename"];
    [ethers setObject:@"ethers/iOS" forKey:@"client"];
    [ethers setObject:@"0.1" forKey:@"version"];

    __block char stop = 0;
    
    Cancellable *cancellable = [[Cancellable alloc] initWithCancelCallback:^() {
        stop = 1;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^() {
        
        // Get the key to encrypt with from the password and salt
        SecureData *derivedKey = [SecureData secureDataWithLength:64];
        int status = crypto_scrypt(passwordBytes, (int)passwordData.length, salt.bytes, salt.length, n, r, p, derivedKey.mutableBytes, derivedKey.length, &stop);
        
        // Bad scrypt parameters
        if (status) {
            sendResult(nil);
            return;
        }
        
        SecureData *cipherText = [SecureData secureDataWithLength:32];
        {
            unsigned char counter[16];
            memcpy(counter, iv.bytes, MIN(iv.length, sizeof(counter)));

            SecureData *encryptionKey = [derivedKey subdataWithRange:NSMakeRange(0, 16)];
            
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
        
        [crypto setObject:[[cipherText hexString] substringFromIndex:2] forKey:@"ciphertext"];

        if (_mnemonicData) {
            SecureData *mnemonicCounter = [SecureData secureDataWithLength:16];;
            {
                int failure = SecRandomCopyBytes(kSecRandomDefault, (int)mnemonicCounter.length, [mnemonicCounter mutableBytes]);
                if (failure) {
                    sendResult(nil);
                    return;
                }
            }

            SecureData *mnemonicCiphertext = [SecureData secureDataWithLength:_mnemonicData.length];
            
            // We are using a different key, so it is safe to use the same IV
            unsigned char counter[16];
            memcpy(counter, mnemonicCounter.bytes, MIN(mnemonicCounter.length, sizeof(counter)));
            
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
            
            [ethers setObject:[[mnemonicCounter hexString] substringFromIndex:2] forKey:@"mnemonicCounter"];
            [ethers setObject:[[mnemonicCiphertext hexString] substringFromIndex:2] forKey:@"mnemonicCiphertext"];
        }

        
        // Compute the MAC
        {
            SecureData *macCheck = [SecureData secureDataWithCapacity:(16 + 32)];
            [macCheck append:[derivedKey subdataWithRange:NSMakeRange(16, 16)]];
            [macCheck append:cipherText];
            [crypto setObject:[[[macCheck KECCAK256] hexString] substringFromIndex:2] forKey:@"mac"];
        }
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
        if (error) {
            NSLog(@"Account: Error decoding JSON - %@", error);
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
    
    SecureData *signatureData = [SecureData secureDataWithLength:64];;
    uint8_t pby;
    ecdsa_sign_digest(&secp256k1, [_privateKey bytes], digestData.bytes, signatureData.mutableBytes, &pby, NULL);
    return [Signature signatureWithData:signatureData.data v:pby];
}

static NSString *MessagePrefix = @"Ethereum Signed Message:\n%d";

+ (NSData*)messageDigest: (NSData*)message {
    NSString *prefix = [NSString stringWithFormat:MessagePrefix, (int)message.length];
    NSData *prefixData = [prefix dataUsingEncoding:NSUTF8StringEncoding];
    
    SecureData *data = [SecureData secureDataWithCapacity:(1 + prefixData.length + message.length)];
    [data appendByte:0x19];
    [data appendData:prefixData];
    [data appendData:message];
    return [data KECCAK256].data;
}

- (Signature*)signMessage:(NSData *)message {
    return [self signDigest:[Account messageDigest:message]];
}

+ (Address*)verifyMessage:(NSData *)message signature:(Signature *)signature {

    NSData *digest = [Account messageDigest:message];

    SecureData *signatureData = [SecureData secureDataWithCapacity:64];
    [signatureData appendData:signature.r];
    [signatureData appendData:signature.s];
    
    char v = signature.v;

    SecureData *publicKey = [SecureData secureDataWithLength:65];

    int failed = ecdsa_verify_digest_recover(&secp256k1, publicKey.mutableBytes, signatureData.bytes, digest.bytes, v);
    if (failed) {
        return nil;
    }
    
    return [Address addressWithData:[[[publicKey subdataFromIndex:1] KECCAK256] subdataFromIndex:12].data];
}

+ (Signature*)signatureWithMessage: (NSData*)message r: (NSData*)r s: (NSData*)s address: (Address*)address {
    NSData *digest = [Account messageDigest:message];

    SecureData *publicKey = [SecureData secureDataWithLength:65];

    SecureData *signatureData = [SecureData secureDataWithCapacity:64];
    [signatureData appendData:r];
    [signatureData appendData:s];

    for (uint8_t recid = 0; recid <= 3; recid++) {
        int failed = ecdsa_verify_digest_recover(&secp256k1, publicKey.mutableBytes, signatureData.bytes, digest.bytes, recid);
        if (failed) { continue; }
        Address *addr = [Address addressWithData:[[[publicKey subdataFromIndex:1] KECCAK256] subdataFromIndex:12].data];
        if ([address isEqualToAddress:addr]) {
            return [Signature signatureWithData:signatureData.data v:recid];
        }
    }
    
    return nil;
}

- (void)sign: (Transaction*)transaction {
    [transaction sign:self];
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
    if (![object isKindOfClass:[Account class]]) { return NO; }
    return [[self _privateKeyHash] isEqualToString:[((Account*)object) _privateKeyHash]];
}

- (NSUInteger)hash {
    return [_address hash];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<Account address=%@>", self.address];
}
@end
