// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { Test } from "forge-std/Test.sol";

import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MerkleTreeLib } from "solady/utils/MerkleTreeLib.sol";

import "../../src/contracts/FooToken.sol";
import "../../src/contracts/Airdrop.sol";
contract AirdropSetup is Test {
    uint256 internal constant MOCK_CHAINID = 1234;
    address internal owner = vm.addr(0xdeadbeef);
    address internal claimant = vm.addr(0xbeeffeeAcc097);

    function setUp() public {
        vm.chainId(MOCK_CHAINID);
    }

}
