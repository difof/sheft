// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;
import { Ownable } from "openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from
    "openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "openzeppelin/contracts/utils/Address.sol";
import { Pausable } from "openzeppelin/contracts/utils/Pausable.sol";
import { MerkleProofLib } from "solady/utils/MerkleProofLib.sol";
interface IAirdropErrors {
    error ZeroMerkleRoot();
    error MerkleRootNotChanged();
}
contract Airdrop is
    IAirdropErrors,
    Ownable,
    Pausable,
{
    using Address for address payable;
    using SafeERC20 for IERC20;
    using MerkleProofLib for bytes32[];
    bytes32 public merkleRoot = 0x0;
    event MerkleRootUpdated(bytes32 indexed previous, bytes32 indexed updated);
    event ReceivedNative(address indexed sender, uint256 amount);
    event TokensWithdrawn(
        IERC20 indexed token, address indexed receiver, uint256 amount
    );
    constructor(
        address _admin
    ) Ownable(_admin) { }
    receive() external payable {
        emit ReceivedNative(msg.sender, msg.value);
    }
    function withdrawTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _transferToken(_token, _to, _amount);
        emit TokensWithdrawn(_token, _to, _amount);
    }
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
    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }
    function verifyEligibility(
        bytes32[] calldata _proof,
        bytes32 _leaf
    ) external view returns (bool) {
        return _verifyProof(_proof, _leaf);
    }
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
    function _verifyProof(
        bytes32[] calldata _proof,
        bytes32 _leaf
    ) internal view returns (bool _isMember) {
        _isMember = _proof.verifyCalldata(merkleRoot, _leaf);
    }
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
