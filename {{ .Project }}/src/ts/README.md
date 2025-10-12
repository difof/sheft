# TypeScript Utilities

This directory contains TypeScript utility modules for blockchain development.

## Keccak

The `keccak.ts` module provides a simple interface for generating Keccak-256 hashes, which is the same hashing algorithm used by Ethereum. This utility is particularly useful when you don't need to import the entire ethers for just hashing.

### Usage

The keccak function automatically handles hex-prefixed strings and returns a hex-encoded hash:

```typescript
import keccak from "./keccak.ts"

// Hash a regular string
const hash1 = keccak("Hello, World!")

// Hash a hex-prefixed string (automatically strips 0x prefix)
const hash2 = keccak("0x742d35cc6b8B4C0532C15f9AD3E8b8c8bB8c9e3f")
```

The function is designed to be compatible with ethers.js keccak256 implementation, except that it doesn't add the '0x' prefix, ensuring consistent hashing across different libraries. This is particularly important when working with smart contracts that expect specific hash formats.

## Merkle Wrapper

The `merkle.ts` module provides a type-safe wrapper around the MerkleTree functionality, making it easier to work with Merkle trees in TypeScript applications. This is especially useful for implementing airdrop mechanisms, whitelist verification, or any scenario requiring efficient proof-of-inclusion verification.

### Usage

The MerkleWrapper class provides a clean interface for creating and working with Merkle trees:

```typescript
import MerkleWrapper from "./merkle.ts"
import keccak from "./keccak.ts"

// Define your data structure
interface WhitelistEntry {
    address: string
    amount: number
}

// Create a wrapper with your data
const whitelist = [
    { address: "0x742d35cc6b8B4C0532C15f9AD3E8b8c8bB8c9e3f", amount: 1000 },
    { address: "0x8ba1f109551bD432803012645Hac189451c4e155", amount: 2000 }
]

const merkleWrapper = new MerkleWrapper(
    whitelist,
    (entry) => `${entry.address}-${entry.amount}`, // mapper function
    (input) => "0x" + keccak(input) // hash function
)

// Get the root hash for storage in your smart contract
const root = merkleWrapper.getRoot()

// Generate a proof for a specific entry
const proof = merkleWrapper.getProof(0) // by index
// or
const proof2 = merkleWrapper.getProof(whitelist[0]) // by item
```

The wrapper handles the complexity of Merkle tree construction while providing type safety and a clean API for common operations like proof generation and root hash extraction.

## Prompt Secret

The `prompt-secret.ts` module is a utility script used by the `wallet:import:mnemonic` task in the Taskfile to securely prompt users for mnemonic phrases and account indices when importing wallets from BIP39 mnemonic seeds.

### Usage

This script is automatically executed by the task system:

```bash
task wallet:import:mnemonic -- mywallet
```

The script will:
1. Prompt for a 12-word mnemonic phrase
2. Prompt for an account index (defaults to 0)
3. Save the mnemonic to `.keystore/.tmp.mn`
4. Save the account index to `.keystore/.tmp.mni`
5. The task then uses these temporary files with `cast wallet import` to create the keystore

### Features

- **Secure prompting**: Uses the `@inquirer/prompts` library for secure password input
- **Error handling**: Graceful handling of user cancellation and other errors
- **Temporary storage**: Saves sensitive data to temporary files for use by the cast command
- **Task integration**: Automatically cleaned up after use by the task system

