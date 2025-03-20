// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;
import { Ownable } from "openzeppelin/contracts/access/Ownable.sol";
contract Airdrop is
    Ownable,
{
    bytes32 public merkleRoot = 0x0;
    event MerkleRootUpdated(bytes32 indexed previous, bytes32 indexed updated);
    constructor(
        address _admin
    ) Ownable(_admin) { }
}
