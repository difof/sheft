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

        bytes32[] memory leaves = _hashData(_data, token);
        (bytes32[] memory tree,) = _updateRoot(airdrop, leaves);
        bytes32[] memory proof = MerkleTreeLib.leafProof(tree, _leafIndex);
        AirdropMembership memory memberToClaim = _data[_leafIndex];

        uint256 balanceBefore = token.balanceOf(memberToClaim.userWallet);

        vm.expectEmit(address(airdrop));
        emit Airdrop.TokensClaimed(
            token, memberToClaim.userWallet, memberToClaim.claimAmount
        );
        {
            airdrop.claim(proof, memberToClaim, token);
        }

        uint256 balanceAfter = token.balanceOf(memberToClaim.userWallet);

        assertTrue(balanceAfter - balanceBefore == memberToClaim.claimAmount);
    }

    function testFuzz_Claim_NativeToken_HappyPath(
        AirdropMembership[] memory _data,
        uint256 _leafIndex
    ) public {
        _fuzzDefaultCaps(_data, _leafIndex);
        vm.assume(_isAddressPayable(_data[_leafIndex].userWallet));

        (Airdrop airdrop,) = _setUpAirdrop();

        bytes32[] memory leaves = _hashData(_data, IERC20(address(0)));
        (bytes32[] memory tree,) = _updateRoot(airdrop, leaves);
        bytes32[] memory proof = MerkleTreeLib.leafProof(tree, _leafIndex);
        AirdropMembership memory memberToClaim = _data[_leafIndex];

        uint256 balanceBefore = memberToClaim.userWallet.balance;

        vm.expectEmit(address(airdrop));
        emit Airdrop.TokensClaimed(
            IERC20(address(0)),
            memberToClaim.userWallet,
            memberToClaim.claimAmount
        );
        {
            airdrop.claim(proof, memberToClaim, IERC20(address(0)));
        }

        uint256 balanceAfter = memberToClaim.userWallet.balance;

        assertTrue(balanceAfter - balanceBefore == memberToClaim.claimAmount);
    }

    }
}
