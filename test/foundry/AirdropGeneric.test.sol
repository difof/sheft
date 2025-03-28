// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { MerkleTreeLib } from "solady/utils/MerkleTreeLib.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "openzeppelin/contracts/utils/Address.sol";
import { Pausable } from "openzeppelin/contracts/utils/Pausable.sol";

import { AirdropSetup } from "./Airdrop.setup.sol";

import "../../src/contracts/Airdrop.sol";

contract Test_Airdrop_Generic is AirdropSetup {
    using Address for address payable;
    function test_DepositAndWithdraw_Native() public {
        uint256 amount = 10 ether;
        deal(address(owner), amount);

        Airdrop airdrop = new Airdrop(owner);

        vm.startPrank(owner);

        // deposit
        vm.expectEmit(address(airdrop));
        emit Airdrop.ReceivedNative(owner, amount);
        payable(address(airdrop)).sendValue(amount);

        // withdraw
        vm.expectEmit(address(airdrop));
        emit Airdrop.TokensWithdrawn(IERC20(address(0)), owner, amount);
        airdrop.withdrawTokens(IERC20(address(0)), owner, amount);

        vm.stopPrank();
    }

    function test_PauseAndUnpause() public {
        Airdrop airdrop = new Airdrop(owner);

        vm.startPrank(owner);

        vm.expectEmit(address(airdrop));
        emit Pausable.Paused(owner);
        airdrop.pause();

        vm.expectEmit(address(airdrop));
        emit Pausable.Unpaused(owner);
        airdrop.unpause();

        vm.stopPrank();
    }

    function test_UpdateMerkleRoot_ZeroRoot_Reverts() public {
        Airdrop airdrop = new Airdrop(owner);

        vm.startPrank(owner);

        vm.expectRevert(IAirdropErrors.ZeroMerkleRoot.selector);
        airdrop.updateMerkleRoot(bytes32(0));

        vm.stopPrank();
    }

    function test_UpdateMerkleRoot_SameRoot_Reverts() public {
        Airdrop airdrop = new Airdrop(owner);
        bytes32 testRoot = keccak256("test root");

        vm.startPrank(owner);

        airdrop.updateMerkleRoot(testRoot);
        vm.expectRevert(IAirdropErrors.MerkleRootNotChanged.selector);
        airdrop.updateMerkleRoot(testRoot);

        vm.stopPrank();
    }

    function test_GetLeaf() public {
        Airdrop airdrop = new Airdrop(owner);
        IERC20 token = IERC20(address(0x123));

        bytes32 leaf = airdrop.getLeaf(claimant, 1 ether, token);
        bytes32 expectedLeaf = keccak256(
            abi.encodePacked(
                claimant, uint256(1 ether), address(token), MOCK_CHAINID
            )
        );

        assertEq(leaf, expectedLeaf);
    }

    function test_VerifyEligibility() public {
        Airdrop airdrop = new Airdrop(owner);

        bytes32 leaf = keccak256("test leaf");
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = leaf;

        bytes32[] memory tree = MerkleTreeLib.build(leaves);
        bytes32 root = MerkleTreeLib.root(tree);

        vm.prank(owner);
        airdrop.updateMerkleRoot(root);

        bytes32[] memory proof = MerkleTreeLib.leafProof(tree, 0);

        assertTrue(airdrop.verifyEligibility(proof, leaf));
    }

    function test_Claim_NotEligible_Reverts() public {
        (Airdrop airdrop, IERC20 token) = _setUpAirdrop();

        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = keccak256("different leaf");

        (bytes32[] memory tree,) = _updateRoot(airdrop, leaves);
        bytes32[] memory wrongProof = MerkleTreeLib.leafProof(tree, 0);

        AirdropMembership memory member =
            AirdropMembership({ userWallet: claimant, claimAmount: 1 ether });

        vm.expectRevert(
            abi.encodeWithSelector(
                IAirdropErrors.NotEligible.selector, claimant
            )
        );
        airdrop.claim(wrongProof, member, token);
    }
}
