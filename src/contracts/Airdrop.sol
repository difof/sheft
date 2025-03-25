// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { Ownable } from "openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from
    "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "openzeppelin/contracts/utils/Address.sol";
import { Pausable } from "openzeppelin/contracts/utils/Pausable.sol";
import { ReentrancyGuard } from
    "openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { MerkleProofLib } from "solady/utils/MerkleProofLib.sol";

/// @notice Data describing a single eligible membership claim.
/// @dev The Merkle leaf for each membership is derived from the fields of this struct.
/// @dev Chain ID and token address should also be included in leaf hashing off-chain.
struct AirdropMembership {
    /// @notice Wallet that is eligible to claim.
    address userWallet;
    /// @notice Amount of tokens (or native wei) the wallet may claim.
    uint256 claimAmount;
}

/// @title Airdrop external interface
interface IAirdrop {
    /// @return The active Merkle root.
    function merkleRoot() external view returns (bytes32);

    /// @notice Returns whether the given Merkle leaf has been claimed already.
    /// @param _leaf The Merkle leaf associated with a membership.
    /// @return True if the leaf has been marked as claimed.
    function claimed(
        bytes32 _leaf
    ) external view returns (bool);

    /// @notice Withdraws an arbitrary token (or native if `_token == address(0)`) to a recipient.
    /// @dev Only callable by the owner.
    /// @param _token The ERC20 to transfer, or address(0) for native token.
    /// @param _to The recipient address to receive the tokens.
    /// @param _amount The amount to withdraw.
    function withdrawTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    /// @notice Updates the Merkle root controlling eligibility.
    /// @dev Only callable by the owner.
    /// @param _root The new Merkle root to set.
    function updateMerkleRoot(
        bytes32 _root
    ) external;

    /// @notice Pauses claim functionality.
    function pause() external;

    /// @notice Unpauses claim functionality.
    function unpause() external;

    /// @notice Computes the Merkle leaf for a given user, amount and token.
    /// @dev Implementations include `block.chainid` and token address to make leaves chain and token specific.
    /// @param _user The wallet address.
    /// @param _amount The amount claimable by the wallet.
    /// @param _token The ERC20 address or address(0) for native token.
    /// @return The leaf hash.
    function getLeaf(
        address _user,
        uint256 _amount,
        IERC20 _token
    ) external view returns (bytes32);

    /// @notice Verifies if a provided proof is valid for a leaf under the current root.
    /// @param _proof The Merkle proof corresponding to the leaf.
    /// @param _leaf The leaf hash to verify.
    /// @return True if the leaf is part of the tree referenced by the stored root.
    function verifyEligibility(
        bytes32[] calldata _proof,
        bytes32 _leaf
    ) external view returns (bool);

    /// @notice Claims the allocated tokens/native for the caller based on membership data.
    /// @param _proof The Merkle proof for the membership leaf.
    /// @param _membership The membership data (wallet and amount) for the caller.
    /// @param _token The ERC20 address or address(0) for native token to be transferred.
    function claim(
        bytes32[] calldata _proof,
        AirdropMembership calldata _membership,
        IERC20 _token
    ) external;
}

interface IAirdropErrors {
    /// @notice Thrown when the wallet is not included in the Merkle allowlist.
    /// @param userWallet The wallet that attempted an invalid claim.
    error NotEligible(address userWallet);

    /// @notice Thrown when a wallet attempts to claim more than once.
    /// @param userWallet The wallet that already claimed its allocation.
    error AlreadyClaimed(address userWallet);

    /// @notice Thrown when attempting to set the Merkle root to the zero value.
    error ZeroMerkleRoot();

    /// @notice Thrown when the provided Merkle root is identical to the current root.
    error MerkleRootNotChanged();
}

/// @title ETH/ERC20 Merkle Airdrop
/// @notice Distributes ERC20 tokens or native ETH to addresses included in a Merkle tree allowlist. Each wallet can claim a predefined amount only once.
/// @dev The leaf is calculated as `keccak256(abi.encodePacked(user, amount, token, block.chainid))` to prevent cross-chain replay attacks and token cross-over. Verification is performed via Solady's `MerkleProofLib` and security modules from OpenZeppelin are leveraged for ownership, pausing, and reentrancy protection.
contract Airdrop is
    IAirdrop,
    IAirdropErrors,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Address for address payable;
    using SafeERC20 for IERC20;
    using MerkleProofLib for bytes32[];

    /// @notice Active Merkle root used to verify eligibility.
    bytes32 public merkleRoot = 0x0;
    /// @notice Tracks whether a specific Merkle leaf has been claimed.
    mapping(bytes32 => bool) public claimed;

    /// @notice Emitted when the Merkle root is updated.
    /// @param previous The previous Merkle root.
    /// @param updated The new Merkle root.
    event MerkleRootUpdated(bytes32 indexed previous, bytes32 indexed updated);

    /// @notice Emitted when the contract receives native ETH.
    /// @param sender The address that sent the ETH.
    /// @param amount The amount of ETH received.
    event ReceivedNative(address indexed sender, uint256 amount);

    /// @notice Emitted after a successful claim.
    /// @param token The ERC20 token address or address(0) if native.
    /// @param receiver The wallet that received the airdrop.
    /// @param amount The amount of tokens/native (in wei) sent to the receiver.
    event TokensClaimed(
        IERC20 indexed token, address indexed receiver, uint256 amount
    );

    /// @notice Emitted after a successful administrative withdrawal.
    /// @param token The ERC20 token address or address(0) if native.
    /// @param receiver The wallet that received the withdrawn funds.
    /// @param amount The amount withdrawn.
    event TokensWithdrawn(
        IERC20 indexed token, address indexed receiver, uint256 amount
    );

    /// @notice Deploys the airdrop contract and sets the initial owner.
    /// @param _admin The address that will be set as the contract owner.
    constructor(
        address _admin
    ) Ownable(_admin) { }

    /// @notice Accepts plain ETH transfers sent to the contract.
    /// @dev Emits a {ReceivedNative} event.
    receive() external payable {
        emit ReceivedNative(msg.sender, msg.value);
    }

    /// @notice Withdraws tokens or native ETH held by the contract to a recipient.
    /// @dev Only callable by the owner. Native token is specified with `_token == address(0)`.
    /// @dev Emits a {TokensWithdrawn} event.
    /// @param _token The ERC20 token to transfer, or address(0) for native ETH.
    /// @param _to The address receiving the withdrawn funds.
    /// @param _amount The amount to withdraw.
    function withdrawTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _transferToken(_token, _to, _amount);
        emit TokensWithdrawn(_token, _to, _amount);
    }

    /// @notice Updates the Merkle root controlling eligibility.
    /// @dev Only callable by the contract owner.
    /// @dev Emits a {MerkleRootUpdated} event.
    /// @param _root The new Merkle root.
    function updateMerkleRoot(
        bytes32 _root
    ) external onlyOwner {
        if (_root == bytes32(0)) {
            revert ZeroMerkleRoot();
        }

        bytes32 current = merkleRoot;

        if (_root == current) {
            revert MerkleRootNotChanged();
        }

        merkleRoot = _root;
        emit MerkleRootUpdated(current, _root);
    }

    /// @notice Pauses claim functionality.
    /// @dev Only callable by the contract owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses claim functionality.
    /// @dev Only callable by the contract owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Computes the Merkle leaf for a given user and allocation for a token/native context.
    /// @dev The current chain ID is included to make leaves chain-specific and token-specific.
    /// @param _user Wallet address claiming the airdrop.
    /// @param _amount Amount of tokens/native (in wei) the wallet is entitled to.
    /// @param _token The ERC20 token address or address(0) to indicate native token.
    /// @return The calculated leaf hash.
    function getLeaf(
        address _user,
        uint256 _amount,
        IERC20 _token
    ) external view returns (bytes32) {
        return _computeLeaf(_user, _amount, address(_token));
    }

    /// @notice Verifies whether a leaf and proof are part of the stored Merkle root.
    /// @param _proof Merkle proof from the off-chain tree.
    /// @param _leaf Leaf computed via {getLeaf}.
    /// @return True if the proof is valid for the current root.
    function verifyEligibility(
        bytes32[] calldata _proof,
        bytes32 _leaf
    ) external view returns (bool) {
        return _verifyProof(_proof, _leaf);
    }

    /// @notice Claims the allocated tokens/native for the sender.
    /// @dev Reverts with {NotEligible} if the proof is invalid and {AlreadyClaimed} if already claimed.
    /// @dev Emits a {TokensClaimed} event if claim was successful.
    /// @param _proof Corresponding Merkle proof.
    /// @param _membership Packed claim data containing the caller's wallet and allocation.
    /// @param _token The ERC20 token address or address(0) for native.
    function claim(
        bytes32[] calldata _proof,
        AirdropMembership calldata _membership,
        IERC20 _token
    ) external nonReentrant whenNotPaused {
        address user = _membership.userWallet;
        uint256 amount = _membership.claimAmount;
        bytes32 leaf = _computeLeaf(user, amount, address(_token));

        if (!_verifyProof(_proof, leaf)) {
            revert NotEligible(user);
        }

        if (claimed[leaf]) {
            revert AlreadyClaimed(user);
        }

        claimed[leaf] = true;

        _transferToken(_token, user, amount);

        emit TokensClaimed(_token, user, amount);
    }

    /// @dev Transfers `_amount` of `_token` to `_to`. Treats address(0) as native token.
    /// @param _token The ERC20 token address or address(0) for native token.
    /// @param _to The recipient address.
    /// @param _amount The amount to transfer.
    function _transferToken(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        if (address(_token) == address(0)) {
            payable(_to).sendValue(_amount);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    /// @dev Verifies a Merkle proof against the stored `merkleRoot`.
    /// @param _proof The Merkle proof corresponding to `_leaf`.
    /// @param _leaf The leaf being verified.
    /// @return _isMember True if the proof is valid.
    function _verifyProof(
        bytes32[] calldata _proof,
        bytes32 _leaf
    ) internal view returns (bool _isMember) {
        _isMember = _proof.verifyCalldata(merkleRoot, _leaf);
    }

    /// @dev Computes the leaf for `(user, amount, token, chainid)` packed as addresses and uint256.
    /// @dev Using Yul inline assembly for gas optimization because keccak256 and abi.encodePacked are somewhat expensive.
    /// @param _user The wallet address.
    /// @param _amount The claim amount.
    /// @param _token The token address (zero for native) used in the leaf.
    /// @return _hash The keccak256 hash of the packed data.
    function _computeLeaf(
        address _user,
        uint256 _amount,
        address _token
    ) internal view returns (bytes32 _hash) {
        assembly {
            // user 20 + amount 32 + token 20 + chainid 32 = 104 (0x68)
            let mem := mload(0x40)
            // pack data
            // user (address): 20 bytes at offset 0
            // shift left by 12 bytes (96 bits)
            mstore(mem, shl(0x60, _user))
            // amount (uint256): 32 bytes at offset 20 (0x14)
            mstore(add(mem, 0x14), _amount)
            // token (address): 20 bytes at offset 52 (0x34)
            // shift left by 12 bytes to align address
            mstore(add(mem, 0x34), shl(0x60, _token))
            // chainid (uint256): 32 bytes at offset 72 (0x48)
            mstore(add(mem, 0x48), chainid())

            _hash := keccak256(mem, 0x68)
        }
    }
}
