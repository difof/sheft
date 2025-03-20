// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { ERC20 } from "openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title FooToken
/// @notice A basic ERC20 token with fixed supply minted at deployment.
/// @dev This token has no pausable functionality and mints the entire supply to a specified address during construction.
contract FooToken is ERC20 {
    /// @notice Creates the FooToken with a fixed total supply.
    /// @dev Mints the entire token supply to the specified address during deployment.
    ///      There is no additional minting functionality after deployment.
    ///      This contract has no pausable features - transfers cannot be halted.
    /// @param _totalSupply The total number of tokens to mint (18 decimals).
    /// @param _mintFor The address that will receive the entire token supply.
    constructor(uint256 _totalSupply, address _mintFor) ERC20("NAME", "SYM") {
        _mint(_mintFor, _totalSupply);
    }
}
