// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;
contract Airdrop is
    bytes32 public merkleRoot = 0x0;
    event MerkleRootUpdated(bytes32 indexed previous, bytes32 indexed updated);
}
