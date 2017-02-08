ethers.objc
===========

Everything you need to write your own Ethereum wallet and interact with the blockchain.

Please note this documentation is a work in progress, with many stubs and place holders. The bulk of the documentation is being put together in a readthedocs RST document and this is just to help out a (very) little in the meantime.

**Features:**

- Simple and complete public API
- Ready-to-go; drop the framework into your project and you are off to the races
- Full testnet support
- Geth Secret Storage Wallet support
- BIP39 + BIP32 + BIP44 support (SLIP 44)
- ICAP + checksum address support
- Multiple providers and meta-providers
- Secure; all private keys are stored in self-clearing memory
- A large test suite to ensure correctness against other libraries
- Open Source (MIT Licensed)



API
===

To use the Framework, add the ethers.Framework to your project and add:

```obj-c
@import ethers;
```

Fundamentals
------------

**Account**

An account contains a private key used to sign transactions and prove ownership of an account.

- Import/Export Geth Secret storage wallets
- Generate and import BIP 39 mnemonic wallets (m/44'/60'/0'/0/0)

**Provider**

- A provider is used to connect to the blockchain.


Common Objects
--------------

**Address**

- Checksum Addresses
- IBAN/ICAP Addresses

**BigNumber**

- Explain why we need to use Bignumbers

**Hash**

- BlockHash
- TransactionHash

**Promise**

- Async
- Chainable and able to make a dependency tree


Detail Objects
--------------

**Transaction**

- Serialize and deserialize transactions
- EIP155 support

**TransactionInfo**

- Information (possibly incomplete) about a transaction

**BlockInfo**

- Information about a block


Providers
---------

**EtherscanProvider**

- Connects to the [Etherscan](https://etherscan.io) API endpoints.

**InfuraProvider**

- Connect to [INFURA](https://infura.io) with an optional API Access Token.

**JsonRpcProvider**

- Connect to any Parity, Geth, et cetera node.

**FallbackProvider**

- On error, try the next provider in the list.

**RoundRobinProvider**

- Randomly selects from a list of providers, with fallback.

**LightWalletProvider**

- Experimental
- Still a lot of issues with the iOS Geth library (and xgo)
- Makes the phone VERY hot


Utilities
---------

**SecureData**

- Create NSMutableData backed objects with a SecureAllocator to zero the memory when deallocated.
- Convenience methods for operating on hex strings

**Payment**

- Convert between ether value strings and wei
- Parse payment URI


To Do
=====

**Contract API**

Still need an equivalent to the Ethers.Contract object to parse an ABI, and generate ABI encoders/decoders.


License
=======

MIT License.


Donations
=========

Everything is released under the MIT license, so these is **absolutely no need** to donate anything. If you would like to buy me a coffee though, I certainly won't complain. =)

- **Ethereum:** `0x2F40e3b51533698A14aFcf7Fe386050e22e1FdB2`
- **Bitcoin:** `18QMCEt71xUioVncupxy8ZajKooFkpG4Y6`
