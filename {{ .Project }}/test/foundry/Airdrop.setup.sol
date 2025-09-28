// SPDX-License-Identifier: {{.Scaffold.license}}

pragma solidity {{.Scaffold.solc_version}};

import { Test } from "forge-std/Test.sol";

import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import { MerkleTreeLib } from "solady/utils/MerkleTreeLib.sol";

import "../../src/contracts/{{.ProjectPascal}}Token.sol";
import "../../src/contracts/Airdrop.sol";

/// @title Airdrop test setup helpers
/// @notice Provides common fixtures, constants and utilities for Airdrop tests.
contract AirdropSetup is Test {
    /// @notice Mock chain id used to ensure leaves are chain-specific in tests.
    uint256 internal constant MOCK_CHAINID = 1234;

    /// @notice Test owner address.
    address internal owner = vm.addr(0xdeadbeef);
    /// @notice Default claimant address used across tests.
    address internal claimant = vm.addr(0xbeeffeeAcc097);

    /// @notice Sets the test chain id to `MOCK_CHAINID` for deterministic hashing.
    function setUp() public {
        vm.chainId(MOCK_CHAINID);
    }

    /// @notice Deploys the `Airdrop` and funds it with both native ETH and a fresh ERC20 token.
    /// @dev Transfers the entire token supply to the airdrop and deals max native balance.
    /// @return _airdrop The deployed airdrop instance.
    /// @return _token The ERC20 token minted and transferred to the airdrop.
    function _setUpAirdrop()
        internal
        returns (Airdrop _airdrop, IERC20 _token)
    {
        _airdrop = new Airdrop(owner);
        _token = new {{.ProjectPascal}}Token(type(uint256).max, address(_airdrop));
        deal(address(_airdrop), type(uint256).max);
    }

    /// @notice Hashes membership data into leaves using `(user, amount, token, chainid)` packing.
    /// @param _data Membership entries to hash.
    /// @param _token The token used for hashing (address(0) for native).
    /// @return _buffer Array of hashed leaves.
    function _hashData(
        AirdropMembership[] memory _data,
        IERC20 _token
    ) internal pure returns (bytes32[] memory _buffer) {
        _buffer = new bytes32[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            _buffer[i] = keccak256(
                abi.encodePacked(
                    _data[i].userWallet,
                    _data[i].claimAmount,
                    address(_token),
                    MOCK_CHAINID
                )
            );
        }
    }

    /// @notice Builds a Merkle tree from leaves using Solady's `MerkleTreeLib`.
    /// @param _leaves The leaf nodes.
    /// @return _tree The full merkle tree array.
    function _buildTree(
        bytes32[] memory _leaves
    ) internal pure returns (bytes32[] memory _tree) {
        _tree = MerkleTreeLib.build(_leaves);
    }

    /// @notice Updates the airdrop's root with a tree built from `_leaves` and expects the event.
    /// @param _airdrop Airdrop instance to update.
    /// @param _leaves Leaves used to build the tree.
    /// @return _tree The built tree.
    /// @return _root The computed root set on the airdrop.
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
