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

}
