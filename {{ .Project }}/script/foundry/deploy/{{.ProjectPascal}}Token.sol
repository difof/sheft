// SPDX-License-Identifier: {{.Scaffold.license}}

pragma solidity {{.Scaffold.solc_version}};

import { Script } from "forge-std/Script.sol";

import "../../../src/contracts/{{.ProjectPascal}}Token.sol";

contract Deploy_{{.ProjectPascal}}Token is Script {
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
        return address(new {{.ProjectPascal}}Token(_totalSupply, _owner));
    }
}
