// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { Test } from "forge-std/Test.sol";

import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MerkleTreeLib } from "solady/utils/MerkleTreeLib.sol";

import "../../src/contracts/FooToken.sol";
import "../../src/contracts/Airdrop.sol";
