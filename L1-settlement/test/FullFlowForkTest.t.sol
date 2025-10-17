// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IDisputeGameFactory} from "../lib/optimism/packages/contracts-bedrock/interfaces/dispute/IDisputeGameFactory.sol";
import {IDisputeGame} from "../lib/optimism/packages/contracts-bedrock/interfaces/dispute/IDisputeGame.sol";
import {ISP1Verifier} from "../lib/sp1-contracts/contracts/src/ISP1Verifier.sol";
import {Claim, GameStatus, GameType, Hash, Timestamp} from "@optimism/src/dispute/lib/Types.sol";
import {IComposeL2OutputOracle} from "../src/interfaces/IComposeL2OutputOracle.sol";
import {IComposeL2OutputOracleTypes} from "../src/interfaces/IComposeL2OutputOracle.sol";
import {ComposeL2OutputOracle} from "../src/ComposeL2OutputOracle.sol";
import {ComposeDisputeGame} from "../src/ComposeDisputeGame.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Utils} from "./Utils.sol";
import "forge-std/Test.sol";

contract ForkTestFullFlow is Test, Utils {
    // TODO find a way to calculate these values
    uint32 internal gameType = 5555;
    bytes32 internal rootClaim = 0x91af865f72ec6d7f32385c863134f7d37b712a0543be5b9e025c37c1b544f73b;
    bytes32 internal gameHash = 0xd7be2c90491cc594de9b7bf6bad0da650eb71cbc72277653a3e0ec2ff9fbb522;
    bytes internal extraData = hex"0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000017d57f19a8a1e0ecf2b9629d2cbddee10a72f999b9d15873479dbff1b6f4681e1e3f00000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001b8f204029b558c834435a190314cf6464cab0b0c4a6aab04bb75aca2473c2d19f17b7929727413373eff0bc73a93625af0e38c9d7d0e46e862819ca458435863f71523f015ad1362d9c8ed57a1281747cdaa0d374fc8a967e014fde8ec266d4a000000000000000000000000000000000000000000000000000000000000006431c0b890571188295ff16d0d6d58acd65a5ef5137f56d049c331d872bd3cb40a0000000000000000000000000000000000000000000000000000000000000104a4594c592f39c2f5bd29ecae28e2f719b17bf19a65074407af90537e11f10db569ed8f302389bf869e96ccf539fb3cd44d43b623fe2ee5d9dc5ca3545ab3f5748f954f9e15e465ce5dab36e623b121d4399b6e9b20db44ee8e2d757984f087d92b0cb24c0d21f229b110596903bb3308c644f55b87dade00c0e58e9fa85f349cdc2672262bcd1a6c93ca16a0c3ec6d9e81dc4627a15becf334705d48394e299d690eef9105b8c4e450e9758392fab724048a5cf880cb8a07d70675e4a5f0dfce6fe34821071647f9e08086d7eb5d32f58223c7440dc048722f912d013465ab990295717e228b1e9171c68368d9519c615b2e4c0fede3170f5e94d5f4962f7a2a3a7c79df00000000000000000000000000000000000000000000000000000000";

    uint256 internal hoodiFork;

    address internal hoodiVerifier = vm.envAddress("HOODI_VERIFIER_ADDRESS");
    address internal hoodiFactory = vm.envAddress("HOODI_GAME_FACTORY_ADDRESS");
    address internal proposer = vm.envAddress("HOODI_PROPOSER_ADDRESS");
    address internal deployer = vm.envAddress("HOODI_DEPLOYER_ADDRESS");

    bytes32 internal aggVKey = 0x0059ae2f8c8ad61a6af02594067148b58dbecff2e3352170923efda8ea603f1e;

    ComposeL2OutputOracle internal l2oo;
    ComposeDisputeGame internal gameImpl;

    IComposeL2OutputOracleTypes.InitParams internal initParams = IComposeL2OutputOracleTypes.InitParams(
        proposer,
        proposer,
        aggVKey,
        0,
        hoodiVerifier
    );

    function setUp() public {
        hoodiFork = vm.createFork(vm.envString("HOODI_RPC_URL"));
    }

    function test_ForkOnly_CreateGame() public {
        vm.selectFork(hoodiFork);
        if (hoodiVerifier.code.length == 0 || hoodiFactory.code.length == 0) {
            vm.skip(true);
        }

        l2oo = deployL2OutputOracle(initParams);
        gameImpl = new ComposeDisputeGame(address(l2oo));

        vm.prank(deployer);
        IDisputeGameFactory(hoodiFactory).setImplementation(
            GameType.wrap(gameType), IDisputeGame(gameImpl)
        );

        IDisputeGame createdGame;

        vm.expectRevert(abi.encodeWithSelector(
            IDisputeGameFactory.GameAlreadyExists.selector,
            gameHash
        ));

        vm.prank(proposer, proposer);
        createdGame = IDisputeGameFactory(hoodiFactory).create(
            GameType.wrap(gameType),
            Claim.wrap(rootClaim),
            extraData
        );
    }
}