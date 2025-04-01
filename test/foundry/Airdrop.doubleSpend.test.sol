// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { MerkleTreeLib } from "solady/utils/MerkleTreeLib.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AirdropSetup } from "./Airdrop.setup.sol";

import "../../src/contracts/Airdrop.sol";

contract Test_AirdropDoubleSpend is AirdropSetup {
    function test_DoubleSpend_ERC20_HappyPath() public {
        uint256 claimAmount = 1 ether;
        (Airdrop airdrop, IERC20 token) = _setUpAirdrop();

        bytes32 leaf = keccak256(
            abi.encodePacked(
                claimant, claimAmount, address(token), MOCK_CHAINID
            )
        );
        bytes32 dummyLeaf = keccak256(
            abi.encodePacked(
                address(0xDEADBEEF), uint256(0), address(0xABCDEF), MOCK_CHAINID
            )
        );
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = leaf;
        leaves[1] = dummyLeaf;

        bytes32[] memory tree = MerkleTreeLib.build(leaves);
        bytes32 root = MerkleTreeLib.root(tree);

        vm.startPrank(owner);
        airdrop.updateMerkleRoot(root);
        vm.stopPrank();

        bytes32[] memory proof = MerkleTreeLib.leafProof(tree, 0);

        AirdropMembership memory member = AirdropMembership({
            userWallet: claimant,
            claimAmount: claimAmount
        });

        vm.prank(claimant);
        airdrop.claim(proof, member, token);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAirdropErrors.AlreadyClaimed.selector, claimant
            )
        );
        vm.prank(claimant);
        airdrop.claim(proof, member, token);
    }
}
