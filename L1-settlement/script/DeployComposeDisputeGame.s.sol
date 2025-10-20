// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {ComposeDisputeGame} from "../src/ComposeDisputeGame.sol";

contract DeployComposeDisputeGame is Script {
    function run(address oracle) public returns (address composeDisputeGame) {
        vm.startBroadcast();

        console.log("Deploying ComposeDisputeGame implementation...");
        composeDisputeGame = address(new ComposeDisputeGame(oracle));

        console.log(
            "ComposeDisputeGame implementation deployed at:",
            composeDisputeGame
        );

        vm.stopBroadcast();
    }
}
