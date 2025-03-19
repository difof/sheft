// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { ERC20 } from "openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FooToken is ERC20 {
    constructor(uint256 _totalSupply, address _mintFor) ERC20("NAME", "SYM") {
        _mint(_mintFor, _totalSupply);
    }
}
