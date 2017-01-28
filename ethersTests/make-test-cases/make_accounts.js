'use strict';

var fs = require('fs');

var ethereumUtil = require('ethereumjs-util');
var iban = require('./node_modules/web3/lib/web3/iban.js');

var Tests = [
    '0x0000000000000000000000000000000000000000',
    '0x0000000000000000000000000000000000000001',
    '0xfffffffffffffffffffffffffffffffffffffffe',
    '0xffffffffffffffffffffffffffffffffffffffff',
]

var Output = [];
Tests.forEach(function(address) {
     Output.push({
         address: address,
         checksumAddress: ethereumUtil.toChecksumAddress(address),
         icap: (iban.fromAddress(address))._iban,
     });
});

for (var i = 0; i < 1000; i++) {
    var privateKey = ethereumUtil.sha3("sunflowerSeed" + i);
    var address = '0x' + ethereumUtil.privateToAddress(privateKey).toString('hex');
    Output.push({
         address: address,
         checksumAddress: ethereumUtil.toChecksumAddress(address),
         icap: (iban.fromAddress(address))._iban,
         privateKey: '0x' + privateKey.toString('hex'),
    });
}


fs.writeFileSync('../test-cases/tests-accounts.json', JSON.stringify(Output, undefined, ' '));

console.log('Generated ../test-cases/tests-accounts.json.');

