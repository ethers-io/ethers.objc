'use strict';

/**
 *  A quick script to extract and decrypt the mnemonic from a JSON
 *  wallet created with Ethers Wallet.
 *
 *  Ethers Wallet places metadata in the JSON wallet format with
 *  the key x-ethers, which contains:
 *  - client: the client used to create the wallet
 *  - gethFilename: a Geth compatible keystore filename for the file
 *  - version: the x-ethers version
 *  - mnemonicCounter: the counter (IV) for the encryptedCiphertext
 *  - mnemonicCiphertext: the encrypted mnemonic the wallet was derived from
 *
 *  The mnemonic is encrypted with aes-256-ctr with:
 *  - key: derivedKey[32:64] (the same derived key used for encrypting the wallet)
 *  - iv: mnemonicCounter
 *  - cipherText: mnemonicCiphertext
 *
 *  This is just a quick test script. You should never put a password you care about
 *  in the command line of an application; we will make this tool more robust in the
 *  future.
 */

var fs = require('fs');

var aesjs = require('aes-js');
var bip39 = require('bip39');
var HDNode = require('bitcoinjs-lib').HDNode;
var keccak256 = require('js-sha3').keccak_256;
var scrypt = require('scrypt-js');

function getPath(object, path, coerce) {
    try {
        var components = path.split('/');
        for (var i = 0; i < components.length; i++) {
            object = object[components[i]];
        }
    } catch (error) {
        throw new Error('missing ' + path);
    }

    if (coerce) { object = coerce(object); }

    return object;
}

function ensureInteger(value) {
    var result = parseInt(value)
    if (result != value) {
        throw new Error('invalid integer: ' + value);
    }
    return result;
}

function ensureBuffer(value) {
    if (typeof(value) !== 'string' || !value.match(/^(0x)?[0-9A-Fa-f]*$/)) {
        throw new Error('invalid hex: ' +  value);
    }

    if (value.substring(0, 2) === '0x') {
        value = value.substring(2);
    }

    return new Buffer(value, 'hex');
}

function extractMnemonic(json, password) {
    return new Promise(function(resolve, reject) {
        try {
            var data = JSON.parse(json);
        } catch (error) {
            reject(error);
            return;
        }

        var cipherText = getPath(data, 'x-ethers/mnemonicCiphertext', ensureBuffer);
        var counter = getPath(data, 'x-ethers/mnemonicCounter', ensureBuffer);
        var address = getPath(data, 'address');

        var N = getPath(data, 'Crypto/kdfparams/n', ensureInteger);
        var p = getPath(data, 'Crypto/kdfparams/p', ensureInteger);
        var r = getPath(data, 'Crypto/kdfparams/r', ensureInteger);
        password = new Buffer(password);
        var salt = getPath(data, 'Crypto/kdfparams/salt', ensureBuffer);

        scrypt(password, salt, N, r, p, 64, function(error, progress, key) {
            if (error) {
                reject(error);

            } else if (key) {
                var aes = new aesjs.ModeOfOperation.ctr(new Buffer(key.slice(32)), new aesjs.Counter(counter));
                var mnemonic = bip39.entropyToMnemonic(aes.decrypt(cipherText))
                var root = HDNode.fromSeedBuffer(bip39.mnemonicToSeed(mnemonic));
                var node = root.derivePath("m/44'/60'/0'/0/0");
                var privateKey = node.keyPair.d.toBuffer(32);
                var publicKey = node.keyPair.Q.getEncoded(false);
                var computedAddress = keccak256(publicKey.slice(1)).substring(24);
                if (computedAddress !== address) {
                    reject(new Error('wrong password'));
                    return;
                }
                //console.log('Mnemonic Phrase: ' + mnemonic);
                //console.log('Private Key:     0x' + privateKey.toString('hex'));
                //console.log('Public Key:      0x' + publicKey.toString('hex'));
                //console.log('Address:         0x' + address);
                resolve(mnemonic);
            }
        });
    });
}

var args = process.argv.slice(2);
if (args.length !== 2) {
    console.log('Usage: node index.js FILENAME PASSWORD');

} else {
    try {
        var data = fs.readFileSync(args[0]);
    } catch(error) {
        console.log('Error opening file: ' + error.message);
        process.exit(1)
    }

    extractMnemonic(data, args[1]).then(function(mnemonic) {
        console.log(mnemonic);
    }, function(error) {
        console.log('Error decrpyting file: ' + error.message);
        process.exit(1)
    });
}
