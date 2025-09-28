// SPDX-License-Identifier: {{.Scaffold.license}}

pragma solidity {{.Scaffold.solc_version}};

import { Script } from "forge-std/Script.sol";

import "../../../src/contracts/Airdrop.sol";

contract Deploy_Airdrop is Script {
    function run() public {
        address owner = vm.getWallets()[0];

        vm.startBroadcast();
        deploy(owner);
        vm.stopBroadcast();
    }

    function deploy(
        address _owner
    ) public returns (address airdrop) {
        return address(new Airdrop(_owner));
    }
}
