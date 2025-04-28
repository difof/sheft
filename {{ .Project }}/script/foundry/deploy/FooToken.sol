// SPDX-License-Identifier: UNLICENCED

pragma solidity 0.8.23;

import { Script } from "forge-std/Script.sol";

import "../../../src/contracts/FooToken.sol";

contract Deploy_FooToken is Script {
    function run() public {
        address owner = vm.getWallets()[0];
        uint256 totalSupply = 777 ether;

        vm.startBroadcast();
        deploy(totalSupply, owner);
        vm.stopBroadcast();
    }

    function deploy(
        uint256 _totalSupply,
        address _owner
    ) public returns (address token) {
        return address(new FooToken(_totalSupply, _owner));
    }
}
