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

    function _setUpAirdrop()
        internal
        returns (Airdrop _airdrop, IERC20 _token)
    {
        _airdrop = new Airdrop(owner);
        _token = new FooToken(type(uint256).max, address(_airdrop));
        deal(address(_airdrop), type(uint256).max);
    }

    function _buildTree(
        bytes32[] memory _leaves
    ) internal pure returns (bytes32[] memory _tree) {
        _tree = MerkleTreeLib.build(_leaves);
    }

    function _updateRoot(
        Airdrop _airdrop,
        bytes32[] memory _leaves
    ) internal returns (bytes32[] memory _tree, bytes32 _root) {
        _tree = _buildTree(_leaves);
        _root = MerkleTreeLib.root(_tree);

        vm.startPrank(_airdrop.owner());
        vm.expectEmit(address(_airdrop));
        emit Airdrop.MerkleRootUpdated(bytes32(0x0), _root);
        {
            _airdrop.updateMerkleRoot(_root);
        }
        vm.stopPrank();
    }
}
