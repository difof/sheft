// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import { MerkleTreeLib } from "solady/utils/MerkleTreeLib.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AirdropSetup } from "./Airdrop.setup.sol";

import "../../src/contracts/Airdrop.sol";

contract TestFuzz_AirdropClaim is AirdropSetup {
    function testFuzz_Claim_ERC20_HappyPath(
        AirdropMembership[] memory _data,
        uint256 _leafIndex
    ) public {
        _fuzzDefaultCaps(_data, _leafIndex);

        (Airdrop airdrop, IERC20 token) = _setUpAirdrop();
    }
}
