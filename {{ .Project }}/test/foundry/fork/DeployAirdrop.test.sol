// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import { Test } from "forge-std/Test.sol";

import { Deploy_Airdrop } from "../../../script/foundry/deploy/Airdrop.s.sol";
import { Ownable } from "openzeppelin/contracts/access/Ownable.sol";

contract TestFork_DeployAirdrop is Test {
    address owner = vm.addr(0x200);

    Deploy_Airdrop deployScript;

    function setUp() public {
        deployScript = new Deploy_Airdrop();
    }

    function testFork_DeployAirdrop() public {
        vm.expectEmit();
        emit Ownable.OwnershipTransferred(address(0), address(owner));
        deployScript.deploy(owner);
    }
}
