// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;
import { Ownable } from "openzeppelin/contracts/access/Ownable.sol";
contract Airdrop is
    Ownable,
{
    bytes32 public merkleRoot = 0x0;
    event MerkleRootUpdated(bytes32 indexed previous, bytes32 indexed updated);
    event ReceivedNative(address indexed sender, uint256 amount);
    constructor(
        address _admin
    ) Ownable(_admin) { }
    receive() external payable {
        emit ReceivedNative(msg.sender, msg.value);
    }
}
