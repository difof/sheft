// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import { MerkleTreeLib } from "solady/utils/MerkleTreeLib.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AirdropSetup } from "./Airdrop.setup.sol";

import "../../src/contracts/Airdrop.sol";

/// @title Airdrop claim fuzz tests
/// @notice Fuzzes successful claim paths for ERC20 and native token flows.
contract TestFuzz_AirdropClaim is AirdropSetup {
    /// @notice Fuzz: any valid membership set should allow the indexed user to claim ERC20 tokens once.
    /// @param _data Array of membership entries used to build the Merkle tree.
    /// @param _leafIndex Index of the membership in `_data` that will claim.
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

    /// @notice Fuzz: any valid membership set should allow the indexed user to claim native ETH once.
    /// @param _data Array of membership entries used to build the Merkle tree.
    /// @param _leafIndex Index of the membership in `_data` that will claim.
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

    /// @notice Applies fuzzing assumptions to bound array sizes, indices and values.
    /// @param _data Membership data used to construct the tree.
    /// @param _leafIndex The candidate index for the claiming member.
    function _fuzzDefaultCaps(
        AirdropMembership[] memory _data,
        uint256 _leafIndex
    ) internal pure {
        vm.assume(_data.length > 1);
        vm.assume(_leafIndex < _data.length);
        vm.assume(_data[_leafIndex].userWallet != address(0));
        vm.assume(_data[_leafIndex].claimAmount < type(uint256).max);
    }

    /// @notice Helper that checks whether an address can receive native ETH via a plain call.
    /// @param _input The address to test for payability.
    /// @return True if the address can receive native ETH.
    function _isAddressPayable(
        address _input
    ) internal returns (bool) {
        deal(address(this), 1);
        (bool ok,) = _input.call{ value: 1 }("");
        return ok;
    }
}
